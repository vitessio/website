---
title: SetWritable
series: vtctldclient
commit: 3ae5c005a75f782a004e8992be4a4fb95460458e
---
## vtctldclient SetWritable

Sets the specified tablet as writable or read-only.

```
vtctldclient SetWritable <alias> <true/false>
```

### Options

```
  -h, --help   help for SetWritable
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

