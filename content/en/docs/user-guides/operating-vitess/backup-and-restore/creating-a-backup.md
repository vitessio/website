	---
title: Creating a Backup
weight: 2
aliases: ['/docs/user-guides/backup-and-restore/']
---

## Creating a backup

The default backup implementation is ‘builtin’, however we strongly recommend using the xtrabackup engine given builtin’s lingering issues. Restores will always be done with whichever engine was used to create the backup.

### Prerequisite

A compatible version of [xtrabackup](https://www.percona.com/doc/percona-xtrabackup/LATEST/index.html) and [xbstream](https://www.percona.com/doc/percona-xtrabackup/LATEST/xtrabackup_bin/backup.streaming.html), if needed, must be present in $PATH prior to running the backup command.

### Supported Versions of Xtrabackup

* [For MySQL 5.7 and MariaDB 10](https://www.percona.com/doc/percona-xtrabackup/2.4/index.html#installation)
* [MySQL 8.0](https://www.percona.com/doc/percona-xtrabackup/8.0/index.html#installation)
* MariaDB 10.3 is not compatible with xtrabackup.

### Basic VTTablet Configuration

Required vttablet flags:

* -backup_engine_implementation=xtrabackup
* -xtrabackup_user string 
	* The string should be the user that xtrabackup will use to connect to the database server. This user must have the necessary privileges.

Required for MySQL 8.0:

* -xtrabackup_stream_mode=xbstream
* -xtrabackup_backup_flags=--no-server-version-check 

### Run the following vtctl command to create a backup:

``` sh
vtctl Backup <tablet-alias>
```

If the engine is `builtin`, in response to this command, the designated tablet performs the following
sequence of actions:

1. Switches its type to `BACKUP`. After this step, the tablet is no
   longer used by VTGate to serve any query.

1. Stops replication, gets the current replication position (to be saved in the
   backup along with the data).

1. Shuts down its mysqld process.

1. Copies the necessary files to the Backup Storage implementation that was
   specified when the tablet was started. Note if this fails, we still keep
   going, so the tablet is not left in an unstable state because of a storage
   failure.

1. Restarts mysqld.

1. Restarts replication (with the right semi-sync flags corresponding to its
   original type, if applicable).

1. Switches its type back to its original type. After this, it will most likely
   be behind on replication, and not used by VTGate for serving until it catches
   up.

If the engine is `xtrabackup`, we do not do any of the above. The tablet can
continue to serve traffic while the backup is running.

## Common Errors and Resolutions

### Error:
E0310 08:15:45.336083  197442 main.go:72] remote error: rpc error: code = Unknown desc = TabletManager.Backup on zone1-0000000102 error: xtrabackupUser must be specified.: xtrabackupUser must be specified

* Fix: Set vttablet flag [-xtrabackup_user](../#basic-vttablet-configuration)

### Error:
E0310 08:22:22.260044  200147 main.go:72] remote error: rpc error: code = Unknown desc = TabletManager.Backup on zone1-0000000102 error: unable to start backup: exec: "xtrabackup": executable file not found in $PATH: unable to start backup: exec: "xtrabackup": executable file not found in $PATH

* Fixes:
	* Ensure the xtrabackup binary is in the $PATH for the $USER running vttablet
	* Alternatively, set -xtrabackup_root_path on vttablet provide path to xtrabackup/xbstream binaries via vttablet flag

### Error: 
I0310 12:34:47.900363  211809 backup.go:163] I0310 20:34:47.900004 xtrabackupengine.go:310] xtrabackup stderr: Invalid --stream argument: tar
Streaming in tar format is no longer supported in 8.0; use xbstream instead

* Fix: Set [-xtrabackup_stream_mode to xbstream](../#basic-vttablet-configuration) on vttablet 

## Restoring a backup

When a tablet starts, Vitess checks the value of the `-restore_from_backup` command-line flag to determine whether to restore a backup to that tablet.

* If the flag is present, Vitess tries to restore the most recent backup from the Backup Storage system when starting the tablet.
* If the flag is absent, Vitess does not try to restore a backup to the tablet. This is the equivalent of starting a new tablet in a new shard.

As noted in the [Configuration](#vttablet-configuration) section, the flag is generally enabled all of the time for all of the tablets in a shard. By default, if Vitess cannot find a backup in the Backup Storage system, the tablet will start up empty. This behavior allows you to bootstrap a new shard before any backups exist.

If the `-wait_for_backup_interval` flag is set to a value greater than zero, the tablet will instead keep checking for a backup to appear at that interval. This can be used to ensure tablets launched concurrently while an initial backup is being seeded for the shard (e.g. uploaded from cold storage or created by another tablet) will wait until the proper time and then pull the new backup when it's ready.

``` sh
vttablet ... -backup_storage_implementation=file \
             -file_backup_storage_root=/nfs/XXX \
             -restore_from_backup
```

## Managing backups

**vtctl** provides two commands for managing backups:

* [ListBackups](https://vitess.io/docs/reference/programs/vtctl/shards/#listbackups) displays the existing backups for a keyspace/shard in chronological order.

    ``` sh
    vtctl ListBackups <keyspace/shard>
    ```

* [RemoveBackup](https://vitess.io/docs/reference/programs/vtctl/shards/#removebackup) deletes a specified backup for a keyspace/shard.

    ``` sh
    RemoveBackup <keyspace/shard> <backup name>
    ```

## Bootstrapping a new tablet

Bootstrapping a new tablet is almost identical to restoring an existing tablet. The only thing you need to be cautious about is that the tablet specifies its keyspace, shard and tablet type when it registers itself at the topology. Specifically, make sure that the following additional vttablet parameters are set:

``` sh
    -init_keyspace <keyspace>
    -init_shard <shard>
    -init_tablet_type replica|rdonly
```

The bootstrapped tablet will restore the data from the backup and then apply changes, which occurred after the backup, by restarting replication.

## Backing up Topology Server

The Topology Server stores metadata (and not tablet data). It is recommended to create a backup using the method described by the underlying plugin:

* [etcd](https://etcd.io/docs/v3.4.0/op-guide/recovery/)
* [ZooKeeper](http://zookeeper.apache.org/doc/r3.6.0/zookeeperAdmin.html#sc_dataFileManagement)
* [Consul](https://www.consul.io/docs/commands/snapshot.html)
