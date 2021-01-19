---
title: ReverseTraffic
description: Reverse traffic from target to source
weight: 50
---
##### _Experimental_
This documentation is for a new (v2) set of vtctld commands. See [RFC](https://github.com/vitessio/vitess/issues/7225) for more details.

### Command

```
MoveTables/Reshard -v2 [-tablet_types <tablet_types_csv>] [-cells <cells>] ReverseTraffic <targetKs.workflow>
```

### Description

`ReverseTraffic` switches traffic in the reverse direction for the tablet_types specified. The traffic should have been previously switched forward using SwitchTraffic for the cells/tablet_types specified.

### Parameters

#### -cells
**optional**\
**default** all cells

<div class="cmd">
A comma separated list of cell names or cell aliases. Traffic will be reversed only in these cells for the
specified tablet types.

</div>

#### -tablet_types
**optional**\
**default** all (replica,rdonly,master)

<div class="cmd">
A comma separated list of tablet types for which traffic is to be reversed.
One or more from master, replica, rdonly.<br><br>

</div>
