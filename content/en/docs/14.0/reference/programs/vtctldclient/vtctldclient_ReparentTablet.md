---
title: ReparentTablet
series: vtctldclient
description:
---
## vtctldclient ReparentTablet



### Synopsis

Reparent a tablet to the current primary in the shard. This only works if the current replica position matches the last known reparent action.

```
vtctldclient ReparentTablet <alias> [flags]
```

### Options

```
  -h, --help   help for ReparentTablet
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

