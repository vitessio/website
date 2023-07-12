---
title: Bootstrap and Restore
weight: 3
aliases: ['/docs/user-guides/backup-and-restore/']
---

Restores can be done automatically by way of seeding/bootstrapping new tablets, or they can be invoked manually on a tablet to restore a full backup or do a point-in-time recovery.
## Auto restoring a backup on startup

When a tablet starts, Vitess checks the value of the `--restore_from_backup` command-line flag to determine whether to restore a backup to that tablet. Restores will always be done with whichever engine was used to create the backup.

* If the flag is present, Vitess tries to restore the most recent backup from the [BackupStorage](../overview/#backup-storage-services) system when starting the tablet or if the `--restore_from_backup_ts` flag (Vitess 12.0+) is also set then using the latest backup taken at or before this timestamp instead. Example: '2021-04-29.133050'
* If the flag is absent, Vitess does not try to restore a backup to the tablet. This is the equivalent of starting a new tablet in a new shard.

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

## Manual restore

A manual restore is done on a specific tablet. The tablet's MySQL server is shut down and its data is wiped out.

### Restore a full backup

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

`v17` supports incremental restore, or restoring to a specific _position_:

```shell
vtctlclient -- RestoreFromBackup --restore_to_pos <position> <tablet-alias>
```

Example:

```shell
vtctlclient -- RestoreFromBackup --restore_to_pos "MySQL56/0d7aaca6-1666-11ee-aeaf-0a43f95f28a3:1-60" zone1-0000000102
```

This restore method assumes backups have been taken that cover the specified position. The restore process will first determine a restore path: a sequence of backups, starting with a full backup followed by zero or more incremental backups, that when combined, include the specified position. See more on [Restore Types](../overview/#restore-types) and on [Taking Incremental Backup](../creating-a-backup/#create-an-incremental-backup-with-vtctl).

`v18` will supports restore to a given timestamp.
