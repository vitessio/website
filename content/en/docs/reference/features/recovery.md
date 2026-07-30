---
title: Point In Time Recovery
weight: 17
aliases: ['/docs/recovery/pitr','/docs/reference/pitr/']
---

## Point in Time Recovery

Vitess supports incremental backup and recoveries, AKA point in time recoveries. It supports both restore-to-timestamp and (one second resolution) as well as restore-to-position (precise GTID set).

Point in time recoveries are based on full and incremental backups. It is possible to recover a database to a position that is _covered_ by some backup.

See [Backup Types](../../../user-guides/operating-vitess/backup-and-restore/overview/#backup-types) and [Restore Types](../../../user-guides/operating-vitess/backup-and-restore/overview/#restore-types) for an overview of incremental backups and restores.

See the user guides for how to [Create an Incremental Backup](../../../user-guides/operating-vitess/backup-and-restore/creating-a-backup/#create-an-incremental-backup-with-vtctl) and how to [Restore to a position](../../../user-guides/operating-vitess/backup-and-restore/bootstrap-and-restore/#restore-to-a-point-in-time).

### Supported Databases
- 8.0
