---
title: ValidateSchemaKeyspace
series: vtctldclient
commit: a7f80a82e5d99cf00c253c3902367bec5fa40e5d
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
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

