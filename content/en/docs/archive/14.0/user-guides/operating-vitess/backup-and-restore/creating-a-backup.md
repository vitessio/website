---
title: Creating a Backup
weight: 2
aliases: ['/docs/user-guides/backup-and-restore/']
---

{{< warning >}}
Backups of MySQL 8.0.30 and later are only supported in Vitess 14.0.2 and later. You can see additional details [here](https://github.com/vitessio/vitess/pull/10847).
{{< /warning >}}

## Creating a backup

The default backup implementation is `builtin`, however we strongly recommend using the `xtrabackup` engine as it is more robust and allows for non-blocking backups. Restores will always be done with whichever engine was used to create the backup.

### Prerequisite

A compatible version of [xtrabackup](https://www.percona.com/doc/percona-xtrabackup/LATEST/index.html) and [xbstream](https://www.percona.com/doc/percona-xtrabackup/LATEST/xtrabackup_bin/backup.streaming.html), if needed, must be present in your `$PATH` prior to running the `Backup[Shard]` command.

### Supported Versions of Xtrabackup

* [For MySQL 5.7](https://www.percona.com/doc/percona-xtrabackup/2.4/index.html#installation)
* [MySQL 8.0](https://www.percona.com/doc/percona-xtrabackup/8.0/index.html#installation)

### Basic VTTablet and Vtctld Configuration

Required vttablet and vtctld flags:

* `--backup_engine_implementation=xtrabackup`
* `--xtrabackup_user string` 
	* The user that xtrabackup will use to connect to the database server. This user must have the [necessary privileges](https://www.percona.com/doc/percona-xtrabackup/2.4/using_xtrabackup/privileges.html#permissions-and-privileges-needed).
    * This user will need to be authorized to connect to mysql locally without a password using [auth_socket](https://dev.mysql.com/doc/refman/5.7/en/socket-pluggable-authentication.html).

Additionally required for MySQL 8.0:

* `--xtrabackup_stream_mode=xbstream`

### Run the following vtctl command to create a backup:

``` sh
vtctlclient --server=<vtctld_host>:<vtctld_port> Backup <tablet-alias>
```

If the engine is `builtin`, replication will be stopped prior to shutting down mysqld for the backup.

If the engine is `xtrabackup`, the tablet can continue to serve traffic while the backup is running.

### Run the following vtctl command to backup a specific shard:

``` sh
vtctlclient --server=<vtctld_host>:<vtctld_port> BackupShard -- [--allow_primary=false] <keyspace/shard>
```

## Restoring a backup

When a tablet starts, Vitess checks the value of the `-restore_from_backup` command-line flag to determine whether to restore a backup to that tablet.

* If the flag is present, Vitess tries to restore the most recent backup from the [BackupStorage](../backup-and-restore/#backup-storage-services) system when starting the tablet or if the `--restore_from_backup_ts` flag (Vitess 12.0+) is also set then using the latest backup taken at or before this timestamp instead. Example: '2021-04-29.133050'
* If the flag is absent, Vitess does not try to restore a backup to the tablet. This is the equivalent of starting a new tablet in a new shard.

As noted in the [Configuration](#basic-vttablet-and-vtctld-configuration) section, the flag is generally enabled all of the time for all of the tablets in a shard. By default, if Vitess cannot find a backup in the Backup Storage system, the tablet will start up empty. This behavior allows you to bootstrap a new shard before any backups exist.

If the `--wait_for_backup_interval` flag is set to a value greater than zero, the tablet will instead keep checking for a backup to appear at that interval. This can be used to ensure tablets launched concurrently while an initial backup is being seeded for the shard (e.g. uploaded from cold storage or created by another tablet) will wait until the proper time and then pull the new backup when it's ready.

``` sh
vttablet ... --backup_storage_implementation=file \
             --file_backup_storage_root=/nfs/XXX \
             --restore_from_backup
```

## Managing backups

**vtctl** provides two commands for managing backups:

* [ListBackups](https://vitess.io/docs/reference/programs/vtctl/shards/#listbackups) displays the existing backups for a keyspace/shard in chronological order.

    ``` sh
    vtctlclient --server=<vtctld_host>:<vtctld_port> ListBackups <keyspace/shard>
    ```

* [RemoveBackup](https://vitess.io/docs/reference/programs/vtctl/shards/#removebackup) deletes a specified backup for a keyspace/shard.

    ``` sh
    vtctlclient --server=<vtctld_host>:<vtctld_port> RemoveBackup <keyspace/shard> <backup name>
    ```

You can also confirm your backup finished by viewing the files in your configured `--<engine>_backup_storage_root` location. You will still need to test and verify these backups for completeness. Note that backups are stored by keyspace and shard under `--<engine>_backup_storage_root`. For example, when using `--file_backup_storage_root=/vt/vtdataroot/backups`:

```sh
/vt/vtdataroot/backups/commerce/0/2021-03-10.205419.zone1-0000000102:
backup.xbstream.gz  MANIFEST
```

Each backup contains a manifest file with general information about the backup:

```sh
MySQL 8.0 xbstream Manifest
{
  "BackupMethod": "xtrabackup",
  "Position": "MySQL56/c022ad67-81fc-11eb-aa0e-1c1bb572885f:1-50",
  "BackupTime": "2021-03-11T00:01:37Z",
  "FinishedTime": "2021-03-11T00:01:42Z",
  "FileName": "backup.xbstream.gz",
  "ExtraCommandLineParams": "--no-server-version-check",
  "StreamMode": "xbstream",
  "NumStripes": 0,
  "StripeBlockSize": 102400,
  "SkipCompress": false
}
```

## Bootstrapping a new tablet

Bootstrapping a new tablet is almost identical to restoring an existing tablet. The only thing you need to be cautious about is that the tablet specifies its keyspace, shard and tablet type when it registers itself in the topology. Specifically, make sure that the following additional vttablet parameters are set:

``` sh
    --init_keyspace <keyspace>
    --init_shard <shard>
    --init_tablet_type replica|rdonly
```

The bootstrapped tablet will restore the data from the backup and then apply changes, which occurred after the backup, by restarting replication.

## Common Errors and Resolutions

### No xtrabackup User passed to vttablet

```
E0310 08:15:45.336083  197442 main.go:72] remote error: rpc error: code = Unknown desc = TabletManager.Backup on zone1-0000000102 error: xtrabackupUser must be specified.: xtrabackupUser must be specified
```

Fix: Set the vtctld and vttablet flag `--xtrabackup_user`

### xtrabackup binary not found in $PATH

```
E0310 08:22:22.260044  200147 main.go:72] remote error: rpc error: code = Unknown desc = TabletManager.Backup on zone1-0000000102 error: unable to start backup: exec: "xtrabackup": executable file not found in $PATH: unable to start backup: exec: "xtrabackup": executable file not found in $PATH
```

Fixes:

	* Ensure the xtrabackup binary is in the $PATH for the $USER running vttablet
	* Alternatively, set --xtrabackup_root_path on vttablet provide path to xtrabackup/xbstream binaries via vtctld and vttablet flags

### Tar format no longer supported in 8.0

```
I0310 12:34:47.900363  211809 backup.go:163] I0310 20:34:47.900004 xtrabackupengine.go:310] xtrabackup stderr: Invalid --stream argument: tar
Streaming in tar format is no longer supported in 8.0; use xbstream instead
```

Fix: Set the `--xtrabackup_stream_mode` flag to to xbstream on vttablets and vtctlds

### Unsupported mysql server version

```
I0310 12:49:32.279729  215835 backup.go:163] I0310 20:49:32.279435 xtrabackupengine.go:310] xtrabackup stderr: Error: Unsupported server version 8.0.23-0ubuntu0.20.04.1.
I0310 12:49:32.279773  215835 backup.go:163] I0310 20:49:32.279485 xtrabackupengine.go:310] xtrabackup stderr: Please upgrade PXB, if a new version is available. To continue with risk, use the option --no-server-version-check.
```

To continue with risk: Set `--xtrabackup_backup_flags=--no-server-version-check`. Note this occurs when your MySQL server version is technically unsupported by `xtrabackup`.

## Backing up Topology Server

The Topology Server stores metadata (and not tablet data). It is recommended to create a backup using the method described by the underlying plugin:

* [etcd](https://etcd.io/docs/v3.4.0/op-guide/recovery/)
* [ZooKeeper](http://zookeeper.apache.org/doc/r3.6.0/zookeeperAdmin.html#sc_dataFileManagement)
* [Consul](https://www.consul.io/docs/commands/snapshot.html)
