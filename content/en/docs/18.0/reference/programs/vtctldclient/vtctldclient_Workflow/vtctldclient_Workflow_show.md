---
title: Workflow show
series: vtctldclient
---
## vtctldclient Workflow show

Show the details for a VReplication workflow.

```
vtctldclient Workflow show
```

### Examples

```
vtctldclient --server localhost:15999 workflow --keyspace customer show --workflow commerce2customer
```

### Options

```
  -h, --help              help for show
  -w, --workflow string   The workflow you want the details for (required)
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
  -k, --keyspace string           Keyspace context for the workflow (required)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient Workflow](../)	 - Administer VReplication workflows (Reshard, MoveTables, etc) in the given keyspace.

