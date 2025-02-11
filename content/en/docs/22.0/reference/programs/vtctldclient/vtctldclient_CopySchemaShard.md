---
title: CopySchemaShard
series: vtctldclient
---
## vtctldclient CopySchemaShard

Copies the schema from a source shard's primary (or a specific tablet) to a destination shard. The schema is applied directly on the primary of the destination shard, and it is propagated to the replicas through binlogs.

```
vtctldclient CopySchemaShard [--tables=<table1>,<table2>,...] [--exclude-tables=<table1>,<table2>,...] [--include-views] [--skip-verify] [--wait-replicas-timeout=10s] {<source keyspace/shard> || <source tablet alias>} <destination keyspace/shard>
```

### Options

```
      --exclude-tables strings           Specifies a comma-separated list of tables to exclude. Each is either an exact match, or a regular expression of the form /regexp/
  -h, --help                             help for CopySchemaShard
      --include-views                    Includes views in the output (default true)
      --skip-verify                      Skip verification of source and target schema after copy
      --tables strings                   Specifies a comma-separated list of tables to copy. Each is either an exact match, or a regular expression of the form /regexp/
      --wait-replicas-timeout duration   The amount of time to wait for replicas to receive the schema change via replication. (default 10s)
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

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server or alternatively as a standalone binary using --server=internal.

