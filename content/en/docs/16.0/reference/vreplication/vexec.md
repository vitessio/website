---
title: VExec
description: Wrapper on VReplicationExec to run query on all participating primary tablets
weight: 60
---

### Command

```
VExec  -- [--dry_run] <keyspace.workflow> <query>
```

### Description

{{< warning >}}
Deprecated in version 12.0.
{{</ warning >}}

VExec is a wrapper over [VReplicationExec](../vreplicationexec).
Given a workflow it executes the provided query on all primary tablets in the target keyspace that participate
in the workflow. Internally it calls `VReplicationExec` for running the query.

### Parameters

#### --dry_run
**optional**\
**default** false

<div class="cmd">
You can do a dry run where no actual action is taken but the command logs the queries and the tablets
 on which the query would be run.
</div>

#### keyspace.workflow
**mandatory**

<div class="cmd">
Name of target keyspace and the associated workflow
</div>

#### query
**mandatory**

<div class="cmd">
SQL query to be run: validations are done to ensure that queries can be run only against vreplication tables.
A limited set of queries are allowed.
</div>

#### Example

```
vtctlclient VExec keyspace1.workflow1 'select * from _vt.vreplication'
```
