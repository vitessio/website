---
title: GetSrvKeyspaceNames
series: vtctldclient
commit: 314ebcf13923f98945595208d5099eca4a7184ea
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
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

