---
title: Backups and Restores
weight: 12
---

The default settings created by `mysqlctl` set the binlog `expire_logs_days` to 3. Once the binlogs expire, you will not be able to bring up new empty replicas that can catch up to the current state.

So, you need to take regular backups, probably through a cron job. Assuming that you’ve configured the shared storage and provided the correct parameters to the Vitess components, you should be able to create a backup as follows:

```text
vtctldclient Backup cell1-101
```

{{< warning >}}
If you are not using an online backup method like xtrabackup, the `Backup` command will shut down the MySQL instance to perform the operation. The instance will be unavailable until the backup is finished, the restarted MySQL instance is pointed back at the primary and caught up on replication.
{{< /warning >}}

{{< info >}}
It is recommended that you also periodically backup your binlogs. Vitess does not natively support this ability. You will need to set this up yourself.
{{< /info >}}

Once a backup is taken, bringing up a subsequent vttablet-MySQL pair will cause it to restore from the backup instead of starting with a fresh MySQL instance. This will make it catch up from the beginning of time. You should see the following messages in the vttablet logs:

```text
I0102 13:06:01.379759   30842 backup.go:227] Restore: looking for a suitable backup to restore
I0102 13:06:01.379820   30842 shard_sync.go:70] Change to tablet state
I0102 13:06:01.380757   30842 backupengine.go:221] Restore: found backup commerce/0 2021-01-02.205158.cell1-0000000101 to restore
```

If a MySQL with existing data is restarted either manually or due to a failure, an automatic restore will not be performed. Instead, a recovery will be performed from the existing data files.

Please refer to the [Backup and Restore](../../operating-vitess/backup-and-restore) documentation for more information.
