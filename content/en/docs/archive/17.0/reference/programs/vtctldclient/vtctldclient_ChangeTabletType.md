---
title: ChangeTabletType
series: vtctldclient
commit: 3ae5c005a75f782a004e8992be4a4fb95460458e
---
## vtctldclient ChangeTabletType

Changes the db type for the specified tablet, if possible.

### Synopsis

Changes the db type for the specified tablet, if possible.

This command is used primarily to arrange replicas, and it will not convert a primary.
NOTE: This command automatically updates the serving graph.

```
vtctldclient ChangeTabletType [--dry-run] <alias> <tablet-type>
```

### Options

```
  -d, --dry-run   Shows the proposed change without actually executing it.
  -h, --help      help for ChangeTabletType
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

