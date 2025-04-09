---
title: UI, API and Metrics
---

# UI

In order to use UI, `--port` flag has to be provided.

Currently, the `/debug/status` lists the recent recoveries that VTOrc has performed.

![VTOrc-recent-recoveries](../img/VTOrc-Recent-Recoveries.png)

# APIs

VTOrc supports the following APIs which can be used for monitoring and changing the behaviour of VTOrc.

 | New API                          | Additional notes                                                                                                                                                                                        |
|----------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
 | `/api/problems`                  | This API lists all the instances that have any problems in them. The problems range from replication not running to errant GTIDs. The new API also supports filtering using the keyspace and shard name |
| `/api/disable-global-recoveries` | This API disables the global recoveries in VTOrc. This makes it so that VTOrc doesn't repair any failures it detects.                                                                                   |
 | `/api/enable-global-recoveries`  | This API enables the global recoveries in VTOrc.                                                                                                                                                        |
 | `/debug/health`                  | This API outputs the health of the VTOrc process.                                                                                                                                                       |
 | `/debug/liveness`                | This API outputs the liveness of the VTOrc process.                                                                                                                                                     |
| `/api/replication-analysis`      | This API shows the replication analysis of VTOrc. Output is in JSON format.                                                                                                                             |
| `/api/errant-gtids`              | This API shows the tablets that have errant GTIDs as detected by VTOrc. Output is in JSON format. This API supports filtering by keyspace and shard name.                                               |
| `/api/database-state`            | This API shows the internal database state of VTOrc. This API can be used to debug VTOrc.                                                                                                               |

# Metrics

Metrics are available to be seen on the `/debug/vars` page. VTOrc exports the following metrics:

| Metric                             | Usage                                                                                                                                   |
|------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `PendingRecoveries`                | The number of recoveries in progress which haven't completed.                                                                           |
| `RecoveriesCount`                  | The number of recoveries run. This is further subdivided for all the different recoveries.                                              |
| `SuccessfulRecoveries`             | The number of succesful recoveries run. This is further subdivided for all the different recoveries.                                    |
| `FailedRecoveries`                 | The number of recoveries that failed. This is further subdivided for all the different recoveries.                                      |
| `ErrantGtidTabletCount`            | The number of tablets with errant GTIDs as detected by VTOrc.                                                                           |
| `DetectedProblems`                 | Binary gauge that shows the active problems that VTOrc has detected. This is further subdivided by TabletAlias, Keyspace, and Shard.    |
| `planned_reparent_counts`          | Number of times Planned Reparent Shard has been run. It is further subdivided by the keyspace, shard and the result of the operation.   |
| `emergency_reparent_counts`        | Number of times Emergency Reparent Shard has been run. It is further subdivided by the keyspace, shard and the result of the operation. |
| `reparent_shard_operation_timings` | Timings of reparent shard operations indexed by the type of operation.                                                                  |


{{< info >}}
If there is some information about VTOrc that you would like to see
on the `/debug/status` page or support for some API or metrics to be added, please let us know in [slack](https://vitess.io/slack)
in the [#feat-vtorc](https://vitess.slack.com/archives/C02GSRZ8XAN) channel
{{< /info >}}
