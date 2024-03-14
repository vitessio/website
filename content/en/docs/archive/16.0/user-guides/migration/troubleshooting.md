---
title: Troubleshooting
weight: 4
---

## Overview

Here we will cover some common issues seen during a migration — how to avoid them, how to detect them, and how to address them.

{{< info >}}
This guide follows on from the [Get Started](../../../get-started/) guides. Please make sure that you have a
[Kubernetes Operator](../../../get-started/operator) or [local](../../../get-started/local) installation ready.
Make sure you have run the "101" and "201" steps of the examples, for example the "101" step is
`101_initial_cluster.sh` in the [local](../../../get-started/local) example. The commands in this guide also assume
you have setup the shell aliases from the example, e.g. `env.sh` in the [local](../../../get-started/local) example.
{{< /info >}}


## General and Precautionary Info

### Execute a Dry Run

The `SwitchTraffic`/`ReverseTraffic` and `Complete` actions support a dry run using the `--dry_run` flag where no
actual steps are taken but instead the command logs all the steps that *would* be taken. This command will also
verify that the cluster is generally in a state where it can perform the action successfully without potentially
timing out along the way. Given that traffic cutovers can potentially cause read/write pauses or outages this can
be particularly helpful during the final cutover stage.

### DDL Handling

If you expect DDL to be executed on the source table(s) while the workflow runs and you want those DDL statements
to be replicated to the target keyspace then you will need to use one of the `EXEC*` options for the workflow's
[`on-ddl`](../../../reference/vreplication/vreplication/#handle-ddl) flag. Please see the
[`on-ddl` flag documentation](../../../reference/vreplication/vreplication/#handle-ddl) for additional details and
related considerations.

## Running a Diff

In most cases you should run a [`VDiff`](../../../reference/vreplication/vdiff/) before switching traffic to ensure
that nothing unexpected happened which caused the data to diverge during the migration.

## Performance Notes

- VReplication workflows (including [`VDiff`](../../../reference/vreplication/vdiff/)) can have a major impact on the
tablet so it's recommended to use non-PRIMARY tablets whenever possible to limit any impact on production traffic
    - You can see the key related tablet flags and when/why you may want to set them in the [VReplication tablet flag docs](../../../reference/vreplication/flags/)
    - You can further control any impact on the source and target tablets using [the tablet throttler](../../../reference/features/tablet-throttler/)
- VReplication workflows can generate a lot of network traffic
    - You should strive to keep the source and target tablets in the same [cell](../../../concepts/cell) whenever possible to limit performance and cost impacts

## Monitoring

It's important to properly monitor your VReplication workflows in order to detect any issues. Your primary tools for this are:
  - The [`Workflow show`](../../../reference/vreplication/workflow/) command
  - The `Progress`/`Show` action (e.g. [`MoveTables -- Progress`](../../../reference/vreplication/movetables/#progress))
  - The [VReplication related metrics](../../../reference/vreplication/metrics/)
    - Note that in most production systems the tablet endpoints would be scraped and stored in something like [Prometheus](https://prometheus.io) where you can build dashboards and alerting on the data

### Save Routing Rules

The `Create`, `SwitchTraffic`/`ReverseTraffic`, and `Cancel`/`Complete` actions modify the
[routing rules](../../../reference/features/schema-routing-rules/). You may want to save the routing rules before
taking an action just in case you want to restore them for any reason (note that e.g. the `ReverseTraffic` action
will automatically revert the routing rules):
```bash
$ vtctldclient GetRoutingRules > /tmp/routingrules.backup.json
```

Those can later be applied this way:
```bash
$ vtctldclient ApplyRoutingRules --rules-file=/tmp/routingrules.backup.json
```


## Specific Errors and Issues

### Stream Never Starts

This can be exhibited in one of two ways:
1. This error is shown in the `Progress`/`Show` action output or the `Workflow show` output: `Error picking tablet: context has expired`
2. The stream never starts, which can be seen in the following ways:
    1. The `Workflow show` output is showing an empty value in the `Pos` field for the stream
    2. The `Progress`/`Show` action output is showing `VStream has not started` for the stream

When a VReplication workflow starts or restarts the [tablet selection process](../../../reference/vreplication/tablet_selection/)
runs to find a viable source tablet for the stream. The `cells` and `tablet_types` play a key role in this process and
if we cannot ever find a viable source tablet for the stream then you may want to expand the cells and/or tablet types
made available for the selection process.

#### Corrective Action

If the workflow was only created and has not yet made any progress then you should `Cancel` the workflow and `Create` a new
one using different values for the `--cells` and `--tablet_types` flags. If, however, this workflow has made significant
progress that you do not wish you lose, you can update the underlying workflow record directly to modify either of those
values. For example:
```bash
$ vtctlclient MoveTables -- Progress customer.commerce2customer

The following vreplication streams exist for workflow customer.commerce2customer:

id=1 on 0/zone1-0000000200: Status: Running. VStream has not started.


$ for tablet in $(vtctlclient ListAllTablets -- --keyspace=customer --tablet_type=primary | awk '{print $1}'); do
    vtctlclient VReplicationExec -- ${tablet} 'update _vt.vreplication set tablet_types="replica,primary" where workflow="commerce2customer"'
  done


$ vtctlclient MoveTables -- Progress customer.commerce2customer

The following vreplication streams exist for workflow customer.commerce2customer:

id=1 on 0/zone1-0000000201: Status: Running. VStream Lag: 0s.
```

### Workflow Has SQL Errors

We can encounter persistent SQL errors when applying replicated events on the target for a variety of reasons, but
the most common cause is incompatible DDL having been executed against the source table while the workflow is running. 
You would see this error in the `Show`/`Progress` or `Workflow show` output. For example:
```bash
$ vtctlclient MoveTables -- Progress customer.commerce2customer

The following vreplication streams exist for workflow customer.commerce2customer:

id=1 on 0/zone1-0000000201: Status: Error: Unknown column 'notes' in 'field list' (errno 1054) (sqlstate 42S22) during query: insert into customer(customer_id,email,notes) values (100,'test@tester.com','Lots of notes').

# OR a variant

$ vtctlclient MoveTables -- Progress customer.commerce2customer

The following vreplication streams exist for workflow customer.commerce2customer:

id=1 on 0/zone1-0000000201: Status: Error: vttablet: rpc error: code = Unknown desc = stream (at source tablet) error @ a2d90338-916d-11ed-820a-498bdfbb0b03:1-90: cannot determine table columns for customer: event has [8 15 15], schema has [name:"customer_id" type:INT64 table:"customer" org_table:"customer" database:"vt_commerce" org_name:"customer_id" column_length:20 charset:63 flags:49667 name:"email" type:VARBINARY table:"customer" org_table:"customer" database:"vt_commerce" org_name:"email" column_length:128 charset:63 flags:128].
```

This can be caused by a DDL executed on the source table as by default — controlled by the
[`on-ddl` flag value](../../../reference/vreplication/vreplication/#handle-ddl) — DDL is ignored in the stream.

#### Corrective Action
If you want the same or similar DDL to be applied on the target then you can apply that DDL on the target keyspace
and then restart the workflow. For example, using the example above:
```bash
$ vtctlclient ApplySchema -- --allow_long_unavailability --ddl_strategy=direct --sql="alter table customer add notes varchar(100) not null" customer

$ vtctlclient Workflow -- customer.commerce2customer start
``` 

If the tables are not very large or the workflow has not made much progress, you can alternatively `Cancel` the current
worfklow and `Create` another. For example:
```bash
$ vtctlclient MoveTables -- Cancel customer.commerce2customer
Cancel was successful for workflow customer.commerce2customer
Start State: Reads Not Switched. Writes Not Switched
Current State: Workflow Not Found


$ vtctlclient MoveTables -- --source commerce --tables 'customer,corder' Create customer.commerce2customer
Waiting for workflow to start:

Workflow started successfully with 1 stream(s)

The following vreplication streams exist for workflow customer.commerce2customer:

id=2 on 0/zone1-0000000201: Status: Copying. VStream Lag: 0s.


$ vtctlclient MoveTables -- Progress customer.commerce2customer

The following vreplication streams exist for workflow customer.commerce2customer:

id=2 on 0/zone1-0000000201: Status: Running. VStream Lag: 0s.
```

### Switching Traffic Fails

You can encounter a variety of failures during the `SwitchTraffic`/`ReverseTraffic` step as a number of operations are performed. To
demonstrate that we can look at an example dry run output:
```bash
$ vtctlclient MoveTables -- --dry_run SwitchTraffic customer.commerce2customer
Dry Run results for SwitchTraffic run at 11 Jan 23 08:51 EST
Parameters: --dry_run SwitchTraffic customer.commerce2customer

Lock keyspace commerce
Switch reads for tables [corder,customer] to keyspace customer for tablet types [RDONLY,REPLICA]
Routing rules for tables [corder,customer] will be updated
Unlock keyspace commerce
Lock keyspace commerce
Lock keyspace customer
Stop writes on keyspace commerce, tables [corder,customer]:
	Keyspace commerce, Shard 0 at Position MySQL56/a2d90338-916d-11ed-820a-498bdfbb0b03:1-94
Wait for VReplication on stopped streams to catchup for up to 30s
Create reverse replication workflow commerce2customer_reverse
Create journal entries on source databases
Enable writes on keyspace customer tables [corder,customer]
Switch routing from keyspace commerce to keyspace customer
Routing rules for tables [corder,customer] will be updated
Switch writes completed, freeze and delete vreplication streams on:
	tablet 201
Start reverse replication streams on:
	tablet 101
Mark vreplication streams frozen on:
	Keyspace customer, Shard 0, Tablet 201, Workflow commerce2customer, DbName vt_customer
Unlock keyspace customer
Unlock keyspace commerce
```

</br>

#### disallowed due to rule: enforce denied tables

If your queries start failing with this error then you most likely had some leftover artifacts from a previous `MoveTables` operation
that were not properly cleaned up by running [`MoveTables -- Cancel`](../../../reference/vreplication/movetables/#cancel). For
`MoveTables` operations, shard query serving control records (denied tables lists) are used in addition to
[routing rules](../../../reference/features/schema-routing-rules/) to ensure that all query traffic is managed by the correct keyspace
as you are often only moving some tables from one keyspace to another. If those control records are not properly cleaned up then
queries may be incorrectly denied when traffic is switched. If you e.g. were to see the following error for queries after switching
traffic for the customer table from the commerce keyspace to the customer keyspace:
```
code = FailedPrecondition desc = disallowed due to rule: enforce denied tables (CallerID: matt) for query SELECT * FROM customer WHERE customer_id = 1
```

Then you can remove those unwanted/errant denied table rules from the customer keyspace this way:
```bash
$ for type in primary replica rdonly; do
    vtctldclient SetShardTabletControl --remove customer/0 ${type}
  done

# Ensure that these changes are in place everywhere
$ vtctldclient RefreshStateByShard customer/0
```

### Completion and Cleanup Failures

The completion action performs a number of steps that could potentially fail. We can again use the dry run output to demonstrate the
various actions that are taken:
```bash
$ vtctlclient MoveTables -- --dry_run Complete customer.commerce2customer
Dry Run results for Complete run at 11 Jan 23 10:22 EST
Parameters: --dry_run Complete customer.commerce2customer

Lock keyspace commerce
Lock keyspace customer
Dropping these tables from the database and removing them from the vschema for keyspace commerce:
	Keyspace commerce Shard 0 DbName vt_commerce Tablet 101 Table corder
	Keyspace commerce Shard 0 DbName vt_commerce Tablet 101 Table customer
Denied tables [corder,customer] will be removed from:
	Keyspace commerce Shard 0 Tablet 101
Delete reverse vreplication streams on source:
	Keyspace commerce Shard 0 Workflow commerce2customer_reverse DbName vt_commerce Tablet 101
Delete vreplication streams on target:
	Keyspace customer Shard 0 Workflow commerce2customer DbName vt_customer Tablet 201
Routing rules for participating tables will be deleted
Unlock keyspace customer
Unlock keyspace commerce
```