---
title: GetWorkflows
series: vtctldclient
commit: 9a3628037518bc108c636220319f3c7385b2a559
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

