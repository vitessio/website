---
title: VReplicationExec
description: Low level command to run a query on vreplication related tables
weight: 70
---

{{< warning >}}
This command was deprecated in v16.0 and will be removed in a future release.
{{< /warning >}}

### Command

```
VReplicationExec -- [--json] <tablet_alias> <query>
```

### Description

The `VReplicationExec` command is used to view or manage vreplication streams. You would typically use one of the higher-level commands like the [WorkFlow](../workflow) command accomplish the same task.

### Parameters

#### --json
**optional**

<div class="cmd">
The output of the command is json formatted: to be readable by scripts.
</div>

#### tablet_alias
**mandatory**

<div class="cmd">
Id of the target tablet on which to run the sql query, specified using the vitess tablet id format
&lt;cell&gt;-&lt;uid&gt; (see example below).
</div>

#### query
**mandatory**

<div class="cmd">
SQL query which will be run: validations are done to ensure that queries can be run only against vreplication tables.
A limited set of queries are allowed.
</div>

#### Example
```
vtctlclient VReplicationExec 'zone1-100' 'select * from _vt.vreplication'
```
