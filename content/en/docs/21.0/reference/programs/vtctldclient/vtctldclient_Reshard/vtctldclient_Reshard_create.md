---
title: Reshard create
series: vtctldclient
commit: 069651aed3c06088dc00f8f699a276665056e3d0
---
## vtctldclient Reshard create

Create and optionally run a Reshard VReplication workflow.

```
vtctldclient Reshard create
```

### Examples

```
vtctldclient --server localhost:15999 reshard --workflow customer2customer --target-keyspace customer create --source-shards="0" --target-shards="-80,80-" --cells zone1 --cells zone2 --tablet-types replica
```

### Options

```
  -a, --all-cells                          Copy table data from any existing cell.
      --auto-start                         Start the workflow after creating it. (default true)
  -c, --cells strings                      Cells and/or CellAliases to copy table data from.
      --defer-secondary-keys               Defer secondary index creation for a table until after it has been copied.
  -h, --help                               help for create
      --on-ddl string                      What to do when DDL is encountered in the VReplication stream. Possible values are IGNORE, STOP, EXEC, and EXEC_IGNORE. (default "IGNORE")
      --skip-schema-copy                   Skip copying the schema from the source shards to the target shards.
      --source-shards strings              Source shards.
      --stop-after-copy                    Stop the workflow after it's finished copying the existing rows and before it starts replicating changes.
      --tablet-types strings               Source tablet types to replicate table data from (e.g. PRIMARY,REPLICA,RDONLY).
      --tablet-types-in-preference-order   When performing source tablet selection, look for candidates in the type order as they are listed in the tablet-types flag. (default true)
      --target-shards strings              Target shards.
```

### Options inherited from parent commands

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --format string                        The format of the output; supported formats are: text,json. (default "text")
      --server string                        server to use for the connection (required)
      --target-keyspace string               Target keyspace for this workflow.
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
  -w, --workflow string                      The workflow you want to perform the command on.
```

### SEE ALSO

* [vtctldclient Reshard](../)	 - Perform commands related to resharding a keyspace.

