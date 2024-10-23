---
title: Backup and Restore
description: Frequently Asked Questions about Vitess
weight: 4
---

## How do backups work in vitess?

Backup and Restore are integrated features provided by tablets managed by Vitess. As well as using backups for data integrity, Vitess will also create and restore backups for provisioning new tablets in an existing shard.

Vitess supports plugins for a number of Backup Storage Services and Backup Engines. The supported plugins are listed [here](https://vitess.io/docs/user-guides/operating-vitess/backup-and-restore/overview/#backup-storage-services).

## What is XtraBackup and how does Vitess use it?

Percona XtraBackup is an open source backup utility for MySQL. You can delve into Percona’s documentation on XtraBackup [here](https://www.percona.com/doc/percona-xtrabackup/2.4/intro.html).

XtraBackup works with Vitess as a plugin that you can make tablets aware of using command-line flags following the instructions [here](https://vitess.io/docs/user-guides/operating-vitess/backup-and-restore/creating-a-backup/).

## What are my options to restore in vitess?

When a tablet starts, Vitess checks the value of the `-restore_from_backup command-line` flag to determine whether to restore a backup to that tablet.

- If the flag is present, Vitess tries to restore the most recent backup from the Backup Storage system when starting the tablet.
- If the flag is absent, Vitess does not try to restore a backup to the tablet. This is the equivalent of starting a new tablet in a new shard.

For more information on restoring and managing backups please follow the link [here](https://vitess.io/docs/user-guides/operating-vitess/backup-and-restore/bootstrap-and-restore/#restoring-a-backup).

## What is the default behavior of connection pooling after a failover?

The expected behavior is that the connection to the old primary will close and that Vitess will try to reconnect to the new primary. 

AWS/Aurora

To ensure that the expected behavior occurs when using AWS/Aurora you will need to set the vttablet flag `-pool_hostname_resolve_interval` to something other than the default. This is because the default is 0. When this flag is set to the default, Vitess will never re-resolve the AWS/Aurora DNS name.