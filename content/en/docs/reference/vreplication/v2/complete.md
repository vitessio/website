---
title: --- Complete
description: Tear down a workflow after switching all traffic
weight: 34
---
##### _Experimental_
This documentation is for a new (v2) set of vtctld commands. See [RFC](https://github.com/vitessio/vitess/issues/7225) for more details.

### Command

```
MoveTables/Reshard [-keep_data] [-rename_tables] [-dry_run]
  Complete <targetKs.workflow>
```

### Description
**Alert: This is a destructive command**

`Complete` is used after all traffic has been switched. It removes vreplication-related artifacts like rows from vreplication and copy_state in the side-car \_vt database, routing rules, and blacklisted tables (for MoveTables) from the topo. Also, by default, the source tables (or source shards) are dropped.

### Parameters

#### -keep_data
**optional**\
**default** false

<div class="cmd">

Usually, the source data (tables or shards) are deleted by Complete. If this flag is used, for MoveTables, source tables will not be deleted, for Reshard, source shards will not be dropped.

</div>

#### -rename_tables
**optional**\
**default** false

<div class="cmd">

The rename_tables flag is applicable only for MoveTables. Tables are renamed instead of being deleted. Currently the new name is _&lt;table_name&gt;_old.

We use the same renaming logic used by `pt-online-schema-change`. Such tables are automatically skipped by vreplication if they exist on the source.

</div>

#### -dry-run
**optional**\
**default** false

<div class="cmd">
You can do a dry run where no actual action is taken but the command logs all the actions that would be taken
by Complete.
</div>
