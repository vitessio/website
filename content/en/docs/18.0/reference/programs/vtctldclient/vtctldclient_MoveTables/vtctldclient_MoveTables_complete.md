---
title: MoveTables complete
series: vtctldclient
---
## vtctldclient MoveTables complete

Complete a MoveTables VReplication workflow.

```
vtctldclient MoveTables complete
```

### Examples

```
vtctldclient --server localhost:15999 movetables --workflow commerce2customer --target-keyspace customer complete
```

### Options

```
      --dry-run              Print the actions that would be taken and report any known errors that would have occurred
  -h, --help                 help for complete
      --keep-data            Keep the original source table data that was copied by the MoveTables workflow
      --keep-routing-rules   Keep the routing rules in place that direct table traffic from the source keyspace to the target keyspace of the MoveTables workflow
      --rename-tables        Keep the original source table data that was copied by the MoveTables workflow, but rename each table to '_<tablename>_old'
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
      --target-keyspace string    Keyspace where the tables are being moved to and where the workflow exists (required)
```

### SEE ALSO

* [vtctldclient MoveTables](../)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

