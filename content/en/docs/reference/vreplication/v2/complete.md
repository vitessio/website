---
title: Complete
description: Tear down a workflow after switching all traffic
weight: 80
---
##### _Experimental_
This documentation is for a new (v2) set of vtctld commands. See [RFC](https://github.com/vitessio/vitess/issues/7225) for more details.

### Command

```
MoveTables/Reshard -v2 [-keep_data] [-rename_tables] Complete <targetKs.workflow>
```

### Description

`Complete` is used after all traffic has been switched. It removes vreplication-related artifacts like rows from vreplication and copy_state in the side-car \_vt database, routing rules and blacklisted tables (for MoveTables) from the topo. Also, by default, the target tables (or target shards) are dropped.

### Parameters

#### -keep_data
**optional**\
**default** false

<div class="cmd">
Usually the source data (tables or shards) are deleted by Complete. If this flag is used, for MoveTables, source tables will not be deleted, for Reshard, source shards will not be dropped.

</div>

#### -rename_tables
**optional**\
**default** false

<div class="cmd">
The rename_tables flag is applicable only for MoveTables. Tables are renamed instead of being deleted. Currently the new name is _&lt;table_name&gt;.
<br/><br/>
(We plan to change this to use the logic used by `pt-online-schema-change` using the template _&lt;table_name&gt;_old. The new naming convention has the additional benefit that vreplication will automatically ignore such tables from getting resharded or streamed by the VStream API)

</div>
