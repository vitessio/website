---
title: RebuildKeyspaceGraph
series: vtctldclient
commit: a7f80a82e5d99cf00c253c3902367bec5fa40e5d
---
## vtctldclient RebuildKeyspaceGraph

Rebuilds the serving data for the keyspace(s). This command may trigger an update to all connected clients.

```
vtctldclient RebuildKeyspaceGraph [--cells=c1,c2,...] [--allow-partial] ks1 [ks2 ...]
```

### Options

```
      --allow-partial   Specifies whether a SNAPSHOT keyspace is allowed to serve with an incomplete set of shards. Ignored for all other types of keyspaces.
  -c, --cells strings   Specifies a comma-separated list of cells to update.
  -h, --help            help for RebuildKeyspaceGraph
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

