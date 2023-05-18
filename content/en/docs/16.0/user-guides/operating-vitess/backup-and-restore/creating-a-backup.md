---
title: Creating a Backup
weight: 2
aliases: ['/docs/user-guides/backup-and-restore/']
---

## Using xtrabackup

{{< warning >}}
Please see this [known issue](https://github.com/vitessio/vitess/releases/tag/v16.0.0#mysql-xtrabackup-ddl) if you are taking a backup with XtraBackup with MySQL tables modified via `INSTANT DDL`
{{</ warning >}}

The default backup implementation is `builtin`, however we strongly recommend using the `xtrabackup` engine as it is more robust and allows for non-blocking backups. Restores will always be done with whichever engine was used to create the backup.

### Prerequisites

A compatible version of [xtrabackup](https://www.percona.com/doc/percona-xtrabackup/latest/index.html) and [xbstream](https://docs.percona.com/percona-xtrabackup/8.0/xtrabackup_bin/backup.streaming.html), if needed, must be present in your `$PATH` prior to running the `Backup[Shard]` command.

### Supported Versions

* [MySQL 5.7](https://www.percona.com/doc/percona-xtrabackup/2.4/index.html#installation)
* [MySQL 8.0](https://www.percona.com/doc/percona-xtrabackup/8.0/index.html#installation)

### Configuration

To use `xtrabackup` with Vtbackup, VTTablet or Vtctld, the following flags must be set.

__Required flags:__

* `--backup_engine_implementation=xtrabackup`
* `--xtrabackup_user string` 
	* The user that xtrabackup will use to connect to the database server. This user must have the [necessary privileges](https://www.percona.com/doc/percona-xtrabackup/2.4/using_xtrabackup/privileges.html#permissions-and-privileges-needed).
    * This user will need to be authorized to connect to mysql locally without a password using [auth_socket](https://dev.mysql.com/doc/refman/5.7/en/socket-pluggable-authentication.html).

Additionally required for MySQL 8.0:

* `--xtrabackup_stream_mode=xbstream`

<!-- TODO: create backups with vtbackup
## Create backups with vtctl
-->

### Common Errors and Resolutions

__No xtrabackup User passed to vttablet:__

```
E0310 08:15:45.336083  197442 main.go:72] remote error: rpc error: code = Unknown desc = TabletManager.Backup on zone1-0000000102 error: xtrabackupUser must be specified.: xtrabackupUser must be specified
```

Fix: Set the vtctld and vttablet flag `--xtrabackup_user`

__xtrabackup binary not found in $PATH:__

```
E0310 08:22:22.260044  200147 main.go:72] remote error: rpc error: code = Unknown desc = TabletManager.Backup on zone1-0000000102 error: unable to start backup: exec: "xtrabackup": executable file not found in $PATH: unable to start backup: exec: "xtrabackup": executable file not found in $PATH
```

Fixes:

	* Ensure the xtrabackup binary is in the $PATH for the $USER running vttablet
	* Alternatively, set --xtrabackup_root_path on vttablet provide path to xtrabackup/xbstream binaries via vtctld and vttablet flags

__Tar format no longer supported in 8.0:__

```
I0310 12:34:47.900363  211809 backup.go:163] I0310 20:34:47.900004 xtrabackupengine.go:310] xtrabackup stderr: Invalid --stream argument: tar
Streaming in tar format is no longer supported in 8.0; use xbstream instead
```

Fix: Set the `--xtrabackup_stream_mode` flag to to xbstream on vttablets and vtctlds

__Unsupported mysql server version:__

```
I0310 12:49:32.279729  215835 backup.go:163] I0310 20:49:32.279435 xtrabackupengine.go:310] xtrabackup stderr: Error: Unsupported server version 8.0.23-0ubuntu0.20.04.1.
I0310 12:49:32.279773  215835 backup.go:163] I0310 20:49:32.279485 xtrabackupengine.go:310] xtrabackup stderr: Please upgrade PXB, if a new version is available. To continue with risk, use the option --no-server-version-check.
```

To continue with risk: Set `--xtrabackup_backup_flags=--no-server-version-check`. Note this occurs when your MySQL server version is technically unsupported by `xtrabackup`.

## Create backups with vtctl

__Run the following vtctl command to create a backup:__

``` sh
vtctldclient --server=<vtctld_host>:<vtctld_port> Backup <tablet-alias>
```

If the engine is `builtin`, replication will be stopped prior to shutting down mysqld for the backup.

If the engine is `xtrabackup`, the tablet can continue to serve traffic while the backup is running.

__Run the following vtctl command to backup a specific shard:__

``` sh
vtctldclient --server=<vtctld_host>:<vtctld_port> BackupShard [--allow_primary=false] <keyspace/shard>
```

## Backing up Topology Server

The Topology Server stores metadata (and not tablet data). It is recommended to create a backup using the method described by the underlying plugin:

* [etcd](https://etcd.io/docs/v3.4.0/op-guide/recovery/)
* [ZooKeeper](http://zookeeper.apache.org/doc/r3.6.0/zookeeperAdmin.html#sc_dataFileManagement)
* [Consul](https://www.consul.io/docs/commands/snapshot.html)
