---
title: Bootstrap and Restore
weight: 3
aliases: ['/docs/user-guides/backup-and-restore/']
---

## Restoring a backup

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
