---
title: workflow
series: vtctldclient
commit: 9a3628037518bc108c636220319f3c7385b2a559
---
## vtctldclient workflow

Administer VReplication workflows (Reshard, MoveTables, etc) in the given keyspace

```
vtctldclient workflow
```

### Options

```
  -h, --help              help for workflow
  -k, --keyspace string   Keyspace context for the workflow (required)
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.
* [vtctldclient workflow update](./vtctldclient_workflow_update/)	 - Update the configuration parameters for a VReplication workflow

