---
title: Workflow stop
series: vtctldclient
---
## vtctldclient Workflow stop

Stop a VReplication workflow.

```
vtctldclient Workflow stop
```

### Examples

```
vtctldclient --server localhost:15999 workflow --keyspace customer stop --workflow commerce2customer
```

### Options

```
  -h, --help   help for stop
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
  -k, --keyspace string           Keyspace context for the workflow (required)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient Workflow](../)	 - Administer VReplication workflows (Reshard, MoveTables, etc) in the given keyspace.

