---
title: VTOrc
weight: 8
---

`VTOrc` is the automated fault detection and repair tool of Vitess. It started off as a fork of the [Orchestrator](https://github.com/openark/orchestrator), which was then custom-fitted to the Vitess use-case running as a Vitess component.
An overview of the architecture of `VTOrc` can be found on this [page](../../../reference/vtorc/architecture).

In order to configure `VTOrc`, you have to make the following changes to `vttablet`:

* Add `--disable_active_reparents=true`: This part will prevent vttablet from fixing replication, and will rely on VTOrc instead.

This is recommended but not required to run `VTOrc`.

Setting up `VTOrc` lets you avoid performing the `InitShardPrimary` step. It automatically detects that the new shard doesn't have a primary and elects one for you.


### Flags

For a full list of supported flags, please look at [VTOrc reference page](../../../reference/programs/vtorc).

### UI, API and Metrics

For information about the UI, API and metrics that `VTOrc` exports, please consult this [page](../../../reference/vtorc/ui_api_metrics).

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

You can optionally add a `clusters_to_watch` flag that contains a comma separated list of keyspaces or `keyspace/shard` values. If specified, `VTOrc` will manage only those clusters.


### Durability Policies

All the failovers that `VTOrc` performs will be honoring the [durability policies](../../configuration-basic/durability_policy). Please be careful in setting the
desired durability policies for your keyspace because this will affect what situations VTOrc can recover from and what situations will require manual intervention.
