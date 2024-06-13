---
title: Validating schema migrations using `VDiff`
weight: 15
aliases: [ '/docs/user-guides/schema-changes/validating-migrations/' ]
---

`VDiff` (https://vitess.io/docs/reference/vreplication/vdiff/) is a Vitess tool that performs a row by row comparison of all tables associated with a VReplication workflow.
Vitess-managed schema migrations (aka `Online DDL`) use VReplication workflows to perform the transformation from the 
existing schema to the desired schema. Since the Online DDL is also a VReplication workflow, we 
can use `VDiff` to validate that the transformed table and original table are in sync.

`VDiff`s can only be run on schema migrations created with the `--postpone-completion` flag. You should run `VDiff` 
once your schema migration has its `ready_to_complete` set to `1`.

Here is an example of how you can run a `VDiff` on a schema migration:

1. Start the migration: we are altering table `t1` in the `customer` keyspace.

```
$ vtctldclient ApplySchema --ddl-strategy vitess --postpone-completion --sql "alter table t1 add column extra1 int not null 
default 0" customer
a2994c92_f1d4_11ea_afa3_f875a4d24e90
```

2. Use the `Show` command to confirm that `ready_to_complete` is 1.

```
mysql> show vitess_migrations like 'a2994c92_f1d4_11ea_afa3_f875a4d24e90' \G
*************************** 1. row ***************************
                             id: 1
                 migration_uuid: a2994c92_f1d4_11ea_afa3_f875a4d24e90
                       keyspace: customer
                       ....
                       ....
              ready_to_complete: 1

```

3. Run the VDiff command. The name of the VReplication workflow is the same as Online DDL's `uuid`.
```
vtctldclient VDiff --target-keyspace customer --workflow a2994c92_f1d4_11ea_afa3_f875a4d24e90 Create

VDiff a35b0006-e6d9-416e-bea9-917795dc5bf3 scheduled on target shards, use show to view progress
```

4. Monitor VDiff progress/status. 
```
vtctldclient VDiff --target-keyspace customer --workflow Show a2994c92_f1d4_11ea_afa3_f875a4d24e90

VDiff Summary for customer.commerce2customer (a2994c92_f1d4_11ea_afa3_f875a4d24e90)
State:        completed
RowsCompared: 196872
HasMismatch:  false
StartedAt:    2024-03-26 22:44:29
CompletedAt:  2024-03-26 22:54:31

Use "--format=json" for more detailed output.
```
You should see `HasMismatch: false` unless there is a bug in Vitess, in which case please post on Vitess Slack and/or 
create an issue at `https://github.com/vitessio/vitess/issues`

## References
* [Online DDL usage](https://vitess.io/docs/user-guides/schema-changes/audit-and-control/)
* [VDiff](https://vitess.io/docs/reference/vreplication/vdiff/)
