---
title: VTOrc
weight: 10
---

`VTOrc` is the automated fault detection and repair tool of Vitess. It started off as a fork of the [Orchestrator](https://github.com/openark/orchestrator), which was then custom-fitted to the Vitess use-case running as a Vitess component. It has reached general availablity with this release of Vitess.

In order to configure `VTOrc`, you have to make the following changes to `vttablet`:

* Add `--disable_active_reparents=true`: This part will prevent vttablet from fixing replication, and will rely on vtorc instead.

This is recommended but not required to run `VTOrc`.

Setting up `VTOrc` lets you avoid performing the `InitShardPrimary` step. It automatically detects that the new shard doesn't have a primary and elects one for you.


### Configuration Refactor and New Flags 

Since `VTOrc` was forked from `Orchestrator`, it inherited a lot of configurations that don't make sense for the Vitess use-case.
All of such configurations have been removed.

For all the configurations that are kept, flags have been added for them and the flags are the desired way to pass these configurations going forward.
The config file will be deprecated and removed in upcoming releases. The following is a list of all the configurations that are kept and the associated flags added.

|          Configurations Kept          |           Flags Introduced            | Flag Usage                                                                                                                             |
|:-------------------------------------:|:-------------------------------------:|----------------------------------------------------------------------------------------------------------------------------------------|
|            SQLite3DataFile            |         `--sqlite-data-file`          | SQLite Datafile to use as VTOrc's database                                                                                             |
|          InstancePollSeconds          |        `--instance-poll-time`         | Timer duration on which VTOrc refreshes MySQL information                                                                              |
|    SnapshotTopologiesIntervalHours    |    `--snapshot-topology-interval`     | Timer duration on which VTOrc takes a snapshot of the current MySQL information it has in the database. Should be in multiple of hours |
|    ReasonableReplicationLagSeconds    |    `--reasonable-replication-lag`     | Maximum replication lag on replicas which is deemed to be acceptable                                                                   |
|             AuditLogFile              |        `--audit-file-location`        | File location where the audit logs are to be stored                                                                                    |
|             AuditToSyslog             |         `--audit-to-backend`          | Whether to store the audit log in the VTOrc database                                                                                   |
|           AuditToBackendDB            |          `--audit-to-syslog`          | Whether to store the audit log in the syslog                                                                                           |
|            AuditPurgeDays             |       `--audit-purge-duration`        | Duration for which audit logs are held before being purged. Should be in multiples of days                                             |
|      RecoveryPeriodBlockSeconds       |  `--recovery-period-block-duration`   | Duration for which a new recovery is blocked on an instance after running a recovery                                                   |
| PreventCrossDataCenterPrimaryFailover |    `--prevent-cross-cell-failover`    | Prevent VTOrc from promoting a primary in a different cell than the current primary in case of a failover                              |
|        LockShardTimeoutSeconds        |        `--lock-shard-timeout`         | Duration for which a shard lock is held when running a recovery                                                                        |
|      WaitReplicasTimeoutSeconds       |       `--wait-replicas-timeout`       | Duration for which to wait for replica's to respond when issuing RPCs                                                                  |
|     TopoInformationRefreshSeconds     | `--topo-information-refresh-duration` | Timer duration on which VTOrc refreshes the keyspace and vttablet records from the topology server                                     |
|          RecoveryPollSeconds          |      `--recovery-poll-duration`       | Timer duration on which VTOrc polls its database to run a recovery                                                                     |

Apart from configurations, some flags from VTOrc have also been removed -
- `sibling`
- `destination`
- `discovery`
- `skip-unresolve`
- `skip-unresolve-check`
- `noop`
- `binlog`
- `statement`
- `grab-election`
- `promotion-rule`
- `skip-continuous-registration`
- `enable-database-update`
- `ignore-raft-setup`
- `tag`


### Old UI Removal and Replacement

The old UI that VTOrc inherited from `Orchestrator` has been removed. A replacement UI, more consistent with the other Vitess binaries has been created.
In order to use the new UI, `--port` flag has to be provided.

Along with the UI, the old APIs have also been deprecated. However, some of them have been ported over to the new UI -

| Old API                          | New API                          | Additional notes                                                                                                                                                                                        |
|----------------------------------|----------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `/api/problems`                  | `/api/problems`                  | This API lists all the instances that have any problems in them. The problems range from replication not running to errant GTIDs. The new API also supports filtering using the keyspace and shard name |
| `/api/disable-global-recoveries` | `/api/disable-global-recoveries` | This API disables the global recoveries in VTOrc. This makes it so that VTOrc doesn't repair any failures it detects.                                                                                   |
| `/api/enable-global-recoveries`  | `/api/enable-global-recoveries`  | This API enables the global recoveries in VTOrc.                                                                                                                                                        |
| `/api/health`                    | `/debug/health`                  | This API outputs the health of the VTOrc process.                                                                                                                                                       |
| `/api/replication-analysis`      | `/api/replication-analysis`      | This API shows the replication analysis of VTOrc. Output is in JSON format.                                                                                                                             |

Apart from these APIs, we also now have `/debug/status`, `/debug/vars` and `/debug/liveness` available in the new UI.

Currently, the `/debug/status` lists the recent recoveries that VTOrc has performed.

![VTOrc-recent-recoveries](../img/VTOrc-Recent-Recoveries.png)

If there is some information about VTOrc that you would like to see
on the `/debug/status` page or support for some API to be added, please let us know in [slack](https://vitess.io/slack) 
in the [#feat-vtorc](https://vitess.slack.com/archives/C02GSRZ8XAN) channel


### Example invocation of VTOrc

You can bring `VTOrc` using the following invocation:

```sh
vtorc --topo_implementation etcd2 \
  --topo_global_server_address "localhost:2379" \
  --topo_global_root /vitess/global \
  --port 15000 \
  --log_dir=${VTDATAROOT}/tmp \
  --recovery-period-block-duration "10m" \
  --instance-poll-time "1s" \
  --topo-information-refresh-duration "30s" \
  --alsologtostderr
 ```

You can optionally add a `clusters_to_watch` flag that contains a comma separated list of keyspaces or `keyspace/shard` values. If specified, `vtorc` will manage only those clusters.


### Durability Policies

All the failovers that `VTOrc` performs will be honoring the [durability policies](../../configuration-basic/durability_policy). Please be careful in setting the
desired durability policies for your keyspace because this will affect what situations VTOrc can recover from and what situations will require manual intervention.


### Example Upgrade From v14

If you are running VTOrc with the flags `--ignore-raft-setup --clusters_to_watch="ks/0" --config="path/to/config"` and the following configuration
```json
{
  "Debug": true,
  "ListenAddress": ":6922",
  "MySQLTopologyUser": "orc_client_user",
  "MySQLTopologyPassword": "orc_client_user_password",
  "MySQLReplicaUser": "vt_repl",
  "MySQLReplicaPassword": "",
  "RecoveryPeriodBlockSeconds": 1,
  "InstancePollSeconds": 1,
  "PreventCrossDataCenterPrimaryFailover": true
}
```
First drop the flag `--ignore-raft-setup` while on the previous release, since it is no longer available in this release. So, you'll be running VTOrc with `--clusters_to_watch="ks/0" --config="path/to/config"` and the same configuration listed above.

Now you can upgrade your VTOrc version continuing to use the same flags and configurations, and it will continue to work just the same. If you wish to use the new UI and APIs, then you can add the `--port` flag as well.

After upgrading, you can drop the configuration entirely and only use the new flags like `--clusters_to_watch="ks/0" --recovery-period-block-duration=1s --instance-poll-time=1s --prevent-cross-cell-failover`. This is the desired state
because the support for the configuration file will be removed in upcoming releases.
