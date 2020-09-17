---
title: VExec
description: Wrapper on VReplicationExec to run query on all participating masters
aliases: ['/docs/vreplication/vexec']
weight: 110
---

### Command

```
VExec  [-dry_run] <keyspace.workflow> <query>
```

### Description


VExec is a wrapper over [VReplicationExec](../vreplicationexec).
Given a workflow it executes the provided query on all masters in the target keyspace that participate
in the workflow. Internally it calls VReplicationExec for running the query.

### Parameters

#### -dry-run 
**optional**\
**default** false

<div class="cmd">
You can do a dry run where no actual action is taken but the command logs all the actions that would be taken
by SwitchReads.
</div>

#### keyspace.workflow 
**mandatory**

<div class="cmd">
Name of target keyspace and the associated workflow to SwitchWrites for.
</div>


#### sql query 
**mandatory**

<div class="cmd">
Sql query which will be run: validations are done to ensure that queries can be run only against vreplication tables.
A limited set of queries are allowed. 
</div>



#### Example
```
vtctlclient  VExec keyspace1.wf2 'select * from _vt.vreplication'
```
