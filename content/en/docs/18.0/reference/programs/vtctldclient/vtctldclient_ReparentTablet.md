---
title: ReparentTablet
series: vtctldclient
commit: fe3121946231107b737e319b680c9686396b9ce1
---
## vtctldclient ReparentTablet

Reparent a tablet to the current primary in the shard.

```
vtctldclient ReparentTablet <alias>
```

### Options

```
  -h, --help   help for ReparentTablet
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

