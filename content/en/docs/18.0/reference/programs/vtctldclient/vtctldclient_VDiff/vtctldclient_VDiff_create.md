---
title: VDiff create
series: vtctldclient
commit: 9a6f5262f7707ff80ce85c111d2ff686d85d29cc
---
## vtctldclient VDiff create

Create and run a VDiff to compare the tables involved in a VReplication workflow between the source and target.

```
vtctldclient VDiff create
```

### Examples

```
vtctldclient --server localhost:15999 vdiff --workflow commerce2customer --target-keyspace customer create
vtctldclient --server localhost:15999 vdiff --workflow commerce2customer --target-keyspace customer create b3f59678-5241-11ee-be56-0242ac120002
```

### Options

```
      --auto-retry                                Should this vdiff automatically retry and continue in case of recoverable errors. (default true)
      --debug-query                               Adds a mysql query to the report that can be used for further debugging.
      --filtered-replication-wait-time duration   Specifies the maximum time to wait, in seconds, for replication to catch up when syncing tablet streams. (default 30s)
  -h, --help                                      help for create
      --limit uint32                              Max rows to stop comparing after. (default 4294967295)
      --max-extra-rows-to-compare uint32          If there are collation differences between the source and target, you can have rows that are identical but simply returned in a different order from MySQL. We will do a second pass to compare the rows for any actual differences in this case and this flag allows you to control the resources used for this operation. (default 1000)
      --only-pks                                  When reporting missing rows, only show primary keys in the report.
      --source-cells strings                      The source cell(s) to compare from; default is any available cell.
      --tables strings                            Only run vdiff for these tables in the workflow.
      --tablet-types strings                      Tablet types to use on the source and target.
      --tablet-types-in-preference-order          When performing source tablet selection, look for candidates in the type order as they are listed in the tablet-types flag. (default true)
      --target-cells strings                      The target cell(s) to compare with; default is any available cell.
      --update-table-stats                        Update the table statistics, using ANALYZE TABLE, on each table involved in the VDiff during initialization. This will ensure that progress estimates are as accurate as possible -- but it does involve locks and can potentially impact query processing on the target keyspace.
      --wait                                      When creating or resuming a vdiff, wait for it to finish before exiting.
      --wait-update-interval duration             When waiting on a vdiff to finish, check and display the current status this often. (default 1m0s)
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --format string             The format of the output; supported formats are: text,json. (default "text")
      --server string             server to use for the connection (required)
      --target-keyspace string    Target keyspace for this workflow.
  -w, --workflow string           The workflow you want to perform the command on.
```

### SEE ALSO

* [vtctldclient VDiff](../)	 - Perform commands related to diffing tables involved in a VReplication workflow between the source and target.

