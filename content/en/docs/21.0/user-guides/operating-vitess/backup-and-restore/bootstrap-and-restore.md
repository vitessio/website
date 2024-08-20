---
title: Bootstrap and Restore
weight: 3
aliases: ['/docs/user-guides/backup-and-restore/']
---

Restores can be done automatically by way of seeding/bootstrapping new tablets, or they can be invoked manually on a tablet to restore a full backup or do a point-in-time recovery.

## Auto restoring a backup on startup

When a tablet starts, Vitess checks the value of the `--restore_from_backup` command-line flag to determine whether to restore a backup to that tablet. Restores will always be done with whichever engine was used to create the backup.

If the flag is absent, Vitess does not try to restore a backup to the tablet. This is the equivalent of starting a new tablet in a new shard. If the flag is present, then the tablet is seeded by a backup, as follows:

 - If `--restore-to-timestamp` or `--restore-to-pos` flags are provided, then this is a [point in time recovery](../overview/#restore-types). The tablet auto selects a good full backup followed by a series of incremental backups, that collectively bring it up to date with requested timestamp or position. The tablet is set to `DRAINED` type, and does not begin replicating.
 - If neither of these flags is present, then the tablet is running a _full_ restore. Vitess tries to restore the most recent backup from the [BackupStorage](../overview/#backup-storage-services) system when starting the tablet. Or, if the `--restore_from_backup_ts` flag is also set then using the latest backup taken at or before this timestamp instead. Example: `"2021-04-29.133050"`

This flag is generally enabled all of the time for all of the tablets in a shard. By default, if Vitess cannot find a backup in the Backup Storage system, the tablet will start up empty. This behavior allows you to bootstrap a new shard before any backups exist.

If the `--wait_for_backup_interval` flag is set to a value greater than zero, the tablet will instead keep checking for a backup to appear at that interval. This can be used to ensure tablets launched concurrently while an initial backup is being seeded for the shard (e.g. uploaded from cold storage or created by another tablet) will wait until the proper time and then pull the new backup when it's ready.

``` sh
vttablet ... --backup_storage_implementation=file \
             --file_backup_storage_root=/nfs/XXX \
             --restore_from_backup
```

## Bootstrapping a new tablet

Bootstrapping a new tablet is almost identical to restoring an existing tablet. The only thing you need to be cautious about is that the tablet specifies its keyspace, shard and tablet type when it registers itself in the topology. Specifically, make sure that the following additional vttablet parameters are set:

``` sh
    --init_keyspace <keyspace>
    --init_shard <shard>
    --init_tablet_type replica|rdonly
```

The bootstrapped tablet will restore the data from the backup and then apply changes, which occurred after the backup, by restarting replication.

## Manual Restore

A manual restore is done on a specific tablet. The tablet's MySQL server is shut down and its data is wiped out.

### Restore a Full Backup

To restore the tablet from the most recent full backup, run:

```shell
vtctldclient --server=<vtctld_host>:<vtctld_port> RestoreFromBackup <tablet-alias>
```

Example:

```shell
vtctldclient --server localhost:15999 --alsologtostderr RestoreFromBackup zone1-0000000101
```

If successful, the tablet's MySQL server rejoins the shard's replication stream, to eventually captch up and be able to serve traffic.

### Restore to a point-in-time

Vitess supports restoring to a _timestamp_ or to a specific _position_. Either way, this restore method assumes backups have been taken that cover the specified position. The restore process will first determine a restore path: a sequence of backups, starting with a full backup followed by zero or more incremental backups, that when combined, include the specified timestamp or position. See more on [Restore Types](../overview/#restore-types) and on [Taking Incremental Backup](../creating-a-backup/#create-an-incremental-backup-with-vtctl).

#### Restore to Timestamp

Starting with `v18`, it is possible to restore to a given timestamp. The restore process will apply all events up to, and excluding, the given timestamp, at 1 second granularity. That is, the restore will bring the database to a point in time which is _about_ 1 second before the specified timestamp. Example:

```shell
vtctldclient RestoreFromBackup --restore-to-timestamp "2023-06-15T09:49:50Z" zone1-0000000100
```

The timestamp must be in `RFC3339` format.

#### Restore to a Position

It is possible to restore onto a precise GTID position. Vitess will restore up to, and including, the exact requested position. This gives you the utmost granularity into the state of the restored database.

```shell
vtctldclient RestoreFromBackup --restore-to-pos <position> <tablet-alias>
```

Example:

```shell
vtctldclient RestoreFromBackup --restore-to-pos "MySQL56/0d7aaca6-1666-11ee-aeaf-0a43f95f28a3:1-60" zone1-0000000102
```

#### Dry Run

It is possible to verify whether a restore-to-timestamp or restore-to-pos is possible without actually performing the restore. Run:


```shell
vtctldclient RestoreFromBackup --dry-run --restore-to-timestamp "2023-06-15T09:49:50Z" zone1-0000000100
```

or
```shell
vtctldclient RestoreFromBackup --dry-run --restore-to-pos "MySQL56/0d7aaca6-1666-11ee-aeaf-0a43f95f28a3:1-60" zone1-0000000102
```

A dry run restore looks at existing backups and sees whether there is a path that restores up to given timestamp or pos, but then quits and does not interrupt any tablet's execution and without changing the tablet's type. If there's no valid path to restore, the process exits with error.