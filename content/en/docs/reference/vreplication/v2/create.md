---
title: Create
description: Initiate a workflow
weight: 30
---
##### _Experimental_
This documentation is for a new (v2) set of vtctld commands. See [RFC](https://github.com/vitessio/vitess/issues/7225) for more details.

### Command

```
MoveTables -v2 [-source=<sourceKs>] [-tables=<tableSpecs>] [-cells=<cells>]
  [-tablet_types=<source_tablet_types>] [-all] [-exclude=<tables>]
  Create <targetKs.workflow>

Reshard -v2 [-source_shards=<source_shards>] [-target_shards=<target_shards>]
  [-cells=<cells>] [-tablet_types=<source_tablet_types>]  [-skip_schema_copy]
  Create <keyspace.workflow>

```

### Description

`MoveTables/Reshard Create` sets up and creates a new workflow. The workflow name should not conflict with that of an existing workflow.

### Parameters

#### -source
**mandatory**

**MoveTables only**
<div class="cmd">
Name of existing keyspace (the source keyspace) that contains the tables to be moved.
</div>

#### table_specs
**optional**  one of `table_specs` or `-all` needs to be specified

**MoveTables only**
<div class="cmd">
_Either_

* a comma-separated list of tables
  * if target keyspace is unsharded OR
  * if target keyspace is sharded AND the tables being moved are already defined in the target's vschema

  Example: `MoveTables -source=commerce -tables=customer,corder Create customer.commerce2customer`

_Or_

* the JSON table section of the vschema for associated tables
  * if target keyspace is sharded AND
  * tables being moved are not yet present in the target's vschema

  Example: `MoveTables -source=commerce -tables='{"t1":{"column_vindexes": [{"column": "id", "name": "hash"}]}}}' Create customer.commerce2customer`

</div>

#### -cells
**optional**\
**default** local cell

<div class="cmd">
A comma-separated list of cell names or cell aliases. This list is used by VReplication to determine which
cells should be used to pick a tablet for selecting data from the source keyspace.<br><br>

###### Uses

* Improve performance by picking a tablet in cells in network proximity with the target
* To reduce bandwidth costs by skipping cells that are in different availability zones
* Select cells where replica lags are lower
</div>

#### -tablet_types
**optional**\
**default** replica

<div class="cmd">
A comma-separated list of tablet types that are used while picking a tablet for sourcing data.
One or more from MASTER, REPLICA, RDONLY.<br><br>

###### Uses

* To reduce the load on master tablets by using REPLICAs or RDONLYs
* Reducing lags by pointing to MASTER
</div>


#### -all
**optional** cannot specify `table_specs` if `-all` is specified

**MoveTables only**
<div class="cmd">

Move all tables from the source keyspace.

</div>

#### -exclude
**optional** only applies if `-all` is specified

**MoveTables only**
<div class="cmd">

If moving all tables, specifies tables to be skipped.

</div>


#### source_shards
**mandatory**

**Reshard only**

<div class="cmd">
Comma-separated shard names to reshard from.

Example: `Reshard -source_shards=0 -target_shards=-80,80- Create customer.reshard1to2`

</div>

#### target_shards
**mandatory**

**Reshard only**

<div class="cmd">
Comma-separated shard names to reshard to.
</div>

#### -skip_schema_copy
**optional**\
**default** false

**Reshard only**

<div class="cmd">
If true the source schema is copied to the target shards. If false, you need to create the tables
before calling reshard.
</div>
