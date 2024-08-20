---
title: Creating a Backup
weight: 2
aliases: ['/docs/user-guides/backup-and-restore/']
---

## Choosing the Backup Type

As described in [Backup types](../overview/#backup-types), you choose to run a full Backup (the default) or an incremental Backup.

Full backups will use the backup engine chosen in the tablet's [configuration](#configuration). Incremental backups will always copy MySQL's binary logs, irrespective of the configured backup engine.

## Using xtrabackup

The default backup implementation is `builtin`, however we strongly recommend using the `xtrabackup` engine as it is more robust and allows for non-blocking backups. Restores will always be done with whichever engine was used to create the backup.

### Prerequisites

A compatible version of [xtrabackup](https://www.percona.com/doc/percona-xtrabackup/latest/index.html) and [xbstream](https://docs.percona.com/percona-xtrabackup/8.0/xtrabackup_bin/backup.streaming.html), if needed, must be present in your `$PATH` prior to running the `Backup[Shard]` command.

### Supported Versions

* [MySQL 8.0](https://www.percona.com/doc/percona-xtrabackup/8.0/index.html#installation)

### Configuration

To use `xtrabackup` with Vtbackup, VTTablet or Vtctld, the following flags must be set.

__Required flags:__

* `--backup_engine_implementation=xtrabackup`
* `--xtrabackup_user string` 
	* The user that xtrabackup will use to connect to the database server. This user must have the [necessary privileges](https://www.percona.com/doc/percona-xtrabackup/2.4/using_xtrabackup/privileges.html#permissions-and-privileges-needed).
    * This user will need to be authorized to connect to mysql locally without a password using [auth_socket](https://dev.mysql.com/doc/refman/8.0/en/socket-pluggable-authentication.html).

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

## Create a Full Backup with vtctl

__Run the following vtctl command to create a backup:__

```sh
vtctldclient --server=<vtctld_host>:<vtctld_port> Backup [--upgrade-safe=false] <tablet-alias>
```

If the engine is `builtin`, replication will be stopped prior to shutting down mysqld for the backup.

If the engine is `xtrabackup`, the tablet can continue to serve traffic while the backup is running.

__Run the following vtctl command to backup a specific shard:__

``` sh
vtctldclient --server=<vtctld_host>:<vtctld_port> BackupShard [--allow_primary=false] [--upgrade-safe=false] <keyspace/shard>
```

## Create an Incremental Backup with vtctl

An incremental backup requires additional information: the point from which to start the backup. An incremental backup is taken by supplying `--incremental-from-pos` to the `Backup` or `BackupShard` command. The argument may either indicate:

- A valid position.
- A name of a successful backup.
- Or, the value `auto`.

```sh
vtctldclient Backup --incremental-from-pos="MySQL56/0d7aaca6-1666-11ee-aeaf-0a43f95f28a3:1-53" zone1-0000000102

vtctldclient Backup --incremental-from-pos="0d7aaca6-1666-11ee-aeaf-0a43f95f28a3:1-53" zone1-0000000102

vtctldclient Backup --incremental-from-pos="2024-01-10.062022.zone1-0000000101 commerce/0" zone1-0000000102

vtctldclient Backup --incremental-from-pos="auto" zone1-0000000102

vtctldclient BackupShard --incremental-from-pos=auto commerce/0
```

When `--incremental-from-pos` supplies a position, you may choose to use or to omit the `MySQL56/` prefix (which you can find in the backup manifest's Position).

When `--incremental-from-pos` indicates a backup name, that must be a successfully completed, existing backup. It may be either a full or an incremental backup.

When `--incremental-from-pos="auto"`, Vitess chooses the position of the last successful backup as the starting point for the incremental backup. This is a convenient way to ensure a sequence of contiguous incremental backups.

An incremental backup backs up one or more MySQL binary log files. These binary log files may begin with the requested position, or with an earlier position. They will necessarily include the requested position. When the incremental backup begins, Vitess rotates the MySQL binary logs on the tablet, so that it does not back up an active log file.

If Vitess finds that the database made no writes since the requested backup/position, then the incremental backup is deemed _empty_ and produces no artifacts, essentially becoming a no-op. The `Backup/BackupShard` command exits with success code, but there is no `MANIFEST` file created and no backup name.

An incremental backup fails when it is unable to find binary log files that covers the requested position. This can happen if the binary logs are purged earlier than the incremental backup was taken. It essentially means there's a gap in the changelog events. **Note** that while on one tablet the binary logs may be missing, another tablet may still have binary logs that cover the requested position.

## Backing up Topology Server

The Topology Server stores metadata (and not tablet data). It is recommended to create a backup using the method described by the underlying plugin:

* [etcd](https://etcd.io/docs/v3.4.0/op-guide/recovery/)
* [ZooKeeper](http://zookeeper.apache.org/doc/r3.6.0/zookeeperAdmin.html#sc_dataFileManagement)
* [Consul](https://www.consul.io/docs/commands/snapshot.html)
