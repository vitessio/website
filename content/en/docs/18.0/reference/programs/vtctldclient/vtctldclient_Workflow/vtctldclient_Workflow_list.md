---
title: Workflow list
series: vtctldclient
commit: fe3121946231107b737e319b680c9686396b9ce1
---
## vtctldclient Workflow list

List the VReplication workflows in the given keyspace.

```
vtctldclient Workflow list
```

### Examples

```
vtctldclient --server localhost:15999 workflow --keyspace customer list
```

### Options

```
  -h, --help   help for list
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
  -k, --keyspace string           Keyspace context for the workflow.
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient Workflow](../)	 - Administer VReplication workflows (Reshard, MoveTables, etc) in the given keyspace.

