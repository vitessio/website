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
    - Note that in most production systems the tablet endpoints would be scraped and stored in something like Prometheues where you can build dashboards and alerting on the data

### Save Routing Rules

The `Create`, `SwitchTraffic`/`ReverseTraffic`, and `Cancel`/`Complete` actions modify the
[routing rules](../../../reference/features/schema-routing-rules/). You may want to save the routing rules before
taking an action just in case you want to restore them for any reason (note that e.g. the `ReverseTraffic` will
also properly revert the routing rules):
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



# OLD CONTENT

## Confirm MoveTables has completed

You can tell if the MoveTables workflow is done copying by inspecting workflow “State” and “CopyState” fields.  
The MoveTables workflow is done when the state has transitioned to “Running” from “Copying”, and the CopyState is empty (null).

### Performing the VDiff

Depending on the size of the table(s), the VDiff process may need increased timeouts for two things:

- If you are running VDiff using vtctldclient (i.e. vtctld is doing the VDiff) you will need to increase the vtctldclient
gRPC action timeout. This increase could be something like `--action_timeout 12h` as the default is 1 hour.
- Increase the `--filtered_replication_wait_time` parameter for VDiff as the default is 30 seconds. You many need to
increase this to hours on large and/or busy tables.

{{< info >}}
Note that running VDiff via vtctld can lead to vtctld consuming significantly more memory than usual.
We've found this to be around 1 GB plus, instead of the a few hundred MB that it normally uses.
If you run your vtctld in a memory limited container, you may want to take this into account.
Similarly, while a VDiff is in progress, vtctld will consume significantly more CPU than usual.
{{< /info >}}

Since a VDiff is a synchronous operation, but does not report results until it has completed, which might be after many hours, you have to follow its progress indirectly. 
This can be done by inspecting the vtctld logs, which will print progress every 10 million rows when running VDiff on a large table. 
This can also be used to estimate how long the operation may take.
You will also need to run VDiff from somewhere where it can keep running uninterrupted for hours. 
For example, in a screen or tmux session on a server with stable network connectivity to vtctld. 

### What happens during a VDiff

VDiff uses the same VReplication and VStreamer infrastructure as MoveTables, Materialize, etc.  
As such, it will use consistent snapshot read queries against both sets of tablets that host the data being compared. 
If either side of these tablets are actively being used to serve queries, which usually occurs on the source side, this may lead to impact to that workload. 
This is why we recommend running VDiff against RDONLY tablet types, to reduce the chance of impacting performance-sensitive applications that may be accessing the keyspace(s).

{{< info >}}
Note that the VDiff operation (i.e. the process streaming the data from the two sets of tablets where tables are being compared) actually runs inside vtctld. 
As a result, a large amount of data is potentially transferred between the tablets and vtctld. 
You may want to keep this in mind when choosing the vtctld instance that you are going to run the VDiff against.
{{< /info >}}

### Potential errors or issues when running VDiff

1. Timeouts or network interruptions

VDiff may not start because tablets of the `--tablet_types` specified may not be available in the cells specified. 
This is often the case if you are using the optional parameters of `--source_cell` and `--target_cell`. 
In a case like this VDiff will appear to run, but will not actually make any progress. 
This can be observed via messages in the vtctld log like:

```sh
`I0804 14:43:46.664273   64656 tablet_picker.go:146] No tablet found for streaming, shard keyspacename.0, cells [cellname], tabletTypes [RDONLY], sleeping for 30 seconds`
```

In a case like this, you should stop the VDiff, then adjust the options appropriately, and restart.

### How do you stop and restart VDiff

Since VDiff is synchronous, just using CTRL-C on the vtctldclient VDiff command is sufficient.
Executing another VDiff immediately afterwards will return the workflow back to the proper state.  

If you do NOT plan to execute another VDiff, you will need to double check the current state of the workflow to ensure that it’s running after you interrupted the vtctldclient process. 
If a VDiff is interrupted in certain phases it can leave the workflow stopped.

To check workflow state:

```sh
vtctlclient … Workflow -- targetkeyspace.workflowname show
```

If the workflow state is STOPPED and the message field is empty you can simply start the workflow again:

```sh
vtctlclient … Workflow -- targetkeyspace.workflowname start
```

If the workflow state is STOPPED and the message field is “Stop position … already reached”, then you will have to clear the stop_pos field in the _vt.vreplication table before starting the workflow again.
There are detailed notes and test cases on interrupted VDiffs for further reading [here](https://gist.github.com/mattlord/2205e7b4e5c7e393fe645122ea869e8b).

### How do you stop and restart Workflows

For general Workflow-based operations (MoveTables, Materialize and CreateLookupVindex), cleanup can be performed directly against the underlying workflows. 
Depending on the use-case, additional or alternative cleanup methods may be available.

1. The general procedure is as follows:

```sh
vtctlclient … Workflow -- targetkeyspace.workflowname show
vtctlclient … Workflow -- targetkeyspace.workflowname stop
vtctlclient … Workflow -- targetkeyspace.workflowname delete
```

In the case of MoveTables, additional operations are done at various stages against the Vitess routing rules, which are global for a Vitess cluster.
As a result, you may have to dump the routing rules, edit them, and then apply the edited routing rules in order to fully clean up your workflows. 
Usually, it is also advisable to save the routing rules before starting your MoveTables operation.

2. To save or dump routing rules:

```sh
vtctldclient --server ...  GetRoutingRules > /path/to/save/routingrules.json
```

3. You should then be able to edit the routingrules.json file and then apply the new routing rules using:

```sh
vtctldclient --server ...  ApplyRoutingRules -- --rules=($cat /path/to/save/routingrules.json) --dry-run
```
That will not actually execute ApplyRoutingRules due to the `--dry-run` flag, instead it will enable you to see what would happen when you run that command and address any issues that may occur.

4. Once you have verified the command works as intended run it without --dry-run:

```sh
vtctldclient -server ...  ApplyRoutingRules -rules=($cat /path/to/save/routingrules.json) 
```

Some Vreplication workflows (e.g. MoveTables and Resharding) have their own DropSources cleanup command, which can take care of much of the above.

### How do you clean the tables in the target keyspace

If traffic is not flowing against the target keyspace, you can drop the tables without being concerned about the locking/performance effects.

{{< warning >}}
Be very careful with the routing rules. 
If the routing rules are not correctly cleaned up first, the action of dropping a table in the target keyspace will be re-routed to the source keyspace. 
This will result in you dropping your source/original table.
{{< /warning >}}

## Begin your cutover

It is recommended you first run SwitchTraffic with --dry_run so you understand what actions are going to be taken before actually taking them. 
`--dry_run` needs to be added before SwitchTraffic along with any other [SwitchTraffic parameters](../../../reference/vreplication/switchtraffic) you want to pass.
Reads and writes no longer need to be switched in specific order, but both will need to be completed to run MoveTables Complete. 
The default SwitchTraffic behavior is to switch all traffic in a single command, Vitess switches all reads and then writes if you use this default option.

1. Depending on what `--tablet_types` you are using, you will use one of the four following commands:

- Default (switches all tablet types)

```
vtctlclient --server vtctld.host:15999 MoveTables -- --dry_run SwitchTraffic targetkeyspace.workflowname
```

- RDONLY:
  
```
vtctlclient --server vtctld.host:15999 MoveTables -- --tablet_types=rdonly --dry_run SwitchTraffic targetkeyspace.workflowname
```

- REPLICA:
  
```
vtctlclient --server vtctld.host:15999 MoveTables -- --tablet_types=replica --dry_run SwitchTraffic targetkeyspace.workflowname
```

- PRIMARY:  

```
vtctlclient --server vtctld.host:15999 MoveTables -- --tablet_types=primary --dry_run SwitchTraffic targetkeyspace.workflowname
```

The output of these commands will look similar to the following:

```sh
$ vtctlclient --server localhost:15999 MoveTables -- --tablet_types=rdonly --dry_run SwitchTraffic targetkeyspace.workflowname 
Dry Run results for SwitchReads run at 02 Jan 06 15:04 MST
Parameters: --tablet_types=rdonly --dry_run targetkeyspace.workflowname

Lock keyspace sourcekeyspace
Switch reads for tables [t1] to keyspace targetkeyspace for tablet types [RDONLY]
Routing rules for tables [t1] will be updated
Unlock keyspace sourcekeyspace
```

After you have tried the above command(s) with `--dry_run` remove just that flag to then actually run the command.

## Cutover rollback

MoveTables v2 supports cutover rollbacks via the MoveTables --ReverseTraffic command. 
ReverseTraffic supports the `--dry_run` flag and we recommend using it to verify what actions ReverseTraffic will take. 
Then remove --dry_run when you are prepared to actually ReverseTraffic.
The default ReverseTraffic behavior is to switch all traffic in a single command, meaning that Vitess switches all reads and then writes if you use this default option.

1. Depending on what `--tablet_types` you are using, you will use one of the four following commands:

- Default (switches all tablet types)

```
vtctlclient --server vtctld.host:15999 MoveTables -- --dry_run ReverseTraffic targetkeyspace.workflowname
```

- RDONLY:
  
```
vtctlclient --server vtctld.host:15999 MoveTables -- --tablet_types=rdonly --dry_run ReverseTraffic targetkeyspace.workflowname
```

- REPLICA:
  
```
vtctlclient --server vtctld.host:15999 MoveTables -- --tablet_types=replica --dry_run ReverseTraffic targetkeyspace.workflowname
```

- PRIMARY:  

```
vtctlclient --server vtctld.host:15999 MoveTables -- --tablet_types=primary --dry_run ReverseTraffic targetkeyspace.workflowname
```

## Clean up of the cutover

#### After a successful cutover

If the cutover was successful, the MoveTables Complete command will do the following:

```
vtctlclient --server vtctld.host:15999 MoveTables -- --dry_run Complete targetkeyspace.workflowname
```

1. Drop the tables involved in the MoveTables in the original keyspace (sourcekeyspace)
2. Remove the workflows related to the MoveTables operation
3. Clean up the [routing rules](../../../reference/features/schema-routing-rules/). Applications pointed to the sourcekeyspace will no longer be transparently redirected to the targetkeyspace.

#### After a cutover rollback

If a cutover was rolled back via ReverseTraffic, the MoveTables Cancel command will clean up the targetkeyspace:

```
vtctlclient --server vtctld.host:15999 MoveTables -- Cancel targetkeyspace.workflowname
```

1. Drop the tables involved in the MoveTables in the new keyspace (targetkeyspace)
2. Remove the workflows related to the MoveTables operation
3. Clean up the [routing rules](../../../reference/features/schema-routing-rules/). Applications pointed to the targetkeyspace will no longer be transparently redirected to the sourcekeyspace.