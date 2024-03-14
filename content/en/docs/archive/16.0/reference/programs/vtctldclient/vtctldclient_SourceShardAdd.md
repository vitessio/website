---
title: SourceShardAdd
series: vtctldclient
commit: a7f80a82e5d99cf00c253c3902367bec5fa40e5d
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
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

