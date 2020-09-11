---
title: MoveTables
description: Move one or more tables between keyspaces without downtime
aliases: ['/docs/advanced/movetables','/docs/reference/movetables']
weight: 2
---

<div class="ug-link">

[User Guide](/docs/user-guides/move-tables/)

</div>

### Command

```
MoveTables  [-cells=<cells>] [-tablet_types=<source_tablet_types>] -workflow=<workflow>
                                      <source_keyspace> <target_keyspace> <table_specs>
```

### Description

MoveTables is used to start a workflow move one or more tables from an external database or an existing Vitess keyspace into a new keyspace. The target keyspace can be unsharded or sharded.

MoveTables is used typically for migrating data into Vitess or to implement vertical partitioning. You might use the former when you
first start using Vitess and the latter if you want to distribute your load across servers.

### Parameters

#### -cells 
**optional**\
**default** local cell

<div class="cmd">
A comma separated list of cell names or cell aliases. This list is used by VReplication to determine which
cells should be used to pick a tablet for sourcing data.<br><br>

###### Uses

* Improve performance by using picking a tablet in cells in network proximity with the target
* To reduce bandwidth costs by skipping cells which are in different availability zones
* Select cells where replica lags are lower
</div>

#### -tablet_types
**optional**\
**default** replica

<div class="cmd">
A comma separated list of tablet types that are used while picking a tablet for sourcing data.
One or more from MASTER,REPLICA,RDONLY.<br><br>

###### Uses

* To reduce load on master tablets by using REPLICAs
* Reducing lags by pointing to MASTER
</div>

#### workflow
**mandatory**
<div class="cmd">
Unique name for the MoveTables-initiated workflow, used in later commands to refer back to this workflow
</div>

#### source_keyspace
**mandatory**
<div class="cmd">
Name of existing keyspace that contains the tables to be moved
</div>

#### target_keyspace
**mandatory**
<div class="cmd">
Name of existing keyspace that contains the tables to be moved
</div>

#### table_specs
**mandatory**
<div class="cmd">
One of

* comma separated list of tables (if vschema has been specified for all the tables)
* JSON table section of the vschema for associated tables in case vschema is not yet specified
</div>

### Examples


### A MoveTables Workflow

Once you select the set of tables to move from one keyspace to another you need to initiate a VReplication workflow as follows:

1. Initiate the migration using MoveTables
2. Monitor the workflow using Workflow or VExec
3. Confirm that data has been copied over correctly using VDiff
4. Start the cutover by routing all reads from your application to those tables using SwitchReads
5. Complete the cutover by routing all writes using SwitchWrites
6. Optionally cleanup the source tables using DropSources


### Common use cases for MoveTables

#### Adopting Vitess

#### Horizontal Sharding



