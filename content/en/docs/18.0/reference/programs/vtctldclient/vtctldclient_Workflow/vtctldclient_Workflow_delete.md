---
title: Workflow delete
series: vtctldclient
---
## vtctldclient Workflow delete

Delete a VReplication workflow.

```
vtctldclient Workflow delete
```

### Examples

```
vtctldclient --server localhost:15999 workflow --keyspace customer delete --workflow commerce2customer
```

### Options

```
  -h, --help                 help for delete
      --keep-data            Keep the partially copied table data from the workflow in the target keyspace
      --keep-routing-rules   Keep the routing rules created for the workflow
  -w, --workflow string      The workflow you want to update (required)
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
  -k, --keyspace string           Keyspace context for the workflow (required)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient Workflow](../)	 - Administer VReplication workflows (Reshard, MoveTables, etc) in the given keyspace.

