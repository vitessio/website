---
title: --- Progress
description: Show copy progress and replication lag of a workflow
weight: 36
aliases: ['/docs/reference/vreplication/v2/progress/']
---

##### _Experimental_

This documentation is for a new (v2) set of vtctld commands. See [RFC](https://github.com/vitessio/vitess/issues/7225) for more details.

### Command

```
MoveTables/Reshard Progress <targetKs.workflow>
```

### Description
Workflows start in the copy state, (details in [VReplication Life of a stream](../../internals)), doing a bulk copy of the tables involved until they reach a low replication lag, after which we stream binlog events. Tables are copied sequentially.

`Progress` reports the progress of a workflow by showing the percentage of data copied across targets, if workflow is in copy state, and the replication lag between the target and the source once the copy phase is completed.

It is too expensive to get real-time row counts of tables, using _count(*)_, say. So we use the statistics available in the `information_schema` to approximate copy progress. This data can be significantly off (up to 50-60%) depending on the utilization of the underlying mysql server resources. You can manually run `analyze table` to update the statistics if so desired.
