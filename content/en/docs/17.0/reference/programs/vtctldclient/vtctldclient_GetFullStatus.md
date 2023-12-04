---
title: GetFullStatus
series: vtctldclient
commit: 9a3d0f4a69a840cfa2cb86654abd4afa0be6e0aa
---
## vtctldclient GetFullStatus

Outputs a JSON structure that contains full status of MySQL including the replication information, semi-sync information, GTID information among others.

```
vtctldclient GetFullStatus <alias>
```

### Options

```
  -h, --help   help for GetFullStatus
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

