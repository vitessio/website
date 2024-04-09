---
title: workflow update
series: vtctldclient
commit: 3ae5c005a75f782a004e8992be4a4fb95460458e
---
## vtctldclient workflow update

Update the configuration parameters for a VReplication workflow

```
vtctldclient workflow update
```

### Examples

```
vtctldclient --server=localhost:15999 workflow --keyspace=customer update --workflow=commerce2customer --cells "zone1" --cells "zone2" -c "zone3,zone4" -c "zone5"
```

### Options

```
  -c, --cells strings          New Cell(s) or CellAlias(es) (comma-separated) to replicate from
  -h, --help                   help for update
      --on-ddl string          New instruction on what to do when DDL is encountered in the VReplication stream. Possible values are IGNORE, STOP, EXEC, and EXEC_IGNORE
  -t, --tablet-types strings   New source tablet types to replicate from (e.g. PRIMARY,REPLICA,RDONLY)
  -w, --workflow string        The workflow you want to update (required)
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
  -k, --keyspace string           Keyspace context for the workflow (required)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient workflow](../)	 - Administer VReplication workflows (Reshard, MoveTables, etc) in the given keyspace

