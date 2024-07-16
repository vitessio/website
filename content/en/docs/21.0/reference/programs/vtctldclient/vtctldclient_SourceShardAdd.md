---
title: SourceShardAdd
series: vtctldclient
commit: cd0c2b594b2d5178a9c8ac081eaee7d1b7eef28a
---
## vtctldclient SourceShardAdd

Adds the SourceShard record with the provided index for emergencies only. It does not call RefreshState for the shard primary.

```
vtctldclient SourceShardAdd [--key-range <keyrange>] [--tables <table1,table2,...> [--tables <table3,...>]...] <keyspace/shard> <uid> <source keyspace/shard>
```

### Options

```
  -h, --help               help for SourceShardAdd
      --key-range string   Key range to use for the SourceShard.
      --tables strings     Comma-separated lists of tables to replicate (for MoveTables). Each table name is either an exact match, or a regular expression of the form "/regexp/".
```

### Options inherited from parent commands

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

