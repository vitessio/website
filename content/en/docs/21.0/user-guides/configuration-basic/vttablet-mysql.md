---
title: VTTablet and MySQL
weight: 8
---

Let us assume that we want to bring up a single unsharded keyspace. The first step is to identify the number of replicas (including the primary) we would like to deploy. We should also make a decision about how to distribute them across the cells.

Vitess requires you to assign a globally unique id (tablet UID) to every vttablet. This has to be an unsigned 32-bit integer. This is a legacy requirement derived from the fact that the MySQL server id (also an unsigned 32-bit integer) used to be the same as the tablet uid. This is not the case any more.

In terms of mapping these components to machines, Vitess allows you to run multiple of these on the same machine. If this is the case, you will need to assign non-conflicting ports for these servers to listen on.

VTTablet and MySQL are meant to be brought up as a pair within the same machine. By default, vttablet will connect to its MySQL over a unix socket.

Let us look at the steps to bring up the first pair for an unsharded keyspace `commerce` in cell1 and a tablet uid of 100.

## Starting MySQL

`mysqlctl` is a convenience wrapper that can bring up and initialize a fresh MySQL server, and isolate all associated files within directories that are tied to the unique UID. This makes it easy to bring up multiple MySQL instances on the same machine.

The necessary arguments to a `mysqlctl` are the `tablet_uid` and `mysql_port`. Here is a sample invocation:

```sh
mysqlctl \
  --log_dir=${VTDATAROOT}/tmp \
  --tablet_uid=100 \
  --mysql_port=17100 \
  init
```

### my.cnf

`mysqlctl` **will not** read configuration files from common locations such as `/etc/my.cnf` or `/etc/mysql/my.cnf`. Instead, it will create a separate `my.cnf` config file using builtin defaults. The source files can be found [here](https://github.com/vitessio/vitess/tree/main/config/mycnf). To add your own settings, you can set the `EXTRA_MY_CNF` environment variable to a list of colon-separated files. Alternatively, you can override the default behavior by specifying your own template file using the `-mysqlctl_mycnf_template` command line argument.

For example, to override the default innodb buffer pool size, you would create a file named `/path/to/common.cnf` as follows:
```text
innodb_buffer_pool_size=1G
```

And then launch mysqlctl with as follows:

```sh
EXTRA_MY_CNF=”/path/to/common.cnf” mysqlctl \
  --log_dir=${VTDATAROOT}/tmp \
  --tablet_uid=100 \
  --mysql_port=17100 \
  init
```

When specifying additional configuration changes to Vitess, please keep in mind that changing the following settings is unsupported:

| Setting             | Reason         |
|---------------------|----------------|
| `auto_commit`       | MySQL autocommit needs to be turned on. VTTablet uses connection pools to MySQL. If autocommit is turned off, MySQL will start an implicit transaction (with a point in time snapshot) for each connection and will work very hard at keeping the current view unchanged, which would be counter-productive. |
| `log-bin`           | Several Vitess features rely on the binary log being enabled. |
| `binlog-format`     | Vitess only supports row-based replication. Do not change this setting from the included configuration files. |
| `binlog-row-image`  | Vitess only supports the default value (`FULL`) |
| `log-slave-updates` | Vitess requires this setting enabled, as it is in the included configuration files. |
| `character-set\*`   | Vitess only supports `utf8` (and variants such as `utf8mb4`) | 
| `gtid-mode`         | Vitess relies on GTIDs to track changes to topology. |
| `gtid-strict-mode`/`enforce-gtid-consistency` | Vitess requires this setting to be unchanged. |

Support was recently added to override `sql_mode`. However, we recommend keeping `STRICT_TRANS_TABLES` or replacing it with`STRICT_ALL_TABLES`. Without one of these settings, MySQL could truncate values at the time of writing, and this can mismatch with decisions made by the sharding logic and lead to data corruption. VTTablet ensures that one of these  values is set. If absolutely necessary, you can override this check by setting `-enforce_strict_trans_tables=false` while invoking vttablet.

### init\_db.sql

After mysqld comes up, `mysqlctl` will initialize the server using an internal script, the contents of which can be found [here](https://github.com/vitessio/vitess/blob/main/config/init_db.sql). You can override this behavior by providing your own script using the `-init_db_sql_file` command line argument.

### Disable AppArmor

There is a common pitfall to watch out for: If you see an error like this in the mysqlctl logs, you may need to [disable AppArmor](../../../get-started/local/#disable-apparmor-or-selinux):

```text
I0429 01:16:25.648506       1 mysqld.go:454] Waiting for mysqld socket file (/vtdataroot/tabletdata/mysql.sock) to be ready...
I0429 01:16:25.656153       1 mysqld.go:399] Mysqld.Start(1588122985) stderr: mysqld: [ERROR] Could not open required defaults file: /vtdataroot/tabletdata/my.cnf
I0429 01:16:25.656180       1 mysqld.go:399] Mysqld.Start(1588122985) stderr: mysqld: [ERROR] Fatal error in defaults handling. Program aborted!
I0429 01:16:25.657249       1 mysqld.go:418] Mysqld.Start(1588122985) exit: exit status 1
```

Disabling AppArmor once may not be enough. Many software installs or upgrades automatically install it back. You may have to disable it again if this happens.

### Verify MySQL

You can verify that MySQL came up successfully by connecting to it from the command line client:

```sh
$ mysql -S ${VTDATAROOT}/vt_0000000100/mysql.sock -u vt_dba
[snip]
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| _vt                |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
5 rows in set (0.00 sec)
```

The MySQL instance that was brought up has no identity related to keyspace or shard at this moment. These will be assigned in subsequent steps.

### mysqlctld

`mysqlctld` is the server version of `mysqlctl`. If the target directories are empty when it is invoked, it automatically performs an `init`. The process can subsequently receive commands from vttablet to perform housekeeping operations like shutting down and restarting MySQL as needed.

To enable communication with vttablet, the server must be configured to receive grpc messages on a unix domain socket:

```
mysqlctld \
  --log_dir=${VTDATAROOT}/tmp \
  --tablet_uid=100 \
  --mysql_port=17100 \
  --socket_file=/path/to/socket_file
```

When starting vttablet, the following additional flag must be specified:

```
--mysqlctl_socket=/path/to/socket_file
```
## Starting vttablet

VTTablet should be brought up on the same machine as the MySQL instance. It needs the following flags:

* <topo_flags> and <backup_flags>.
* `tablet-path`: This should be the cell name followed by a `-` and the tablet UID used for `mysqlctl`. VTTablet will infer the `cell` name from this. Example: `cell1-100`.
* `init_keyspace`: The keyspace that the tablet is going to serve. This will cause a keyspace to be created if one is not present.
* `init_shard`: The shard that the tablet is going to serve. This will cause a shard to be created if one is not present.
* `init_tablet_type`: This will typically be REPLICA. You may use other tablet types like “RDONLY”. Note that you are not allowed to start a tablet as a "PRIMARY".
* `port`, `grpc_port`, and `--service_map` `'grpc-queryservice,grpc-tabletmanager'`

There are some additional parameters that we recommend setting:

* `enable_replication_reporter`: Enabling this flag will make vttablet send its replication lag information to the vtgates, and they will use this information to avoid sending queries to replicas that are lagged beyond a threshold.
* `unhealthy_threshold`: If `enable_replication_reporter` is enabled, and the replication lag exceeds this threshold, then vttablet stops serving queries. This value is meant to match the vtgate `discovery_high_replication_lag_minimum_serving` flag.
* `degraded_threshold`: This flag does not change vttablet’s behavior. This threshold is used to report a warning in the status page if the replication lag exceeds this threshold. This value is meant to match the vtgate `discovery_low_replication_lag` flag.
* `restore_from_backup`: This flag informs vttablet to automatically restore data from the latest backup. Once this task completes, vttablet will point itself at the current primary to catch up on replication. When that falls below the specified threshold, vtgate will automatically start sending queries to the tablet.
* `queryserver-config-pool-size`:This value should be set to the max number of simultaneous queries you want MySQL to run. This should typically be around 2-3x the number of allocated CPUs. Around 4-16. There is not much harm in going higher with this value, but you may see no additional benefits. This pool gets used if the workload is set to `oltp`, which is the default.
* `queryserver-config-transaction-cap`: This value should be set to how many concurrent transactions you wish to allow. This should be a function of transaction rate and transaction length. Typical values are in the low 100s.
* `queryserver-config-stream-pool-size`: This value is relevant only if you plan to run streaming queries using the `workload='olap'` setting. This value depends on how many simultaneous streaming queries you plan to run. Typical values are similar to `queryserver-config-pool-size`.
* `queryserver-config-query-timeout`: This value should be set to the upper limit you’re willing to allow an OLTP query to run before it’s deemed too expensive or detrimental to the rest of the system. VTTablet will kill any query that exceeds this timeout. This value is usually around 15-30s.
* `queryserver-config-transaction-timeout`: This value is meant to protect the situation where a client has crashed without completing a transaction. Typical value for this timeout is 30s.
* `queryserver-config-idle-timeout`:  This value sets a time in seconds after which, if a connection has not been used, this connection will be removed from pool. This effectively manages number of connection objects and optimizes the pool performance.
* `queryserver-config-max-result-size`: This parameter prevents the OLTP application from accidentally requesting too many rows. If the result exceeds the specified number of rows, VTTablet returns an error. The default value is 10,000.

Here is a typical vttablet invocation:

```text
vttablet <topo_flags> <backup_flags> \
  --log_dir=${VTDATAROOT}/tmp \
  --cell=cell1 \
  --tablet-path=cell1-100 \
  --init_keyspace=commerce \
  --init_shard=0 \
  --init_tablet_type=replica \
  --port=15100 \
  --grpc_port=16100 \
  --service_map 'grpc-queryservice,grpc-tabletmanager’ \
  --enable_replication_reporter=true \
  --restore_from_backup=true \
  --queryserver-config-pool-size=16 \
  --queryserver-config-transaction-cap=300 \
  --queryserver-config-stream-pool-size= 16
```

### Key Configuration Notes

* It is important to set MySQL’s `max_connections` property to be 50%-100% higher than the total number of connections in the various pools. 
	* This is because Vitess may have to kill connections and open new ones. MySQL accounting has a delay in how it counts closed connections, which may cause its view of the number of connections to exceed the ones currently opened by Vitess. For example, in the above example, the `max_connections` settings should be around 800.
* It is also important to set vttablets `queryserver-config-idle-timeout` to be at least 10% lower than MySQL's `wait_timeout`.
	* This is because MySQL's `wait_timeout` is the number of seconds the server waits for activity on a noninteractive connection before closing it. So if the vttablet setting is not lower the MySQL limit will be hit first and can cause issues with performance. The defaults are as follows: `queryserver-config-idle-timeout` defaults to 30 minutes and MySQL's `wait_timeout` defaults to 8 hours. 

It is normal to see errors like these in the log file until MySQL instances have been initialized and a vttablet has been elected as primary:

```text
2020-04-27T00:38:02.040081Z 2 [Note] Aborted connection 2 to db: 'unconnected' user: 'root' host: 'localhost' (Got an error reading communication packets)
```

Starting the first vttablet against a keyspace and shard performs the following actions:

* Create a keyspace and shard in the global topo if these did not exist before.
* Perform a [RebuildKeyspaceGraph](../../../reference/programs/vtctl/keyspaces/#rebuildkeyspacegraph) to deploy the global topo to the current cell (cell1).
* Create a tablet record, which will allow vtgates to discover it.
* No restore action will be performed because this is the first time vttablet is coming up and no backups exist yet.

The vttablet will be unhealthy because the database for the keyspace has not been created. Visiting the `/debug/status` page on its port should show the following information:

![unhealthy-tablet](../img/unhealthy-tablet.png)

The next step is to bring up the rest of the vttablet-MySQL pairs on other machines or different ports of the same machine.

## Tablet Records

You can find out the current state of all vttablets with the following command:

```sh
$ vtctldclient GetTablets
cell1-0000000100 commerce 0 primary sougou-lap1:15100 sougou-lap1:17100 [] 2021-01-02T22:27:11Z
cell1-0000000101 commerce 0 replica sougou-lap1:15101 sougou-lap1:17101 [] <null>
cell1-0000000102 commerce 0 rdonly sougou-lap1:15102 sougou-lap1:17102 [] <null>
```

This information is extracted from the “tablet record” in the cell specific topo. You can also browse to this information in VTAdmin either from the Tablets page or from the Topology page.

![vtctld-tablet-list](../img/vtadmin-tablet-list.png)

You can move a vttablet-MySQL pair to a new host after shutting them down on the current host. Bringing up the new pair with the same UID will update the tablet record with the new address and ports. This will be noticed by the vtgates and they will adjust their traffic accordingly. However, you must not move a tablet to another cell.

Gracefully bringing down a vttablet will remove the address information from the tablet record thereby informing the vtgates that they should not attempt to send any more traffic to the tablets.

If a vttablet crashes, the address info will remain in the topo. However, vtgates will notice that the tablet is not reachable and will remember it as unhealthy. They will keep attempting to contact the tablet until it comes back up as healthy.

It is recommended that you delete the tablet record if you intend to bring down a vttablet permanently. The command to delete a tablet is:

```text
vtctldclient DeleteTablets cell1-100
```

