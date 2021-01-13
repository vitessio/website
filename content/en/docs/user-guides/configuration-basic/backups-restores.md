---
title: Backups and Restores
weight: 12
---

The default settings created by `mysqlctl` set the binlog `expire_log_days` to 3. Once the binlogs expire, you will not be able to bring up new empty replicas that can catch up to the current state.

So, you need to take regular backups, probably through a cron job. Assuming that you’ve configured the shared storage and provided the correct parameters to the vitess components, you should be able to create a backup as follows:

```text
vtctlclient Backup zone1-101
```

Once a backup is taken, bringing up a subsequent vttablet+mysql pair will cause it to restore from the backup instead of starting with a fresh mysql instance and making it catch up from the beginning of time. You should see the following messages in the vttablet logs:

```text
I0102 13:06:01.379759   30842 backup.go:227] Restore: looking for a suitable backup to restore
I0102 13:06:01.379820   30842 shard_sync.go:70] Change to tablet state
I0102 13:06:01.380757   30842 backupengine.go:221] Restore: found backup commerce/0 2021-01-02.205158.zone1-0000000101 to restore
```

If a mysql with existing data is restarted either manually or due to a failure, an automatic restore will not be performed. Instead, a recovery will be performed from the existing data files.

Please refer to the [Backup and Restore](../../operating-vitess/backup-and-restore) documentation for more information.
