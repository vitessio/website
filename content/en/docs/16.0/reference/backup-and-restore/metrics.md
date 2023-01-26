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

#### restore_duration_seconds

_restore_duration_seconds_ times the duration of a restore.

## Example
**A snippet of vtbackup metrics after running it against the local example after creating the initial cluster**

(Processed with `jq` for readability.)

```
{
  "backup_duration_seconds": 4,
  "restore_duration_seconds": 6
}
```
