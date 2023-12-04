---
title: DeleteTablets
series: vtctldclient
commit: 9a6f5262f7707ff80ce85c111d2ff686d85d29cc
---
## vtctldclient DeleteTablets

Deletes tablet(s) from the topology.

```
vtctldclient DeleteTablets <alias> [ <alias> ... ]
```

### Options

```
  -p, --allow-primary   Allow the primary tablet of a shard to be deleted. Use with caution.
  -h, --help            help for DeleteTablets
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

