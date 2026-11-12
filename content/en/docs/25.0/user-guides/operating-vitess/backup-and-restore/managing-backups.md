---
title: Managing Backups
weight: 4
aliases: ['/docs/user-guides/backup-and-restore/']
---

**vtctldclient** provides two commands for managing backups:

* [GetBackups](https://vitess.io/docs/reference/programs/vtctldclient/vtctldclient_getbackups/) displays the existing backups for a keyspace/shard in chronological order.

    ``` sh
    vtctldclient --server=<vtctld_host>:<vtctld_port> GetBackups <keyspace/shard>
    ```

* [RemoveBackup](https://vitess.io/docs/reference/programs/vtctldclient/vtctldclient_removebackup/) deletes a specified backup for a keyspace/shard.

    ``` sh
    vtctldclient --server=<vtctld_host>:<vtctld_port> RemoveBackup <keyspace/shard> <backup name>
    ```

You can also confirm your backup finished by viewing the files in your configured `--<engine>-backup-storage-root` location. You will still need to test and verify these backups for completeness. Note that backups are stored by keyspace and shard under `--<engine>-backup-storage-root`. For example, when using `--file-backup-storage-root=/vt/vtdataroot/backups`:

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
  "Hostname": "tablet-zone1-0000000102.example.com",
  "FileName": "backup.xbstream.gz",
  "StreamMode": "xbstream",
  "NumStripes": 0,
  "StripeBlockSize": 102400,
  "SkipCompress": false
}
```

The manifest is stored as plain text next to the backup. It doesn't record `--xtrabackup-backup-flags` or `--mysql-shell-load-flags`, because these flags can hold credentials or encryption keys, such as a `--password` or an `--encrypt-key`.

Backups taken by earlier Vitess versions record these flags in the manifest: `xtrabackup` in the `ExtraCommandLineParams` field and `mysqlshell` in the `Params` field. If those flags held secrets, rotate the secrets. Editing an old manifest doesn't remove copies kept by storage versioning or replication.
