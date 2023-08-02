---
title: MoveTables cancel
series: vtctldclient
---
## vtctldclient MoveTables cancel

Cancel a MoveTables VReplication workflow.

```
vtctldclient MoveTables cancel
```

### Examples

```
vtctldclient --server localhost:15999 movetables --workflow commerce2customer --target-keyspace customer cancel
```

### Options

```
  -h, --help                 help for cancel
      --keep-data            Keep the partially copied table data from the MoveTables workflow in the target keyspace
      --keep-routing-rules   Keep the routing rules created for the MoveTables workflow
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
      --target-keyspace string    Keyspace where the tables are being moved to and where the workflow exists (required)
```

### SEE ALSO

* [vtctldclient MoveTables](../)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

