---
title: Workflow
description: Wrapper on VReplication to perform common actions on a workflow
weight: 50
---

### Command

```
Workflow -- [--dry-run] [--cells=<cells>] [--tablet-types=<types>] [--on-ddl=<value>] <keyspace>[.<workflow>] <action>

```

### Description

Workflow is a convenience command for useful actions on a workflow that you can use instead of
actually specifying a query to VReplication.

### Parameters

#### --dry-run
**optional**\
**default** false

<div class="cmd">
You can do a dry run where no actual action is taken but the command logs all the actions that would be taken by the Workflow.
</div>

#### --cells
**optional** (Update action only)\
**default** false

<div class="cmd">
You can update an existing workflow so that a different set of cells and/or cell aliases are used when choosing replication sources.
</div>

#### --tablet-types
**optional** (Update action only)\

<div class="cmd">
You can update an existing workflow so that different types of tablets are selected when choosing replication sources (see [tablet selection](../tablet_selection/)).
</div>

#### --on-ddl
**optional** (Update action only)\

<div class="cmd">
You can update an existing workflow so that DDL in the replication stream are handled differently (see [tablet selection](../vreplication/#handle-ddl)).
</div>

#### keyspace.workflow
**mandatory**

<div class="cmd">
Name of target keyspace and the associated workflow to take action on.
{{< info >}}
The `listall` action is an exception to this rule as with that action you only specify the keyspace.
{{< /info >}}
</div>

#### action
**mandatory**

<div class="cmd">
The Action is one of:

* **stop**: sets the state of the workflow to Stopped: no further vreplication will happen until workflow is restarted
* **start**: restarts a Stopped workflow
* **update**: updates configuration parameters for this workflow in the `_vt.vreplication` table
* **delete**: removes the entries for this workflow in the `_vt.vreplication` table
* **show**: returns a JSON object with details about the associated shards and also with all the columns
    from the `_vt.vreplication` table
* **listall**: returns a comma separated list of all *running* workflows in a keyspace
* **tags**: a comma-separated list of key:value pairs that are used to tag the workflow
</div>

#### Example
```
vtctlclient  Workflow keyspace1.workflow1 stop
vtctlclient  Workflow keyspace1.workflow1 show
vtctlclient  Workflow keyspace1 listall
```
