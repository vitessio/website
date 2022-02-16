---
title: --- SwitchTraffic
description: Switch traffic from source to target
weight: 32
aliases: ['/docs/reference/vreplication/v2/switchtraffic/']
---

{{< info >}}
This documentation is for a new (v2) set of vtctld commands that start in Vitess 11.0. See [RFC](https://github.com/vitessio/vitess/issues/7225) for more details.
{{< /info >}}

### Command

```
MoveTables/Reshard [-tablet_types=<tablet_types>] [-cells=<cells>]
  [-timeout=timeoutDuration] [-reverse_replication] [-dry_run]
  SwitchTraffic <targetKs.workflow>
```

### Description

`SwitchTraffic` switches traffic forward for the tablet_types specified. This replaces the previous SwitchReads and SwitchWrites commands with a single one. It is now possible to switch all traffic with just one command. Also, you can now switch replica, rdonly and primary traffic in any order: earlier you needed to first SwitchReads (for replicas and rdonly tablets) first before SwitchWrites.

### Parameters

#### -cells
**optional**\
**default** all cells

<div class="cmd">

A comma-separated list of cell names or cell aliases. Traffic will be switched only in these cells for the
specified tablet types.

</div>

#### -tablet_types
**optional**\
**default** all (replica,rdonly,primary)

<div class="cmd">

A comma-separated list of tablet types for which traffic is to be switched.
One or more from primary,replica,rdonly.<br><br>

</div>

#### -timeout
**optional**\
**default** 30s

<div class="cmd">

For primary tablets, SwitchTraffic first stops writes on the source primary and waits for the replication to the target to
catchup with the point where the writes were stopped. If the wait time is longer than timeout
the command will error out. For setups with high write qps you may need to increase this value.

</div>

#### -reverse_replication
**optional**\
**default** true

<div class="cmd">

SwitchTraffic for primary tablet types, by default, starts a reverse replication stream with the current target as the source, replicating back to the original source. This enables a quick and simple rollback using ReverseTraffic. This reverse workflow name is that of the original workflow concatenated with \_reverse.

If set to false these reverse replication streams will not be created and you will not be able to rollback once you have switched write traffic over to the target.

</div>

#### -max_transaction_lag_allowed
**optional**\
**default**  the value used for `-timeout`

<div class="cmd">

While switching traffic ensure that the VReplication lag for the workflow is less than this duration, otherwise
report an error and don't switch. VReplication lag is the estimated maximum lag across workflow streams between the last event seen at the source and the event processed by the target. Usually, when VReplication has caught up, this should be very small (under a second).

While switching write traffic, we temporarily make the source databases read-only, and wait for the targets to catchup. The application will be down for this time: writes will error out. While switching write traffic, this flag can ensure that you only switch traffic if the current lag is small limiting downtime.

This can also be useful if only reads are being switched: if the lag is too high the app might be reading stale data.

</div>

#### -dry-run
**optional**\
**default** false

<div class="cmd">
You can do a dry run where no actual action is taken but the command logs all the actions that would be taken
by SwitchTraffic.
</div>
