---
title: MoveTables create
series: vtctldclient
commit: 6dba35de0eeeb6e86d22938f644ac8493d348413
---
## vtctldclient MoveTables create

Create and optionally run a MoveTables VReplication workflow.

```
vtctldclient MoveTables create
```

### Examples

```
vtctldclient --server localhost:15999 movetables --workflow commerce2customer --target-keyspace customer create --source-keyspace commerce --cells zone1 --cells zone2 --tablet-types replica
```

### Options

```
  -a, --all-cells                          Copy table data from any existing cell.
      --all-tables                         Copy all tables from the source.
      --atomic-copy                        (EXPERIMENTAL) A single copy phase is run for all tables from the source. Use this, for example, if your source keyspace has tables which use foreign key constraints.
      --auto-start                         Start the workflow after creating it. (default true)
  -c, --cells strings                      Cells and/or CellAliases to copy table data from.
      --defer-secondary-keys               Defer secondary index creation for a table until after it has been copied.
      --exclude-tables strings             Source tables to exclude from copying.
  -h, --help                               help for create
      --no-routing-rules                   (Advanced) Do not create routing rules while creating the workflow. See the reference documentation for limitations if you use this flag.
      --on-ddl string                      What to do when DDL is encountered in the VReplication stream. Possible values are IGNORE, STOP, EXEC, and EXEC_IGNORE. (default "IGNORE")
      --remove-sharded-auto-increment      If moving the table(s) to a sharded keyspace, remove any auto_increment clauses when copying the schema to the target as sharded keyspaces should rely on either user/application generated values or Vitess sequences to ensure uniqueness. (default true)
      --shards strings                     (EXPERIMENTAL: Multi-tenant migrations only) Specify that vreplication streams should only be created on this subset of target shards. Warning: you should first ensure that all rows on the source route to the specified subset of target shards using your VIndex of choice or you could lose data during the migration.
      --source-keyspace string             Keyspace where the tables are being moved from.
      --source-shards strings              Source shards to copy data from when performing a partial MoveTables (experimental).
      --source-time-zone string            Specifying this causes any DATETIME fields to be converted from the given time zone into UTC.
      --stop-after-copy                    Stop the workflow after it's finished copying the existing rows and before it starts replicating changes.
      --tables strings                     Source tables to copy.
      --tablet-types strings               Source tablet types to replicate table data from (e.g. PRIMARY,REPLICA,RDONLY).
      --tablet-types-in-preference-order   When performing source tablet selection, look for candidates in the type order as they are listed in the tablet-types flag. (default true)
      --tenant-id string                   (EXPERIMENTAL: Multi-tenant migrations only) The tenant ID to use for the MoveTables workflow into a multi-tenant keyspace.
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

* [vtctldclient MoveTables](../)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

