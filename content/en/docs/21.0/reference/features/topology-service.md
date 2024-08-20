---
title: Topology Service
weight: 20
aliases: ['/docs/user-guides/topology-service/','/docs/reference/topology-service/']
---

This document describes the Topology Service, a key part of the Vitess architecture. This service is exposed to all Vitess processes, and is used to store small pieces of configuration data about the Vitess cluster, and provide cluster-wide locks. It also supports watches, and primary election.

Vitess uses a plugin implementation to support multiple backend technologies for the Topology Service (etcd, ZooKeeper, Consul). Concretely, the Topology Service handles two functions: it is both a [distributed lock manager](http://en.wikipedia.org/wiki/Distributed_lock_manager) and a repository for topology metadata. In earlier versions of Vitess, the Topology Serice was also referred to as the Lock Service.

## Requirements and Usage

The Topology Service is used to store information about the Keyspaces, the
Shards, the Tablets, the Replication Graph, and the Serving Graph. We store
small data structures (a few hundred bytes) per object.

The main contract for the Topology Service is to be very highly available and
consistent. It is understood it will come at a higher latency cost and very low
throughput.

We never use the Topology Service as an RPC or queuing mechanism or as a storage
system for logs. We never depend on the Topology Service being responsive and
fast to serve every query.

The Topology Service must also support a Watch interface, to signal when certain
conditions occur on a node. This is used, for instance, to know when the Keyspace
topology changes (e.g. for resharding).

### Global vs Local

We differentiate two instances of the Topology Service: the Global instance, and
the per-cell Local instance:

* The Global instance is used to store global data about the topology that
  doesn’t change very often, e.g. information about Keyspaces and Shards.
  The data is independent of individual instances and cells, and needs
  to survive a cell going down entirely.
* There is one Local instance per cell, that contains cell-specific information,
  and also rolled-up data from the Global + Local cell to make it easier for
  clients to find the data. The Vitess local processes should not use the Global
  topology instance, but instead the rolled-up data in the Local topology
  server as much as possible.

The Global instance can go down for a while and not impact the local cells (an
exception to that is if a reparent needs to be processed, it might not work). If
a Local instance goes down, it only affects the local tablets in that instance
(and then the cell is usually in bad shape, and should not be used).

Vitess will not use the global or local topology service as part of serving individual queries. The Topology Service is only used to get the topology information at startup and in the background.

### Recovery

If a Local Topology Service dies and is not recoverable, it can be wiped out. All
the tablets in that cell then need to be restarted so they re-initialize their
topology records (but they won’t lose any MySQL data).

If the Global Topology Service dies and is not recoverable, this is more of a
problem. All the Keyspace / Shard objects have to be recreated or be restored.
Then the cells should recover.

## Global Data

This section describes the data structures stored in the Global instance of the
topology service.

### Keyspace

The Keyspace object contains various information, mostly about sharding: how is
this Keyspace sharded, what is the name of the sharding key column, is this
Keyspace serving data yet, how to split incoming queries, …

An entire Keyspace can be locked. We use this during resharding for instance,
when we change which Shard is serving what inside a Keyspace. That way we
guarantee only one operation changes the Keyspace data concurrently.

### Shard

A Shard contains a subset of the data for a Keyspace. The Shard record in the
Global topology service contains:

* the primary tablet alias for this shard (that has the MySQL primary).
* the sharding key range covered by this Shard inside the Keyspace.
* the tablet types this Shard is serving (primary, replica, batch, …), per cell
  if necessary.
* if using filtered replication, the source shards this shard is replicating
  from.
* the list of cells that have tablets in this shard.
* shard-global tablet controls, like denied tables no tablet should serve
  in this shard.

A Shard can be locked. We use this during operations that affect either the
Shard record, or multiple tablets within a Shard (like reparenting), so multiple
tasks cannot concurrently alter the data.

### VSchema Data

The VSchema data contains sharding and routing information for
the [VTGate API](https://github.com/vitessio/vitess/blob/main/doc/design-docs/VTGateV3Features.md).

## Local Data

This section describes the data structures stored in the Local instance (per
cell) of the topology service.

### Tablets

The Tablet record has a lot of information about each vttablet process
making up each tablet (along with the MySQL process):

* the Tablet Alias (cell+unique id) that uniquely identifies the Tablet.
* the Hostname, IP address and port map of the Tablet.
* the current Tablet type (primary, replica, batch, spare, …).
* which Keyspace / Shard the tablet is part of.
* the sharding Key Range served by this Tablet.
* user-specified tag map (e.g. to store per-installation data).

A Tablet record is created before a tablet can be running (by passing the `init_*` parameters to the vttablet process).
The only way a Tablet record will be updated is one of:

* The vttablet process itself owns the record while it is running, and can
  change it.
* At init time, before the tablet starts.
* After shutdown, when the tablet gets deleted.
* If a tablet becomes unresponsive, it may be forced to spare to make it
  unhealthy when it restarts.

### Replication Graph

The Replication Graph allows us to find Tablets in a given Cell / Keyspace /
Shard. It used to contain information about which Tablet is replicating from
which other Tablet, but that was too complicated to maintain. Now it is just a
list of Tablets.

### Serving Graph

The Serving Graph is what the clients use to find the per-cell topology of a
Keyspace. It is a roll-up of global data (Keyspace + Shard). vtgates only open a
small number of these objects and get all the information they need quickly.

#### SrvKeyspace

It is the local representation of a Keyspace. It contains information on what
shard to use for getting to the data (but not information about each individual
shard):

* the partitions map is keyed by the tablet type (primary, replica, batch, …) and
  the value is a list of shards to use for serving.
* it also contains the global Keyspace fields, copied for fast access.

It can be rebuilt by running `vtctl RebuildKeyspaceGraph <keyspace>`. It is
automatically rebuilt when a tablet starts up in a cell and the SrvKeyspace
for that cell / keyspace does not exist yet. It will also be changed
during horizontal and vertical splits.

#### SrvVSchema

It is the local roll-up for the VSchema. It contains the VSchema for all
keyspaces in a single object.

It can be rebuilt by running `vtctl RebuildVSchemaGraph`. It is automatically
rebuilt when using `vtctl ApplyVSchema` (unless prevented by flags).

## Workflows Involving the Topology Service

The Topology Service is involved in many Vitess workflows.

When a Tablet is initialized, we create the Tablet record, and add the Tablet to
the Replication Graph. If it is the primary for a Shard, we update the global
Shard record as well.

Administration tools need to find the tablets for a given Keyspace / Shard. To retrieve this:

* first we get the list of Cells that have Tablets for the Shard (global topology
Shard record has these)
* then we use the Replication Graph for that Cell /
Keyspace / Shard to find all the tablets then we can read each tablet record.

When a Shard is reparented, we need to update the global Shard record with the
new primary alias.

Finding a tablet to serve the data is done in two stages:

* vtgate maintains a health check connection to all possible tablets, and they
report which Keyspace / Shard / Tablet type they serve.
* vtgate also reads the SrvKeyspace object, to find out the shard map.

With these two pieces of information, vtgate can route the query to the right vttablet.

During resharding events, we also change the topology significantly. A horizontal split
will change the global Shard records, and the local SrvKeyspace records. A
vertical split will change the global Keyspace records, and the local
SrvKeyspace records.

## Exploring the Data in a Topology Service

We store the proto3 serialized binary data for each object.

We use the following paths for the data, in all implementations:

*Global Cell*:

* CellInfo path: `cells/<cell name>/CellInfo`
* Keyspace: `keyspaces/<keyspace>/Keyspace`
* Shard: `keyspaces/<keyspace>/shards/<shard>/Shard`
* VSchema: `keyspaces/<keyspace>/VSchema`

*Local Cell*:

* Tablet: `tablets/<cell>-<uid>/Tablet`
* Replication Graph: `keyspaces/<keyspace>/shards/<shard>/ShardReplication`
* SrvKeyspace: `keyspaces/<keyspace>/SrvKeyspace`
* SrvVSchema: `SvrVSchema`

The `vtctl TopoCat` utility can decode these files when using the
`--decode_proto` option:

``` sh
GLOBAL_TOPOLOGY="--topo_implementation zk2 --topo_global_server_address global_server1,global_server2 --topo_global_root /vitess/global"

$ vtctl ${GLOBAL_TOPOLOGY} TopoCat -- --decode_proto --long /keyspaces/*/Keyspace
path=/keyspaces/ks1/Keyspace version=53
sharding_column_name: "col1"
path=/keyspaces/ks2/Keyspace version=55
sharding_column_name: "col2"
```

The VTAdmin web tool also contains a topology browser (use the `Topology`
tab on the left side). It will display the various proto files, decoded.

## Implementations

The Topology Service interfaces are defined in our code in `go/vt/topo/`,
specific implementations are in `go/vt/topo/<name>`, and we also have
a set of unit tests for it in `go/vt/topo/test`.

This part describes the implementations we have, and their specific
behavior.

If starting from scratch, please use the `zk2`, `etcd2` or `consul`
implementations. We deprecated the old `zookeeper` and `etcd`
implementations. See the migration section below if you want to migrate.

### Zookeeper `zk2` implementation

This is the current implementation when using Zookeeper. (The old `zookeeper`
implementation is deprecated).

The global cell typically has around 5 servers, distributed one in each
cell. The local cells typically have 3 or 5 servers, in different server racks /
sub-networks for higher resilience. For our integration tests, we use a single
ZK server that serves both global and local cells.

We provide the `zk` utility for easy access to the topology data in
Zookeeper. It can list, read and write files inside any Zoopeeker server. Just
specify the `-server` parameter to point to the Zookeeper servers. Note the
VTAdmin UI can also be used to see the contents of the topology data.

To configure a Zookeeper installation, let's start with the global cell
service. It is described by the addresses of the servers (comma separated list),
and by the root directory to put the Vitess data in. For instance, assuming we
want to use servers `global_server1,global_server2` in path `/vitess/global`:

``` sh
# The root directory in the global server will be created
# automatically, same as when running this command:
# zk -server global_server1,global_server2 touch -p /vitess/global

# Set the following flags to let Vitess use this global server:
# --topo_implementation zk2
# --topo_global_server_address global_server1,global_server2
# --topo_global_root /vitess/global
```

Then to add a cell whose local topology service `cell1_server1,cell1_server2`
will store their data under the directory `/vitess/cell1`:

``` sh
GLOBAL_TOPOLOGY="--topo_implementation zk2 --topo_global_server_address global_server1,global_server2 --topo_global_root /vitess/global"

# Reference cell1 in the global topology service:
vtctl ${GLOBAL_TOPOLOGY} AddCellInfo -- \
  --server_address cell1_server1,cell1_server2 \
  --root /vitess/cell1 \
  cell1
```

If only one cell is used, the same Zookeeper instance can be used for both
global and local data. A local cell record still needs to be created, just use
the same server address, and very importantly a *different* root directory.

[Zookeeper Observers](https://zookeeper.apache.org/doc/current/zookeeperObservers.html) can
also be used to limit the load on the global Zookeeper. They are configured by
specifying the addresses of the observers in the server address, after a `|`,
for instance:
`global_server1:p1,global_server2:p2|observer1:po1,observer2:po2`.

#### Implementation Details

We use the following paths for Zookeeper specific data, in addition to the
regular files:

* Locks sub-directory: `locks/` (for instance:
  `keyspaces/<keyspace>/Keyspace/locks/` for a keyspace)
* Leader election path: `elections/<name>`

Both locks and primary election are implemented using ephemeral, sequential files
which are stored in their respective directory.

### etcd `etcd2` implementation (new version of `etcd`)

This topology service plugin is meant to use etcd clusters as storage backend
for the topology data. This topology service supports version 3 and up of the
etcd server.

This implementation is named `etcd2` because it supersedes our previous
implementation `etcd`. Note that the storage format has been changed with the
`etcd2` implementation, i.e. existing data created by the previous `etcd`
implementation must be migrated manually (See migration section below).

To configure an `etcd2` installation, let's start with the global cell
service. It is described by the addresses of the servers (comma separated list),
and by the root directory to put the Vitess data in. For instance, assuming we
want to use servers `http://global_server1,http://global_server2` in path
`/vitess/global`:

``` sh
# Set the following flags to let Vitess use this global server,
# and simplify the example below:
# --topo_implementation etcd2
# --topo_global_server_address http://global_server1,http://global_server2
# --topo_global_root /vitess/global
GLOBAL_TOPOLOGY="--topo_implementation etcd2 --topo_global_server_address http://global_server1,http://global_server2 --topo_global_root /vitess/global"
```

Then to add a cell whose local topology service
`http://cell1_server1,http://cell1_server2` will store their data under the
directory `/vitess/cell1`:

``` sh
# Reference cell1 in the global topology service:
# (the TOPOLOGY variable is defined in the previous section)
vtctl ${GLOBAL_TOPOLOGY} AddCellInfo -- \
  --server_address http://cell1_server1,http://cell1_server2 \
  --root /vitess/cell1 \
  cell1
```

If only one cell is used, the same etcd instances can be used for both
global and local data. A local cell record still needs to be created, just use
the same server address and, very importantly, a *different* root directory.

#### Implementation Details

For locks, we use a subdirectory named `locks` in the directory to lock, and an
ephemeral file in that subdirectory (it is associated with a lease, whose TTL
can be set with the `--topo_etcd_lease_duration` flag, defaults to 30
seconds). The ephemeral file with the lowest ModRevision has the lock, the
others wait for files with older ModRevisions to disappear.

Leader elections also use a subdirectory, named after the election Name, and use
a similar method as the locks, with ephemeral files.

We store the proto3 binary data for each object (as the API allows us to store
binary data).  Note that this means that if you want to interact with etcd using
the `etcdctl` tool, you will have to tell it to use the v3 API, e.g.:

```
ETCDCTL_API=3 etcdctl get / --prefix --keys-only
```

### Consul `consul` Implementation

This topology service plugin is meant to use Consul clusters as storage backend
for the topology data.

To configure a `consul` installation, let's start with the global cell
service. It is described by the address of a server,
and by the root node path to put the Vitess data in (it cannot start with `/`). For instance, assuming we
want to use servers `global_server:global_port` with node path
`vitess/global`:

``` sh
# Set the following flags to let Vitess use this global server,
# and simplify the example below:
# --topo_implementation consul
# --topo_global_server_address global_server:global_port
# --topo_global_root vitess/global
GLOBAL_TOPOLOGY="--topo_implementation consul --topo_global_server_address global_server:global_port --topo_global_root vitess/global"
```

Then to add a cell whose local topology service
`cell1_server1:cell1_port` will store their data under the
directory `vitess/cell1`:

``` sh
# Reference cell1 in the global topology service:
# (the TOPOLOGY variable is defined in the previous section)
vtctl ${GLOBAL_TOPOLOGY} AddCellInfo -- \
  --server_address cell1_server1:cell1_port \
  --root vitess/cell1 \
  cell1
```

If only one cell is used, the same consul instances can be used for both
global and local data. A local cell record still needs to be created, just use
the same server address and, very importantly, a *different* root node path.

#### Implementation Details

For locks, we use a file named `Lock` in the directory to lock, and the regular
Consul Lock API.

Leader elections use a single lock file (the Election path) and the regular
Consul Lock API. The contents of the lock file is the ID of the current primary.

Watches use the Consul long polling Get call. They cannot be interrupted, so we
use a long poll whose duration is set by the
`-topo_consul_watch_poll_duration` flag. Canceling a watch may have to
wait until the end of a polling cycle with that duration before returning.

## Running Multi Cell Environments

When running an environment with multiple cells, it is essential to first create
and configure your global topology service. Then define each local topology
service to the global topology. As mentioned previously, the global
and local topology service can reside on the same or separate implementation of
etcd, zookeeper, or consul. At a higher level overview:

* Create or locate an existing instance of etcd, zookeeper, or consul for the
  global topology service.
* Use vtctl client commands to initialize the global topology service,
  providing the global topology implementation, and root directory.
  NOTE: for best practices the root dir should be set to `/vitess/global` (on
  consul this should be `vitess/global`).
* (Optional) For each cell create an instance of etcd, zookeeper, or consul for
  the local topology service. This step is optional as you may use the existing
  implementation used by the global topology service. If you create a new local
  instances, the technologies must match. For example, if you are using etcd for
  your global topology service then you must use etcd for your local topology
  service.
* For each cell, using the vtctl client commands, define the local topology
  service with the global topology service. This is done by providing the global
  topology service with the cell name, the local topology service, and the root
  directory. NOTE: for best practices the local root dir should be set to
  `/vitess/${CELL_NAME}` (on consul this should be `vitess/${CELL_NAME}`) where `${CELL_NAME}` is the location of the cell
  `us-east-1, eu-west-2, etc`.
* When starting a vttablet instance you must provide the global topology service
  as well as the `-tablet-path`, which implicitly includes the cell details.
  With this information the vttablet process will read the local topology
  details from the global topology server.
* When starting a vtgate instance, you will provide the global topology
  service, as well as the `-cell` flag to explicitly provide the cell details.
  With this information the vtgate process will retrieve the connection details
  it needs to connect to the applicable local topology server(s). Unlike the
  vttablet process, if you are watching more than one cell, in `--cells_to_watch`
  you may connect to multiple local topology services.


### Simple Local Configuration

For this example run through, we will be using two etcd services one for
the global and one for local topology service.

{{< warning >}}
Production environments can and should be configured with multiple
topology instances at the global and local levels.
{{< /warning >}}


1. Create the global etcd service

``` sh
export VTDATAROOT="/vt"
TOKEN="SOMETHING_UNIQ_HERE"
GLOBAL_ETCD_IP="192.168.0.2"
GLOBAL_ETCD_SERVER="http://${GLOBAL_ETCD_IP}:2379"
GLOBAL_ETCD_PEER_SERVER="http://${GLOBAL_ETCD_IP}:2380"

etcd --enable-v2=true --data-dir ${VTDATAROOT}/etcd/global --listen-client-urls ${GLOBAL_ETCD_SERVER} \
  --name=global --advertise-client-urls ${GLOBAL_ETCD_SERVER} --listen-peer-urls ${GLOBAL_ETCD_PEER_SERVER} \
  --initial-advertise-peer-urls ${GLOBAL_ETCD_PEER_SERVER} --initial-cluster global=${GLOBAL_ETCD_PEER_SERVER} \
  --initial-cluster-token=${TOKEN} --initial-cluster-state=new \
  ${OTHER_ETCD_FLAGS}
```

2. Configure vtctld to use the global topology service

``` sh
vtctld --topo_implementation=etcd2 --topo_global_server_address=${GLOBAL_ETCD_SERVER} \
  --topo_global_root=/vitess/global --port=15000 --grpc_port=15999 --service_map='grpc-vtctl,grpc-vtctld' \
  ${OTHER_VTCTLD_FLAGS}
```

3. Create a local etcd instance to store our cell information

``` sh
CELL_NAME="US_EAST"
CELL_TOKEN="${CELL_NAME}"
CELL_ETCD_IP="192.168.0.3"
CELL_ETCD_SERVER="http://${CELL_ETCD_IP}:2379"
CELL_ETCD_PEER_SERVER="http://${CELL_ETCD_IP}:2380"

etcd --enable-v2=true --data-dir ${VTDATAROOT}/etcd/${CELL_NAME} --listen-client-urls ${CELL_ETCD_SERVER} \
  --name=${CELL_NAME} --advertise-client-urls ${CELL_ETCD_SERVER} --listen-peer-urls ${CELL_ETCD_PEER_SERVER} \
  --initial-advertise-peer-urls ${CELL_ETCD_PEER_SERVER} --initial-cluster ${CELL_NAME}=${CELL_ETCD_PEER_SERVER} \
  --initial-cluster-token=${CELL_TOKEN} --initial-cluster-state=new \
  ${OTHER_ETCD_FLAGS}
```

4. Define the local topology service in the global topology service using vtctl
client commands. We are providing the global topolgy server three pieces of
information about the local topology service:
    * `--root=` the root of our local topology server
    * `--server_address` comma separated connection details to our local etcd
  instance(s). In this example, it is only a single instance
    * `${CELL_NAME}` the name of our local cell in this case `US_EAST`

``` sh
# vtctldclient uses the IP address of the vtctld daemon with the `--server` flag
# The daemon already has the global topology information, therefore, we do not
# need to explicitly provide these details.

vtctldclient --server ${VTCTLD_IP}:15999 AddCellInfo -- \
  --root=/vitess/${CELL_NAME} \
  --server-address=${CELL_ETCD_SERVER} \
  ${CELL_NAME}
```

5. When starting up a new vttablet instances, you will need to provide
the global topology details, as well as the alias of the tablet, provided through
`--tablet-path=${TABLET_ALIAS}`. With the alias vttablet will acquire the cell
name and retrieve the local topology information from the global topology server.
NOTE: the `${TABLET_ALIAS}` variable is composed of two parts, the `${CELL_NAME}`
and the `${TABLET_UID}`. The `${TABLET_ALIAS}` must be unique within the cluster
and the `${TABLET_UID}` must be unique numerical value within the cell.

```sh
# vttablet implementation
GLOBAL_TOPOLOGY="--topo_implementation etcd2 --topo_global_server_address ${GLOBAL_ETCD_SERVER} --topo_global_root /vitess/global"
TABLET_UID="100"
CELL_NAME="US_EAST"
TABLET_ALIAS="${CELL_NAME}-${TABLET_UID}"
KEYSPACE="CustomerInfo"

vttablet ${GLBOAL_TOPOLOGY} --tablet-path=${TABLET_ALIAS} --tablet_dir=${VTDATAROOT}/${TABLET_ALIAS} \
  --mycnf-file=${VTDATAROOT}/${TABLET_ALIAS}/my.cnf --init_keyspace=${KEYSPACE} \
  --init_shard=0 --init_tablet_type=replica --port=15100 --grpc_port=16100 \
  --service_map='grpc-queryservice,grpc-tabletmanager,grpc-updatestream' \
  ${OTHER_VTTABLET_FLAGS}
```

5. When starting up a new vtgate instances, you will explicitly provide cell
details with `--cell` flag, and the global topology details. vtgate may be aware
of additional local topology services if `--cells_to_watch` contains more than
one cell. Local Topology information will be retrieved from the global toplogy
server for each cell vtgate is aware of.

```sh
# vtgate implementation
GLOBAL_TOPOLOGY="--topo_implementation etcd2 --topo_global_server_address ${GLOBAL_ETCD_SERVER} --topo_global_root /vitess/global"
CELL_NAME="US_EAST"

vtgate ${GLOBAL_TOPOLOGY} --cell=${CELL_NAME} --cells_to_watch=${CELL_NAME} --port=15001 --grpc_port=15991 \
--mysql_server_port=25306 --mysql_auth_server_impl=none --service_map='grpc-vtgateservice' \
--tablet_types_to_wait PRIMARY,REPLICA \
${OTHER_VTGATE_FLAGS}
```

6. You can repeat steps 3 through 5 above to create each cell as needed. If you
have a vtgate instance that is watching a new and old cell with `-cells_to_watch`,
you may have to rebuild the topology for the Keyspace and VSchema. This will
propagate information from the global topology service back to the local topology
services

```sh
vtctldclient --server ${VTCTLD_IP}:15999 RebuildKeyspaceGraph ${KEYSPACE_NAME}
vtctldclient --server ${VTCTLD_IP}:15999 RebuildVSchemaGraph
```


## Running Single Cell Environments

The topology service is meant to be distributed across multiple cells, and
survive single cell outages. However, one common usage is to run a Vitess
cluster in only one cell / region. This part explains how to do this, and later
on upgrade to multiple cells / regions.

If running in a single cell, the same topology service can be used for both
global and local data. A local cell record still needs to be created, just use
the same server address and, very importantly, a *different* root node path.

In that case, just running 3 servers for topology service quorum is probably
sufficient. For instance, 3 etcd servers. And use their address for the local
cell as well. Let's use a short cell name, like `local`, as the local data in
that topology service will later on be moved to a different topology service,
which will have the real cell name.

### Extending to More Cells

To then run in multiple cells, the current topology service needs to be split
into a global instance and one local instance per cell. Whereas, the initial
setup had 3 topology servers (used for global and local data), we recommend to
run 5 global servers across all cells (for global topology data) and 3 local
servers per cell (for per-cell topology data).

To migrate to such a setup, start by adding the 3 local servers in the second
cell and run `vtctldclient AddCellInfo` as was done for the first cell. Tablets and
vtgates can now be started in the second cell, and used normally.

vtgate can then be configured with a list of cells to watch for tablets using
the `--cells_to_watch` command line parameter. It can then use all tablets in
all cells to route traffic. Note this is necessary to access the primary in
another cell.

After the extension to two cells, the original topo service contains both the
global topology data, and the first cell topology data. The more symmetrical
configuration we are after would be to split that original service into two: a
global one that only contains the global data (spread across both cells), and a
local one to the original cells. To achieve that split:

* Start up a new local topology service in that original cell (3 more local
  servers in that cell).
* Pick a name for that cell, different from `local`.
* Use `vtctl AddCellInfo` to configure it.
* Make sure all vtgates can see that new local cell (again, using
  `--cells_to_watch`).
* Restart all vttablets to be in that new cell, instead of the `local` cell name
  used before.
* Use `vtctl RemoveKeyspaceCell` to remove all mentions of the `local` cell in
  all keyspaces.
* Use `vtctl RemoveCellInfo` to remove the global configurations for that
  `local` cell.
* Remove all remaining data in the global topology service that are in the old
  local server root.

After this split, the configuration is completely symmetrical:

* a global topology service, with servers in all cells. Only contains global
  topology data about Keyspaces, Shards and VSchema. Typically it has 5 servers
  across all cells.
* a local topology service to each cell, with servers only in that cell. Only
  contains local topology data about Tablets, and roll-ups of global data for
  efficient access. Typically, it has 3 servers in each cell.

## Migration Between Implementations

We provide the `topo2topo` utility to migrate between one implementation
and another of the topology service.

The process to follow in that case is:

* Start from a stable topology, where no resharding or reparenting is ongoing.
* Configure the new topology service so it has at least all the cells of the
  source topology service. Make sure it is running.
* Run the `topo2topo` program with the right flags. `--from_implementation`,
  `--from_root`, `--from_server` describe the source (old) topology
  service. `--to_implementation`, `--to_root`, `--to_server` describe the
  destination (new) topology service.
* Run `vtctl RebuildKeyspaceGraph` for each keyspace using the new topology
  service flags.
* Run `vtctl RebuildVSchemaGraph` using the new topology service flags.
* Restart all `vtgate` processes using the new topology service flags. They
  will see the same Keyspaces / Shards / Tablets / VSchema as before, as the
  topology was copied over.
* Restart all `vttablet` processes using the new topology service flags.
  They may use the same ports or not, but they will update the new topology
  when they start up, and be visible from `vtgate`.
* Restart all `vtctld` processes using the new topology service flags. So that
  the UI also shows the new data.

Sample commands to migrate from deprecated `zookeeper` to `zk2`
topology would be:

``` sh
# Let's assume the zookeeper client config file is already
# exported in $ZK_CLIENT_CONFIG, and it contains a global record
# pointing to: global_server1,global_server2
# an a local cell cell1 pointing to cell1_server1,cell1_server2
#
# The existing directories created by Vitess are:
# /zk/global/vt/...
# /zk/cell1/vt/...
#
# The new zk2 implementation can use any root, so we will use:
# /vitess/global in the global topology service, and:
# /vitess/cell1 in the local topology service.

# Create the new topology service roots in global and local cell.
zk -server global_server1,global_server2 touch -p /vitess/global
zk -server cell1_server1,cell1_server2 touch -p /vitess/cell1

# Store the flags in a shell variable to simplify the example below.
GLOBAL_TOPOLOGY="--topo_implementation zk2 --topo_global_server_address global_server1,global_server2 --topo_global_root /vitess/global"

# Reference cell1 in the global topology service:
vtctl ${GLOBAL_TOPOLOGY} AddCellInfo -- \
  --server_address cell1_server1,cell1_server2 \
  --root /vitess/cell1 \
  cell1

# Now copy the topology. Note the old zookeeper implementation does not need
# any server or root parameter, as it reads ZK_CLIENT_CONFIG.
topo2topo \
  --from_implementation zookeeper \
  --to_implementation zk2 \
  --to_server global_server1,global_server2 \
  --to_root /vitess/global \

# Rebuild SvrKeyspace objects in new service, for each keyspace.
vtctl ${GLOBAL_TOPOLOGY} RebuildKeyspaceGraph keyspace1
vtctl ${GLOBAL_TOPOLOGY} RebuildKeyspaceGraph keyspace2

# Rebuild SrvVSchema objects in new service.
vtctl ${GLOBAL_TOPOLOGY} RebuildVSchemaGraph

# Now restart all vtgate, vttablet, vtctld processes replacing:
# --topo_implementation zookeeper
# With:
# --topo_implementation zk2
# --topo_global_server_address global_server1,global_server2
# --topo_global_root /vitess/global
#
# After this, the ZK_CLIENT_CONF file and environment variables are not needed
# any more.
```

### Migration Using the `Tee` Implementation

If your migration is more complex, or has special requirements, we also support
a 'tee' implementation of the topo service interface. It is defined in
`go/vt/topo/helpers/tee.go`. It allows communicating to two topo services,
and the migration uses multiple phases:

* Start with the old topo service implementation we want to replace.
* Bring up the new topo service, with the same cells.
* Use `topo2topo` to copy the current data from the old to the new topo.
* Configure a `Tee` topo implementation to maintain both services.
  * Note we do not expose a plugin for this, so a small code change is necessary.
  * all updates will go to both services.
  * the `primary` topo service is the one we will get errors from, if any.
  * the `secondary` topo service is just kept in sync.
  * at first, use the old topo service as `primary`, and the new one as
    `secondary`.
  * then, change the configuration to use the new one as `primary`, and the
    old one as `secondary`. Reverse the lock order here.
  * then rollout a configuration to just use the new service.
