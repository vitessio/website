---
title: CreateShard
series: vtctldclient
commit: 9a6f5262f7707ff80ce85c111d2ff686d85d29cc
---
## vtctldclient CreateShard

Creates the specified shard in the topology.

```
vtctldclient CreateShard [--force|-f] [--include-parent|-p] <keyspace/shard>
```

### Options

```
  -f, --force            Overwrite an existing shard record, if one exists.
  -h, --help             help for CreateShard
  -p, --include-parent   Creates the parent keyspace record if does not already exist.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

