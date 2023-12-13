---
title: GetWorkflows
series: vtctldclient
commit: 9a3d0f4a69a840cfa2cb86654abd4afa0be6e0aa
---
## vtctldclient GetWorkflows

Gets all vreplication workflows (Reshard, MoveTables, etc) in the given keyspace.

```
vtctldclient GetWorkflows <keyspace>
```

### Options

```
  -h, --help       help for GetWorkflows
  -a, --show-all   Show all workflows instead of just active workflows.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

