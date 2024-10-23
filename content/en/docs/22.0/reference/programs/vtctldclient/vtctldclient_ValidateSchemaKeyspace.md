---
title: ValidateSchemaKeyspace
series: vtctldclient
commit: b0b79813f21f8ecbf409f558ad6f8864332637cf
---
## vtctldclient ValidateSchemaKeyspace

Validates that the schema on the primary tablet for shard 0 matches the schema on all other tablets in the keyspace.

```
vtctldclient ValidateSchemaKeyspace [--exclude-tables=<exclude_tables>] [--include-views] [--skip-no-primary] [--include-vschema] <keyspace>
```

### Options

```
      --exclude-tables strings   Tables to exclude during schema comparison.
  -h, --help                     help for ValidateSchemaKeyspace
      --include-views            Includes views in compared schemas.
      --include-vschema          Includes VSchema validation in validation results.
      --skip-no-primary          Skips validation on whether or not a primary exists in shards.
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

