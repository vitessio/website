---
title: Migrate create
series: vtctldclient
commit: b0b79813f21f8ecbf409f558ad6f8864332637cf
---
## vtctldclient Migrate create

Create and optionally run a Migrate VReplication workflow.

```
vtctldclient Migrate create
```

### Examples

```
vtctldclient --server localhost:15999 migrate --workflow import --target-keyspace customer create --source-keyspace commerce --mount-name ext1 --tablet-types replica
```

### Options

```
  -a, --all-cells                          Copy table data from any existing cell.
      --all-tables                         Copy all tables from the source.
      --auto-start                         Start the workflow after creating it. (default true)
  -c, --cells strings                      Cells and/or CellAliases to copy table data from.
      --config-overrides strings           Specify one or more VReplication config flags to override as a comma-separated list of key=value pairs.
      --defer-secondary-keys               Defer secondary index creation for a table until after it has been copied.
      --exclude-tables strings             Source tables to exclude from copying.
  -h, --help                               help for create
      --mount-name string                  Name external cluster is mounted as.
      --no-routing-rules                   (Advanced) Do not create routing rules while creating the workflow. See the reference documentation for limitations if you use this flag.
      --on-ddl string                      What to do when DDL is encountered in the VReplication stream. Possible values are IGNORE, STOP, EXEC, and EXEC_IGNORE. (default "IGNORE")
      --source-keyspace string             Keyspace where the tables are being moved from.
      --source-time-zone string            Specifying this causes any DATETIME fields to be converted from the given time zone into UTC.
      --stop-after-copy                    Stop the workflow after it's finished copying the existing rows and before it starts replicating changes.
      --tables strings                     Source tables to copy.
      --tablet-types strings               Source tablet types to replicate table data from (e.g. PRIMARY,REPLICA,RDONLY).
      --tablet-types-in-preference-order   When performing source tablet selection, look for candidates in the type order as they are listed in the tablet-types flag. (default true)
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

* [vtctldclient Migrate](../)	 - Migrate is used to import data from an external cluster into the current cluster.

