---
title: GetFullStatus
series: vtctldclient
commit: a7f80a82e5d99cf00c253c3902367bec5fa40e5d
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

