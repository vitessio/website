---
title: GetSrvKeyspaceNames
series: vtctldclient
commit: a7f80a82e5d99cf00c253c3902367bec5fa40e5d
---
## vtctldclient GetSrvKeyspaceNames

Outputs a JSON mapping of cell=>keyspace names served in that cell. Omit to query all cells.

```
vtctldclient GetSrvKeyspaceNames [<cell> ...]
```

### Options

```
  -h, --help   help for GetSrvKeyspaceNames
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

