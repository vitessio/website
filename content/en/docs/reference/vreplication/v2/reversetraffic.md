---
title: --- ReverseTraffic
description: Reverse traffic from target to source
weight: 33
---
##### _Experimental_
This documentation is for a new (v2) set of vtctld commands. See [RFC](https://github.com/vitessio/vitess/issues/7225) for more details.

### Command

```
MoveTables/Reshard [-tablet_types <tablet_types_csv>] [-cells <cells>]
  [-timeout=timeoutDuration] [-dry_run]
  ReverseTraffic <targetKs.workflow>
```

### Description

`ReverseTraffic` switches traffic in the reverse direction for the tablet_types specified. The traffic should have been previously switched forward using SwitchTraffic for the cells/tablet_types specified.

### Parameters

#### -cells
**optional**\
**default** all cells

<div class="cmd">

A comma-separated list of cell names or cell aliases. Traffic will be reversed only in these cells for the
specified tablet types.

</div>

#### -tablet_types
**optional**\
**default** all (replica,rdonly,primary)

<div class="cmd">

A comma-separated list of tablet types for which traffic is to be reversed.
One or more from primary, replica, rdonly.<br><br>

</div>

#### -timeout
**optional**\
**default** 30s

<div class="cmd">

For primary tablets, ReverseTraffic first stops writes on the target primary and waits for the replication to the source to
catchup with the point where the writes were stopped. If the wait time is longer than timeout
the command will error out. For setups with high write qps you may need to increase this value.

</div>

#### -dry-run
**optional**\
**default** false

<div class="cmd">
You can do a dry run where no actual action is taken but the command logs all the actions that would be taken
by ReverseTraffic.
</div>
