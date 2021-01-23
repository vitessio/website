---
title: Cancel
description: Tear down a workflow where no traffic has been switched
weight: 90
---
##### _Experimental_
This documentation is for a new (v2) set of vtctld commands. See [RFC](https://github.com/vitessio/vitess/issues/7225) for more details.

### Command

```
MoveTables/Reshard -v2 [-keep_data] Cancel <targetKs.workflow>
```

### Description

`Cancel` can be used if a workflow was created in error or was misconfigured and you prefer to create a new workflow instead of fixing this one. Cancel can only be called if no traffic has been switched. It removes vreplication-related artifacts like rows from vreplication and copy_state in the side-car \_vt database, routing rules, and blacklisted tables from the topo and, by default, the target tables/shards from the target keyspace.

### Parameters

#### -keep_data
**optional**\
**default** false

<div class="cmd">

Usually, the target data (tables or shards) are deleted by Cancel. If this flag is used, for MoveTables, target tables will not be deleted and, for Reshard, target shards will not be dropped.

</div>
