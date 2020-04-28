---
author: "Sugu Sougoumarane"
date: 2020-04-27T20:30:00
slug: "2020-04-27-life-of-a-cluster"
tags: ['vitess', 'vitess cluster', 'vitess troubleshooting', 'vitess getting started']
title: "Life of a Vitess Cluster"
---

This post goes into the details of what goes on behind the scenes when a cluster is brought up. This can be used both as a learning tool and troubleshooting guide. We assume that you have downloaded and installed all the necessary binaries before proceeding further.

Vitess is a very flexible system that is capable of running in a variety of environments. The local example does oversimplify things a bit. However, you will need to take more things into consideration when taking Vitess into production.

It will also be important to know how the various components interact with each other. This knowledge will facilitate troubleshooting if a cluster does not come up as intended.

## Choosing a Topology Server

The first component one needs to bring up is actually not a Vitess component. The toposerver can be ZooKeper, etcd, consul, or Kubernetes. Vitess needs a topo server to be up and running. The steps needed to bring up every kind of toposerver are not covered here.

Once you bring up the TopoServer, make sure that you can connect to it using one of their clients.

### Choosing a Topo root

You will probably need to run multiple independent Vitess clusters. For example, you may want to separate out the testing and staging clusters from the production one. However, you may still want to reuse the same TopoServer for all of these.

For this reason, Vitess allows you to choose a root directory in the Topo for each cluster. This directory is known as the `topo_global_root` and will need to be provided for every Vitess binary that is launched.

Caveat: In the case of ZooKeeper, you will actually need to create this directory in the server.

In the local example, we have chosen this to be `/vitess/global`. Here is a sample command to bring up etcd:

```
ETCD_SERVER="localhost:2379" etcd \
  --enable-v2=true \
  --data-dir="${VTDATAROOT}/etcd/" \
  --listen-client-urls="http://${ETCD_SERVER}" \
  --advertise-client-urls="http://${ETCD_SERVER}"
```

## Configuring vtctld

The most important flags for vtctld are the parameters needed to connect to the TopoServer and `-topo_global_root`. Here is a sample vtctld invocation:

```
vtctld \
  -topo_implementation=etcd2 \
  -topo_global_server_address=localhost:2379 \
  -topo_global_root=/vitess/global \
  -port=15000 \
  -grpc_port=15999 \
  -service_map='grpc-vtctl'
```

If the TopoServer is unreachable, or if the `topo_global_root` is not specified, vtctld will fail to start. You should see the following error message in the logs:

```
F0426 11:11:40.363545   14833 server.go:223] Failed to open topo server (etcd2,localhost:2379,/vitess/global): dial tcp 127.0.0.1:2379: connect: connection refused
```

Other required parameters to vtctld are `port`, `grpc_port` and `service_map 'grpc-vtctl'`.

The service_map flag allows you to configure the grpc APIs that a Vitess server exposes as gRPC. If grpc-vtctl is not specified as a service_map for vtctld, you will not be able to access it using vtctlclient.

## Creating a cell

The next step is to create a [cell](https://vitess.io/docs/concepts/cell/). This can be done by issuing the following command:

```
vtctlclient AddCellInfo -root=/vitess/zone1 -server_address=<address> zone1
```

NOTE: vtctlclient does not need a topo global root, because it only talks to vtctld, and vtctld already has that value.

The ‘-root’ flag is different from topo_global_root. All information specific to the cell will be stored under `/vitess/zone1`.

For higher fault tolerance, you can set up and specify a different TopoServer to serve the local cell. If isolation of failure zones is not important, you could just reuse the main TopoServer as long as you ensure that the root paths don’t conflict.

The last parameter “zone1” is the name of the cell, which is required by the subsequent tools.

You can verify this information by browsing the Topology in vtctld:

<figure>
  <img src="/files/2020-life-cluster/cell-in-topo.png"/>
</figure>

Note: In the local example, we’re using the `vtctl` tool to create the local cell. This is because we are creating the local cell before bringing up vtctld. However, this is not necessary. You can create the local cell after bringing up vtctld.

At this point, we have officially created an empty Vitess cluster.

## Configuring VTGate

Although the local example brings up vtgate last, this is not necessary. You can bring up vtgate before creating any keyspaces or bringing up vttablets. VTGate will discover them as they are brought up.

In addition to the topo parameters, vtgate requires a `cell` to operate in. A vtgate’s main job is to forward requests to the vttablets in the local cell. However, vtgates can go cross-cell in two situations:

1. vtgate receives queries to the master, and the master is not in the current cell.
1. vtgate was configured to go to other cells in case no local vttablets were available.

For sending master queries across cells, you must specify an additional `cells_to_watch` flag. This will make the vtgates watch those additional cells, and will help them keep track of the masters in those cells.

The `cells_to_watch` flag is a required parameter and must at least include the current cell. This is an issue we’ll fix soon: https://github.com/vitessio/vitess/issues/6126.

Going cross-cell for non-master requests is an advanced use case that requires setting up cell aliases, which will not be covered here.

The `port` flag is mandatory for vtgate.

For those who wish to use the Java or Go grpc clients to vtgate, you must also configure `grpc_port` and specify the service map as `service_map='grpc-vtgateservice'`.

For those who wish to use the mysql protocol, you must specify a `mysql_server_port` and a `mysql_auth_server_impl` for configuring authentication.

Here is a sample vtgate invocation:

```
vtgate \
  -topo_implementation=etcd2 \
  -topo_global_server_address=localhost:2379 \
  -topo_global_root=/vitess/global \
  -cell=zone1 \
  -cells_to_watch=zone1 \
  -port=15001 \
  -grpc_port=15991 \
  -service_map='grpc-vtgateservice' \
  -mysql_server_port=$mysql_server_port \
  -mysql_auth_server_impl=none
```

The reason why the local example brings up vtgate last is because vtgate polls the TopoServer for changes. Bringing it up last allows vtgate to find all the vttablets that were brought up, and immediately ready itself to send requests to them. This polling frequency is controlled by the `tablet_refresh_interval` whose default value is one minute. This means that it may take up to one minute for vtgate to discover a new vttablet that has come up. This interval can be lowered. However, one must be careful to ensure that too many vtgates don’t overwhelm the TopoServer.

VTGate uses the global topo to get the topo addresses of the cells it has to watch. For this reason, you do not need to specify the topo addresses for the individual cells.

VTGate does not communicate with vtctld.

A vtgate that comes up successfully will show all the vttablets it has discovered in its `/debug/status` page under the `Health Check Cache` section.

<figure>
  <img src="/files/2020-life-cluster/healthy-tablets.png"/>
</figure>
