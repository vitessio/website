---
title: Backup and Restore
weight: 4
---

## How do backups work in vitess?

Backup and Restore are integrated features provided by tablets managed by Vitess. Vitess uses backups for provisioning new tablets in an existing shard.

Vitess supports plugins for a number of Backup Storage Services and Backup Engines. The supported plugins are listed in the [documentation](https://vitess.io/docs/user-guides/operating-vitess/backup-and-restore/overview/#backup-storage-services).

## What is XtraBackup and how does Vitess use it?

Percona XtraBackup is an open source backup utility for MySQL. You can delve into Percona’s [documentation](https://www.percona.com/doc/percona-xtrabackup/2.4/intro.html) on XtraBackup.

XtraBackup can be used as a backup engine in Vitess. Using it requires configuration using [command-line flags](https://vitess.io/docs/user-guides/operating-vitess/backup-and-restore/creating-a-backup/).

## What are my options to restore in vitess?

When a tablet starts, Vitess checks the value of the `--restore_from_backup` command-line flag to determine whether to restore a backup to that tablet.

- If the flag is present, Vitess tries to restore the most recent backup from the Backup Storage system when starting the tablet.
- If the flag is absent, Vitess does not try to restore a backup to the tablet. The MYSQL database associated with the tablet will be empty.

For more information on restoring and managing backups please follow the link [here](https://vitess.io/docs/user-guides/operating-vitess/backup-and-restore/bootstrap-and-restore/#restoring-a-backup).
