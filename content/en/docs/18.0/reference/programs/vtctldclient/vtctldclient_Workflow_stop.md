---
title: Workflow stop
series: vtctldclient
commit: f4d1487c72392cec566ed9ab39a00c7d027cc8ee
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
  -h, --help              help for stop
  -w, --workflow string   The workflow you want to stop.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
  -k, --keyspace string           Keyspace context for the workflow.
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient Workflow](./vtctldclient_workflow/)	 - Administer VReplication workflows (Reshard, MoveTables, etc) in the given keyspace.

