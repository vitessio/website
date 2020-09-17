---
title: Workflow
description: Wrapper on VExec to perform common actions on a workflow
aliases: ['/docs/vreplication/workflow']
weight: 120
---

### Command

```
Workflow  [-dry_run] <keyspace[.workflow]> <action>
```

### Description

Workflow is a convenience command that some common functions associated with a workflow.  

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


#### action 
**mandatory**

<div class="cmd">
action is one of

* *stop* sets the state of the workflow to Stopped, no further vreplication will happen until restarted
* *start* starts a Stopped workflows
* *delete* removes the entries for this workflow in \_vt.vreplication
* *show* returns a JSON object with details about the associated shards and also with all the columns
    from the \_vt.vreplication table
* *list-all* returns a list of all running workflows in a keyspace
</div>



#### Example
```
vtctlclient  Workflow keyspace1.wf2 stop
vtctlclient  Workflow keyspace1.wf2 show
vtctlclient  Workflow keyspace1 list-all
```
