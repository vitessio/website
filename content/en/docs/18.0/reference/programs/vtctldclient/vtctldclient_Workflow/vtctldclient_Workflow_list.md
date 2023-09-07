---
title: Workflow List
series: vtctldclient
---
## vtctldclient Workflow List

List the VReplication workflows in the given keyspace.

```
vtctldclient Workflow List
```

### Examples

```
vtctldclient --server localhost:15999 workflow --keyspace customer list
```

### Options

```
  -h, --help   help for List
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
  -k, --keyspace string           Keyspace context for the workflow (required)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient Workflow](../)	 - Administer VReplication workflows (Reshard, MoveTables, etc) in the given keyspace.

