---
title: VTGate Buffering
weight: 10
aliases: ['/docs/reference/features/vtgate-buffering',
'/docs/reference/programs/vtgate']
---

Here we are going to go through a few senarios involving buffering to see the
various behviors. There are several senarios for buffering tunning, so we will
be using a python utility [gateslap](https://github.com/FancyFane/gateslap)
to generate traffic and simulate an application. You will need three terminal
windows for these exercises:
  * A terminal window for manipulating vtgate
  * A terminal window for sending simulated traffic; gateslap
  * A terminal window to send PlannedReparentShard (PRS) commands

## Setup

These senarios will be will be using a Vitess 12 Cluster, and will be building
off of the 101 application in the example folder. For these senarios we are
assuming a local build of Vitess

#### Terminal 1
1.) Create a vitess cluster using the 101 init script:

```
Terminal 1
    $ cd example/local
    $ source env.sh
    $ ./101_initial_cluster.sh
```

2.) Locate the vtgate process; copy the process information to your notes for
future use; then kill the process

```
Terminal 1
    $ ps aux | head -1; ps aux | grep vtgat[e]
    $ pkill vtgate
```

3.) From your notes, paste in the vtgate command you have previously copied

```
Terminal 1
    $ vtgate -topo_implementation etcd2 -topo_global_server_address localhost:2379 -topo_global_root /vitess/global \
    -log_dir ~/Github/vitess/examples/local/vtdataroot/tmp -log_queries_to_file ~/Github/vitess/examples/local/vtdataroot/tmp/vtgate_querylog.txt \
    -port 15001 -grpc_port 15991 -mysql_server_port 15306 -mysql_server_socket_path /tmp/mysql.sock -cell zone1 \
    -cells_to_watch zone1 -tablet_types_to_wait PRIMARY,REPLICA -service_map grpc-vtgateservice \
    -pid_file ~/Github/vitess/examples/local/vtdataroot/tmp/vtgate.pid -mysql_auth_server_impl none
```

#### Terminal 2:
4.) In a NEW terminal window download and configure gateslap. This utility will
be used to simulate traffic on vitess:

```
Terminal 2
    $ git clone https://github.com/FancyFane/gateslap.git
    $ cd gateslap
    $ virtual venv
    $ source venv/bin/activate
    $ sudo python3 setup.py install
```

5.) You may do a test run of this script which will create a table called "t1"
in customers. You may hit "CTRL + C" at anytime to stop the traffic. By default
this will create 2 persistent, 2 pooled, and 2 oneoff mysql connections.

```
Terminal 2
    (venv) $ gateslap
```

#### Terminal 3:
6.) In a third terminal window we will prepare our statments to do a
PlannedReparentShard (PRS) operation. NOTE: `time` is optional but it is useful
for measuring how long the operation takes.

```
Terminal 3
    $ time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0
```
---
## Senarios

### Senario 1: Default behavior

By default there are no buffering mechanisms in place on vtgate.
In this configuration gateslap is configured to exit immediately when an
error is encountered.

```
Terminal 2:
    (venv) $ gateslap examples/01_light_traffic.ini
```
As soon as traffic is sent issue the PlannedReparentShard command:
```
Terminal 3:
    $ time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0
```

#### Results:
As soon as you issue the PRS operation, you will notice SQL statments begin
to drop and the utility exits. The error code we get from vtgate is `1105` with
the message `target: commerce.0.primary: primary is not serving, there is a
reparent operation in progress`. With no buffering in place it is exclusively
the job of the application to handle this error appropriately, to ensure data
is not lost. Below we can look at buffering metrics.

```sh
$ curl -s localhost:15001/metrics | grep -v '^#' | grep buffer_requests
vtgate_buffer_requests_buffered{keyspace="commerce",shard_name="0"} 0
vtgate_buffer_requests_buffered_dry_run{keyspace="commerce",shard_name="0"} 0
vtgate_buffer_requests_drained{keyspace="commerce",shard_name="0"} 0
vtgate_buffer_requests_evicted{keyspace="commerce",reason="BufferFull",shard_name="0"} 0
vtgate_buffer_requests_evicted{keyspace="commerce",reason="ContextDone",shard_name="0"} 0
vtgate_buffer_requests_evicted{keyspace="commerce",reason="WindowExceeded",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="BufferFull",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="Disabled",shard_name="0"} 64
vtgate_buffer_requests_skipped{keyspace="commerce",reason="LastFailoverTooRecent",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="LastReparentTooRecent",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="Shutdown",shard_name="0"} 0
```



### Senario 2: Solving with error Handling
One approach to preventing these `1105` errors is to handle them in the
application. In the next example we will configure gateslap to retry the mysql
connection 5 times before it quits. Each time it will wait half a second
(500ms) waiting for a `PRIMARY` tablet to return.

```
Terminal 2:
    $ gateslap examples/02_light_traffic_error_handling.ini
```
As soon as traffic is sent issue the PlannedReparentShard command:
```
Terminal 3:
    $ time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0
```
#### Results:
After sleeping for about a second the new primary is elected and the
application can continue sending request to vtgate.
```sh
placeholder
```



### Senario 3: Solving with Buffering
As another approach to this problem, buffering may be employed. While both of
these techniques may be employed we're going to look at the inital (no error
handling) traffic once again. This will allow us to appropriately test buffering.
```
Terminal 1:
    Hit "Ctrl + C" to kill the vtgate process
```
Add the vtgate arguments needed to implment buffering.
{{< warning >}}
The buffering implementation should be set to `keyspace_events` which can
better detect when buffering needs to be enabled. This will become the default
in Vitess 13.
{{< /warning >}}
```
Terminal 1:
    $ vtgate -topo_implementation etcd2 -topo_global_server_address localhost:2379 -topo_global_root /vitess/global \
    -log_dir ~/Github/vitess/examples/local/vtdataroot/tmp -log_queries_to_file ~/Github/vitess/examples/local/vtdataroot/tmp/vtgate_querylog.txt \
    -port 15001 -grpc_port 15991 -mysql_server_port 15306 -mysql_server_socket_path /tmp/mysql.sock -cell zone1 \
    -cells_to_watch zone1 -tablet_types_to_wait PRIMARY,REPLICA -service_map grpc-vtgateservice \
    -pid_file ~/Github/vitess/examples/local/vtdataroot/tmp/vtgate.pid -mysql_auth_server_impl none \
     -enable_buffer=1 -buffer_implementation=keyspace_events
```

```
Terminal 2:
    $ gateslap examples/01_light_traffic.ini
```
As soon as traffic is sent issue the PlannedReparentShard command:
```
Terminal 3:
    $ time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0
```

#### Results:
Shortly after the PRS event is issued, the SQL statments pause momentarily,
also during this time a message is logged to the terminal console window:

```
E1215 15:35:47.712589  251262 healthcheck.go:487] Adding 1 to PrimaryPromoted counter for target: keyspace:"commerce" shard:"0" tablet_type:REPLICA, tablet: zone1-0000000101, tabletType: PRIMARY
```

After this process completes, SQL statments resume processing once again. When
we take a look at stats (shown below) we will see for the first time records of
buffering occuring on the vtgate.
```sh
placeholder
```



### Senario 4: Quickly issued PRS events
In this senario we are going to look at the buffering behavior when quickly
issuing several PlannedReparentShard operations. Restart the VTGate before
proceeding to reset the buffering statistics.

```
Terminal 1:
    Ctrl + C
    vtgate -topo_implementation etcd2 -topo_global_server_address localhost:2379 -topo_global_root /vitess/global \
    -log_dir ~/Github/vitess/examples/local/vtdataroot/tmp -log_queries_to_file ~/Github/vitess/examples/local/vtdataroot/tmp/vtgate_querylog.txt \
    -port 15001 -grpc_port 15991 -mysql_server_port 15306 -mysql_server_socket_path /tmp/mysql.sock -cell zone1 \
    -cells_to_watch zone1 -tablet_types_to_wait PRIMARY,REPLICA -service_map grpc-vtgateservice \
    -pid_file ~/Github/vitess/examples/local/vtdataroot/tmp/vtgate.pid -mysql_auth_server_impl none \
     -enable_buffer=1 -buffer_implementation=keyspace_events
```
```
Terminal 2:
    $ gateslap examples/01_light_traffic.ini
```
As soon as traffic is sent issue the PlannedReparentShard commands. Note there
is a 5 second sleep commands between the PRS statments.
```
Terminal 3:
    $ time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0 && sleep 5 && time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0
```

#### Results:
In this senario, back to back PRS events were issued, only 5 seconds apart.
Due to the close nature of these events, buffering is disabled to protect vitess
against events where PRS may be issued in looping fashion. This behavior is
adjustable with the vtgate flag `-buffer_min_time_between_failovers`.

```sh
placeholder
```

Another way to handle this is to ensure you are waiting for the
`-buffer_min_time_between_failovers` timer to expire before issuing the next
PlannedReparentShard command.



### Senario 5:
Another aspect to be aware of is the `-buffer_size`. For the next seario we will
be setting the buffer size lower than the number of connections from the
application.

{{< warning >}}
The default `buffer_size` is `10` in versions of Vitess prior to 13; in version
13 the default `buffer_size` has moved to `1000`. Caution should be exercised
not to set the `buffer_size` too high as it consumes memory as a resource.
{{< /warning >}}

```
Terminal 1:
    Hit "Ctrl + C" to kill the vtgate process

    $ vtgate -topo_implementation etcd2 -topo_global_server_address localhost:2379 -topo_global_root /vitess/global -log_dir ~/Github/vitess/examples/local/vtdataroot/tmp -log_queries_to_file ~/Github/vitess/examples/local/vtdataroot/tmp/vtgate_querylog.txt -port 15001 -grpc_port 15991 -mysql_server_port 15306 -mysql_server_socket_path /tmp/mysql.sock -cell zone1 -cells_to_watch zone1 -tablet_types_to_wait PRIMARY,REPLICA -service_map grpc-vtgateservice -pid_file ~/Github/vitess/examples/local/vtdataroot/tmp/vtgate.pid -mysql_auth_server_impl none -enable_buffer=1 -buffer_implementation=keyspace_events -buffer_min_time_between_failovers=40s -buffer_size=4
```

```
Terminal 2:
    $ gateslap examples/01_light_traffic.ini
```
```
Terminal 3:
    $ time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0
```

#### Results:
Two of the 6 threads will die, as they were unable to obtain a slot during the
buffering event. The remaining 4 threads will be buffered and will continue to
process threads. The take away here is the `-buffer_size` should be set to the
number of active connections going to vtgate during the PRS event.

```sh
placeholder
```



### Senario 6:
There may be time in which the PRS event takes too long and must be rolled back.
To accomplish this senario we will need to ensure we are using an older version
of MySQL, and we will need to send excessive traffic to vtgate.

{{< warning >}}
This Senario assumes you are running Ubuntu LTS 20.04, you may have to adjust if
your environment is different.
{{< /warning >}}


Here we will tear down the cluster, install an older version of mysql, and rebuild
```
Terminal 1:
    Hit "Ctrl + C" to kill the vtgate process

    $ ./401_teardown.sh

    $ sudo apt-get install mysql-client-core-8.0=8.0.19-0ubuntu5 mysql-server-core-8.0=8.0.19-0ubuntu5

    $ ./101_initial_cluster.sh
    $ ps aux | grep [v]tgate
    $ pkill vtgate
    $ vtgate -topo_implementation etcd2 -topo_global_server_address localhost:2379 -topo_global_root /vitess/global -log_dir ~/Github/vitess/examples/local/vtdataroot/tmp -log_queries_to_file ~/Github/vitess/examples/local/vtdataroot/tmp/vtgate_querylog.txt -port 15001 -grpc_port 15991 -mysql_server_port 15306 -mysql_server_socket_path /tmp/mysql.sock -cell zone1 -cells_to_watch zone1 -tablet_types_to_wait PRIMARY,REPLICA -service_map grpc-vtgateservice -pid_file ~/Github/vitess/examples/local/vtdataroot/tmp/vtgate.pid -mysql_auth_server_impl none -enable_buffer=1 -buffer_implementation=keyspace_events -buffer_min_time_between_failovers=40s
```

```
Terminal 2:
    $ gateslap examples/06_numerous_heavy_traffic.ini
```
As soon as the heavy traffic starts to generate send the PRS command.
```
Terminal 3:
    $ time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0  
```

#### Results:
Here the buffering takes too long to complete, as a result we need to rely on our error handling to recover. When you are programing for error handling in these events, you may want to consider allowing it enough time to recover from an attempted RPC + rollback. In this example I've allocated 50 seconds of retrying the connection.

```sh
placeholder
```

## Revert your configurations

To undo our configuraion we will need to tear the cluster down; upgrade mysql;
then rebuild the vitess cluster:
```
Terminal 1:
    CTRL + C

    Hit "Ctrl + C" to kill the vtgate process

    $ ./401_teardown.sh

    $ sudo apt-get upgrade && sudo apt-get update

```
