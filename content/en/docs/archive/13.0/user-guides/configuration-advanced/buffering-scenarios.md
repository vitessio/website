---
title: VTGate Buffering Scenarios
weight: 1
aliases: ['/docs/user-guides/buffering-scenarios/']
---

For documentation on buffering behaviors please see
[VTGate Buffering](../../../reference/features/vtgate-buffering/).
In this guide we are going to go through a few scenarios involving buffering to
see the practical behaviors. There are several parameters to tune for buffering
so, we will be using a python utility [gateslap](https://github.com/planetscale/gateslap)
to generate traffic and simulate an application. You will need three terminal
windows for these exercises:

  * terminal 1 - for manipulating the vtgate process
  * terminal 2 - for sending simulated traffic to vtgate; gateslap
  * terminal 3 - to send PlannedReparentShard (PRS) commands and retrieve metrics

## Setup

These scenarios will be building off of the
[local getting started guide](../../../get-started/local/).

#### Terminal 1

1.) Locate the vtgate process, copy the process information to your notes for
future use; then kill the process:

```
Terminal 1
    $ ps aux | head -1; ps aux | grep vtgat[e]
    $ pkill vtgate
```

2.) From your notes, paste in the vtgate command you have previously copied into
the terminal window and hit enter:


```
Terminal 1
    $ vtgate -topo_implementation etcd2 -topo_global_server_address localhost:2379 \
    -topo_global_root /vitess/global -log_dir ~/github/vitess/examples/local/vtdataroot/tmp \
    -log_queries_to_file ~/github/vitess/examples/local/vtdataroot/tmp/vtgate_querylog.txt \
    -port 15001 -grpc_port 15991 -mysql_server_port 15306 -mysql_server_socket_path /tmp/mysql.sock \
    -cell zone1 -cells_to_watch zone1 -tablet_types_to_wait PRIMARY,REPLICA \
    -service_map grpc-vtgateservice -pid_file ~/github/vitess/examples/local/vtdataroot/tmp/vtgate.pid \
    -mysql_auth_server_impl none
```

#### Terminal 2:

3.) In a NEW terminal window download and configure gateslap. This utility will
be used to simulate traffic on Vitess. The virtualenv and source commands are
optional:

```
Terminal 2
    $ git clone https://github.com/planetscale/gateslap.git
    $ cd gateslap
    $ virtualenv venv
    $ source venv/bin/activate
    $ sudo python3 setup.py install
```

4.) You may do a test run of this script which will create a table called `t1`
in the commerce schema. You may hit "CTRL + C" at anytime to stop the traffic.
By default this will create 2 persistent, 2 pooled, and 2 oneoff MySQL
connections and it will drop the `t1` table when it is complete, or when the
SIGINT signal is given. You can change the behavior by modifying the
`slapper.ini` file.

```
Terminal 2
    (venv) $ gateslap
    (venv) CTRL + C
```

#### Terminal 3:

5.) In a third terminal window we will prepare the vtctlclient to do a
PlannedReparentShard (PRS). Note, `time` is optional but it is useful
for measuring how long the operation takes.

```
Terminal 3
    $ time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0
```
---

## Scenarios

### Scenario 1: Default behavior

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

As soon as you issue the PRS operation, you will notice SQL statements begin
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
vtgate_buffer_requests_skipped{keyspace="commerce",reason="Disabled",shard_name="0"} 33
vtgate_buffer_requests_skipped{keyspace="commerce",reason="LastFailoverTooRecent",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="LastReparentTooRecent",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="Shutdown",shard_name="0"} 0
```

NOTE: reviewing the buffered request metrics from vtgate, nothing was buffered
during this event.


### Scenario 2: Solving with error Handling

One approach to preventing these `1105` errors is to handle them in the
application. In the next example we will configure gateslap to retry the MySQL
connection 10 times before it quits. Each time it will wait five seconds
(5000ms) for a `PRIMARY` tablet to return.

```
Terminal 2:
    Ctrl + C
    (venv) $ gateslap examples/02_light_traffic_error_handling.ini
```

As soon as traffic is sent issue the PlannedReparentShard command:

```
Terminal 3:
    $ time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0
```

#### Results:

The PlannedReparentShard event occurs, and the application recognizes the `1105`
error. The error is displayed on screen and the application sleeps for 5
seconds before retrying the connection. During the error handling the connection
is retried, and it is able to execute the SQL and continue processing. Nothing
is getting buffered in vtgate.

```sh
$ curl -s localhost:15001/metrics | grep -v '^#' | grep buffer_requests
vtgate_buffer_requests_buffered{keyspace="commerce",shard_name="0"} 0
vtgate_buffer_requests_buffered_dry_run{keyspace="commerce",shard_name="0"} 0
vtgate_buffer_requests_drained{keyspace="commerce",shard_name="0"} 0
vtgate_buffer_requests_evicted{keyspace="commerce",reason="BufferFull",shard_name="0"} 0
vtgate_buffer_requests_evicted{keyspace="commerce",reason="ContextDone",shard_name="0"} 0
vtgate_buffer_requests_evicted{keyspace="commerce",reason="WindowExceeded",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="BufferFull",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="Disabled",shard_name="0"} 122
vtgate_buffer_requests_skipped{keyspace="commerce",reason="LastFailoverTooRecent",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="LastReparentTooRecent",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="Shutdown",shard_name="0"} 0
```

NOTE: Once again no queries are being buffered in these examples.


### Scenario 3: Solving with Buffering

Another approach to this problem, is to employ buffering on vtgate. It is highly
recommended to use both buffering and error handling in your code; however for
purposes of highlighting buffering we will disable the error handling in this
example.

First we will need to reconfigure vtgate running in your terminal 1.

```
Terminal 1:
    Hit "Ctrl + C" to kill the vtgate process
```

Add the vtgate arguments needed to implement buffering. We are only implementing
basic buffering functionality. Notice the additional flag we are adding
to our vtgate process: `-enable_buffer=1`

```
Terminal 1:
    $ vtgate -topo_implementation etcd2 -topo_global_server_address localhost:2379 \
    -topo_global_root /vitess/global -log_dir ~/github/vitess/examples/local/vtdataroot/tmp \
    -log_queries_to_file ~/github/vitess/examples/local/vtdataroot/tmp/vtgate_querylog.txt \
    -port 15001 -grpc_port 15991 -mysql_server_port 15306 -mysql_server_socket_path /tmp/mysql.sock \
    -cell zone1 -cells_to_watch zone1 -tablet_types_to_wait PRIMARY,REPLICA \
    -service_map grpc-vtgateservice -pid_file ~/github/vitess/examples/local/vtdataroot/tmp/vtgate.pid \
    -mysql_auth_server_impl none -enable_buffer=1
```

We're using the `01_light_traffic.ini` which has error handling disabled.

```
Terminal 2:
    Ctrl + C
    (venv) $ gateslap examples/01_light_traffic.ini
```

As soon as traffic is sent issue the PlannedReparentShard command:

```
Terminal 3:
    $ time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0
```

#### Results:

Shortly after the PRS command is issued, the SQL statements pause momentarily.
During this time a message is logged to the terminal console window:

```
E1215 15:35:47.712589  251262 healthcheck.go:487] Adding 1 to PrimaryPromoted counter for target: keyspace:"commerce" shard:"0" tablet_type:REPLICA, tablet: zone1-0000000101, tabletType: PRIMARY
```

After this process completes, SQL statements resume processing once again. When
we take a look at stats (shown below) we will see for the first time records of
buffering occurring on the vtgate.

```sh
$ curl -s localhost:15001/metrics | grep -v '^#' | grep buffer_requests
vtgate_buffer_requests_buffered{keyspace="commerce",shard_name="0"} 6
vtgate_buffer_requests_buffered_dry_run{keyspace="commerce",shard_name="0"} 0
vtgate_buffer_requests_drained{keyspace="commerce",shard_name="0"} 6
vtgate_buffer_requests_evicted{keyspace="commerce",reason="BufferFull",shard_name="0"} 0
vtgate_buffer_requests_evicted{keyspace="commerce",reason="ContextDone",shard_name="0"} 0
vtgate_buffer_requests_evicted{keyspace="commerce",reason="WindowExceeded",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="BufferFull",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="Disabled",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="LastFailoverTooRecent",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="LastReparentTooRecent",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="Shutdown",shard_name="0"} 0
```

NOTE: You will see each of our 6 established connections were buffered during
the PRS event.



### Scenario 4: Quickly issued PRS events

In this scenario we are going to look at the buffering behavior when quickly
issuing several PlannedReparentShard operations. Restart the VTGate before
proceeding to reset the buffering statistics.

Restart the vtgate process to clear metrics:

```
Terminal 1:
    Ctrl + C
    $ vtgate -topo_implementation etcd2 -topo_global_server_address localhost:2379 \
    -topo_global_root /vitess/global -log_dir ~/github/vitess/examples/local/vtdataroot/tmp \
    -log_queries_to_file ~/github/vitess/examples/local/vtdataroot/tmp/vtgate_querylog.txt \
    -port 15001 -grpc_port 15991 -mysql_server_port 15306 -mysql_server_socket_path /tmp/mysql.sock \
    -cell zone1 -cells_to_watch zone1 -tablet_types_to_wait PRIMARY,REPLICA \
    -service_map grpc-vtgateservice -pid_file ~/github/vitess/examples/local/vtdataroot/tmp/vtgate.pid \
    -mysql_auth_server_impl none -enable_buffer=1
```

```
Terminal 2:
    Ctrl + C
    (venv) $ gateslap examples/01_light_traffic.ini

```

As soon as traffic is sent issue the PlannedReparentShard commands. Note there
is a 5 second sleep commands between the PRS statements.

```
Terminal 3:
    $ time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0 && sleep 5 && time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0
```

#### Results:

In this scenario, back to back PRS events were issued, only 5 seconds apart.
Due to the close nature of these events, buffering is disabled to protect Vitess
against events where PRS may be issued in a looping fashion. This behavior is
adjustable with the vtgate flag `-buffer_min_time_between_failovers`.

```sh
$ curl -s localhost:15001/metrics | grep -v '^#' | grep buffer_requests
vtgate_buffer_requests_buffered{keyspace="commerce",shard_name="0"} 6
vtgate_buffer_requests_buffered_dry_run{keyspace="commerce",shard_name="0"} 0
vtgate_buffer_requests_drained{keyspace="commerce",shard_name="0"} 6
vtgate_buffer_requests_evicted{keyspace="commerce",reason="BufferFull",shard_name="0"} 0
vtgate_buffer_requests_evicted{keyspace="commerce",reason="ContextDone",shard_name="0"} 0
vtgate_buffer_requests_evicted{keyspace="commerce",reason="WindowExceeded",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="BufferFull",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="Disabled",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="LastFailoverTooRecent",shard_name="0"} 28
vtgate_buffer_requests_skipped{keyspace="commerce",reason="LastReparentTooRecent",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="Shutdown",shard_name="0"} 0
```

NOTE: Here we will see the `LastFailoverTooRecent` metric to let us know these
PRS events are too close together for the vtgate to buffer again. You will also
see 6 events which were buffered from the first PRS event.

#### Preventing this issue

We can prevent this issue by implementing error handling, which your application
should be doing. Another way to handle the issue is to ensure you are waiting
for the `-buffer_min_time_between_failovers` timer to expire before issuing
the next PlannedReparentShard command.



### Scenario 5: Too many connections

Another aspect to be aware of is the `-buffer_size`. For this scenario we will
be setting the buffer size lower than the number of connections from the
application. As we're using 6 connections in our example we will set the
`buffer_size` down from the default of `1000` to `4`.

Restart the vtgate process to clear metrics:

```
Terminal 1:
    Hit "Ctrl + C" to kill the vtgate process

    $ vtgate -topo_implementation etcd2 -topo_global_server_address localhost:2379 \
    -topo_global_root /vitess/global -log_dir ~/github/vitess/examples/local/vtdataroot/tmp \
    -log_queries_to_file ~/github/vitess/examples/local/vtdataroot/tmp/vtgate_querylog.txt \
    -port 15001 -grpc_port 15991 -mysql_server_port 15306 -mysql_server_socket_path /tmp/mysql.sock \
    -cell zone1 -cells_to_watch zone1 -tablet_types_to_wait PRIMARY,REPLICA \
    -service_map grpc-vtgateservice -pid_file ~/github/vitess/examples/local/vtdataroot/tmp/vtgate.pid \
    -mysql_auth_server_impl none -enable_buffer=1 -buffer_size=4
```

```
Terminal 2:
    Ctrl + C
    (venv) $ gateslap examples/01_light_traffic.ini
```

```
Terminal 3:
    $ time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0
```

#### Results:

Two of the 6 threads will die, as they were unable to obtain a slot during the
buffering event. The remaining 4 threads will be buffered and will continue to
process in their thread. To avoid this issue you should set your buffer_size to
the estimated amount of requests you expect to get during the PRS event.

```sh
$ curl -s localhost:15001/metrics | grep -v '^#' | grep buffer_requests
vtgate_buffer_requests_buffered{keyspace="commerce",shard_name="0"} 8
vtgate_buffer_requests_buffered_dry_run{keyspace="commerce",shard_name="0"} 0
vtgate_buffer_requests_drained{keyspace="commerce",shard_name="0"} 4
vtgate_buffer_requests_evicted{keyspace="commerce",reason="BufferFull",shard_name="0"} 4
vtgate_buffer_requests_evicted{keyspace="commerce",reason="ContextDone",shard_name="0"} 0
vtgate_buffer_requests_evicted{keyspace="commerce",reason="WindowExceeded",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="BufferFull",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="Disabled",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="LastFailoverTooRecent",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="LastReparentTooRecent",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="Shutdown",shard_name="0"} 0
```

NOTE: Here we can see the `BufferFull` metric set to 4 to let us know the buffer
had an overflow.



### Scenario 6: Buffer time too Short

In this scenario we are going to set the `buffer_window` to a short period of
time, and hit the vtgate a bit harder with a different configuration file.

Restart the vtgate process to clear metrics:

```
Terminal 1:
    Hit "Ctrl + C" to kill the vtgate process

    $ vtgate -topo_implementation etcd2 -topo_global_server_address localhost:2379 \
    -topo_global_root /vitess/global -log_dir ~/github/vitess/examples/local/vtdataroot/tmp \
    -log_queries_to_file ~/github/vitess/examples/local/vtdataroot/tmp/vtgate_querylog.txt \
    -port 15001 -grpc_port 15991 -mysql_server_port 15306 -mysql_server_socket_path /tmp/mysql.sock \
    -cell zone1 -cells_to_watch zone1 -tablet_types_to_wait PRIMARY,REPLICA \
    -service_map grpc-vtgateservice -pid_file ~/github/vitess/examples/local/vtdataroot/tmp/vtgate.pid \
    -mysql_auth_server_impl none -enable_buffer=1 -buffer_window=1s
```

```
Terminal 2:
    Ctrl + C
    (venv) $ gateslap examples/03_short_timeout.ini
```

```
Terminal 3:
    $ time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0
```

#### Results:

In these results, we see a few SQL statements fail to buffer. They display
the standard `1105` error we've seen previously.

```sh
$ curl -s localhost:15001/metrics | grep -v '^#' | grep buffer_requests
vtgate_buffer_requests_buffered{keyspace="commerce",shard_name="0"} 10
vtgate_buffer_requests_buffered_dry_run{keyspace="commerce",shard_name="0"} 0
vtgate_buffer_requests_drained{keyspace="commerce",shard_name="0"} 4
vtgate_buffer_requests_evicted{keyspace="commerce",reason="BufferFull",shard_name="0"} 0
vtgate_buffer_requests_evicted{keyspace="commerce",reason="ContextDone",shard_name="0"} 0
vtgate_buffer_requests_evicted{keyspace="commerce",reason="WindowExceeded",shard_name="0"} 6
vtgate_buffer_requests_skipped{keyspace="commerce",reason="BufferFull",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="Disabled",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="LastFailoverTooRecent",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="LastReparentTooRecent",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="Shutdown",shard_name="0"} 0
```

NOTE: Reviewing these results we can see value for `WindowExceeded` at 6;
informing us the `buffer_window` was not long enough for these request.



### Scenario 7: Replica never becomes Primary

There may be time in which the PRS event takes too long and must be rolled back.
To accomplish this scenario we will need to ensure we are using an older version
of MySQL, and we will need to send excessive traffic to vtgate.

{{< warning >}}
This scenario assumes you are running Ubuntu LTS 20.04, you may have to adjust if
your environment is different.
{{< /warning >}}


Here we will tear down the cluster, install an older version of MySQL, and
rebuild:

```
Terminal 1:
    Hit "Ctrl + C" to kill the vtgate process

    $ ./401_teardown.sh
    $ rm -rf ./vtdataroot

    $ sudo apt-get install mysql-client-core-8.0=8.0.19-0ubuntu5 mysql-server-core-8.0=8.0.19-0ubuntu5

    $ ./101_initial_cluster.sh
    $ ps aux | grep [v]tgate
    $ pkill vtgate
    $ vtgate -topo_implementation etcd2 -topo_global_server_address localhost:2379 \
    -topo_global_root /vitess/global -log_dir ~/github/vitess/examples/local/vtdataroot/tmp \
    -log_queries_to_file ~/github/vitess/examples/local/vtdataroot/tmp/vtgate_querylog.txt \
    -port 15001 -grpc_port 15991 -mysql_server_port 15306 -mysql_server_socket_path /tmp/mysql.sock \
    -cell zone1 -cells_to_watch zone1 -tablet_types_to_wait PRIMARY,REPLICA \
    -service_map grpc-vtgateservice -pid_file ~/github/vitess/examples/local/vtdataroot/tmp/vtgate.pid \
    -mysql_auth_server_impl none -enable_buffer=1
```

```
Terminal 2:
    Ctrl + C
    (venv) $ gateslap examples/04_numerous_heavy_traffic.ini
```

As soon as the heavy traffic starts to generate send the PRS command.

```
Terminal 3:
    $ time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0  
```

#### Results:

Here the buffering takes too long to complete, as a result the application
heavily utilizes error handling to recover. When programming for error handling
in these events, consider allowing the client enough time to recover from an
attempted RPC + rollback. This scenario will retry the connection 10 times,
waiting 5 seconds between each attempt.

Part of the reason we had to downgrade MySQL was to make replication issues more
relevant. In this scenario vtgate bailed on the PlannedReparentShard as the
primary candidate `REPLICA` failed to catch up to the `PRIMARY`.

```
$ time vtctlclient -server localhost:15999 PlannedReparentShard -keyspace_shard=commerce/0
PlannedReparentShard Error: rpc error: code = Unknown desc = primary-elect tablet zone1-0000000101 failed
to catch up with replication MySQL56/4fb7c72c-62c8-11ec-8287-8cae4cdeeda4:1-1677: rpc error: code = Unknown
desc = TabletManager.WaitForPosition on zone1-0000000101 error: timed out waiting for position
4fb7c72c-62c8-11ec-8287-8cae4cdeeda4:1-1677: timed out waiting for position 4fb7c72c-62c8-11ec-8287-8cae4cdeeda4:1-1677

E1221 19:44:29.715359  203407 main.go:76] remote error: rpc error: code = Unknown desc = primary-elect tablet
zone1-0000000101 failed to catch up with replication MySQL56/4fb7c72c-62c8-11ec-8287-8cae4cdeeda4:1-1677:
rpc error: code = Unknown desc = TabletManager.WaitForPosition on zone1-0000000101 error: timed out waiting for position
4fb7c72c-62c8-11ec-8287-8cae4cdeeda4:1-1677: timed out waiting for position 4fb7c72c-62c8-11ec-8287-8cae4cdeeda4:1-1677

real	0m35.458s
user	0m0.015s
sys	0m0.005s

```

There are a few things we can do to resolve this issue:

* Upgrade the MySQL version
* Perform these operations during non-peak times
* Ensure we have error handling in case the PRS command fails
* Increase the buffer_window to buffer request instead of return errors

This scenario was designed to show buffering assisting, even during a failed
PlannedReparentShard:

```sh
curl -s localhost:15001/metrics | grep -v '^#' | grep buffer_requests
vtgate_buffer_requests_buffered{keyspace="commerce",shard_name="0"} 30
vtgate_buffer_requests_buffered_dry_run{keyspace="commerce",shard_name="0"} 0
vtgate_buffer_requests_drained{keyspace="commerce",shard_name="0"} 15
vtgate_buffer_requests_evicted{keyspace="commerce",reason="BufferFull",shard_name="0"} 0
vtgate_buffer_requests_evicted{keyspace="commerce",reason="ContextDone",shard_name="0"} 0
vtgate_buffer_requests_evicted{keyspace="commerce",reason="WindowExceeded",shard_name="0"} 15
vtgate_buffer_requests_skipped{keyspace="commerce",reason="BufferFull",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="Disabled",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="LastFailoverTooRecent",shard_name="0"} 50
vtgate_buffer_requests_skipped{keyspace="commerce",reason="LastReparentTooRecent",shard_name="0"} 0
vtgate_buffer_requests_skipped{keyspace="commerce",reason="Shutdown",shard_name="0"} 0
```

NOTE: Reviewing the results, we can see from the `WindowExceeded` metric some of
the buffered queries expired. If this is common you may want to increase your
`buffer_window` to cover these failures. Retrying this scenario with the following
vtgate flags appended resolves many of these errors:

`-buffer_max_failover_duration=1m -buffer_min_time_between_failovers=2m -buffer_window=60s`

## Revert your configurations

To undo our configuration we will need to tear the cluster down; upgrade MySQL;
then rebuild the vitess cluster:

```
Terminal 1:
    Ctrl + C

    $ ./401_teardown.sh
    $ rm -rf ./vtdataroot

    $ sudo apt-get upgrade && sudo apt-get update

```
