---
title: Workflow Start
series: vtctldclient
---
## vtctldclient Workflow Start

Start a VReplication workflow.

```
vtctldclient Workflow Start
```

### Examples

```
vtctldclient --server localhost:15999 workflow --keyspace customer start --workflow commerce2customer
```

### Options

```
  -h, --help   help for Start
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
  -k, --keyspace string           Keyspace context for the workflow (required)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient Workflow](../)	 - Administer VReplication workflows (Reshard, MoveTables, etc) in the given keyspace.

