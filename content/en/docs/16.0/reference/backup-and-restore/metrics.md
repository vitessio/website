---
title: Metrics
description: Metrics related to backup and restore functionality
weight: 10
---

Backup and restore operations export several metrics using the expvars interface. These are available at the `/debug/vars` endpoint of Vtbackup's and VTTablet's http status pages. [More details can be found here](../../features/monitoring/#3-push-based-metrics-system).

## Backup metrics

#### backup_duration_seconds

_backup_duration_seconds_ times the duration of a backup.

## Restore metrics

#### RestoredBackupTime, RestorePosition

_RestoredBackupTime_ captures the timestamp associated with the backup from which the current process was restored. _RestorePosition_ captures the GTID position associated with that backup.

#### restore_duration_seconds

_restore_duration_seconds_ times the duration of a restore.

## Example
**A snippet of vtbackup metrics after running it against the local example after creating the initial cluster**

(Processed with `jq` for readability.)

```
{
  "RestorePosition": "MySQL56/f00e54ca-0fbf-11ee-ad84-eddb850690bf:1-61",
  "RestoredBackupTime": "2023-06-21T00:39:00Z",
  "backup_duration_seconds": 4,
  "restore_duration_seconds": 6
}
```
