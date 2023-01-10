---
title: Troubleshooting
weight: 4
---

## Overview

Here we will cover some common issues seen during a migration, how to avoid them, how to detect them, and how to address them.

{{< info >}}
This guide follows on from the [Get Started](../../../get-started/) guides. Please make sure that you have a
[Kubernetes Operator](../../../get-started/operator) or [local](../../../get-started/local) installation ready.
Make sure you have run the "101" and "201" steps of the examples, for example the "101" step is
`101_initial_cluster.sh` in the [local](../../../get-started/local) example. The commands in this guide also assume
you have setup the shell aliases from the example, e.g. `env.sh` in the [local](../../../get-started/local) example.
{{< /info >}}

## 

Before starting the cutover process you will want to:
 
1.  Save your routing rules just in case the are needed to revert the process:

```sh
vtctldclient --server vtctld.host:15999 GetRoutingRules > /var/tmp/routingrules.backup.json
```

2. Check that the source keyspace(s) have the necessary tablet types in them (e.g. RDONLY).
3. Check that there is free diskspace in the target keyspace (i.e. on the target keyspace tablets). This is because the process will use at least as much diskspace as is in the source keyspace for the tables being moved.

### Performance notes

- In newer Vitess versions (e.g. v7, v8, or v9) MoveTable performance is usually limited by the downstream MySQL instance insert performance.
- In very recent Vitess versions (e.g. v10 or v11), the various database row and gRPC packet buffers are sized dynamically for improved performance.
- With Vitess versions before v10, be careful of making the row and packet buffers too large, since you might run into an issue where [vreplication catchup mode may be unable to terminate](https://github.com/vitessio/vitess/issues/8104).

## Start MoveTables

To begin MoveTables run the following command:

```sh
vtctlclient --server vtctld.host:15999 MoveTables -- --source sourcekeyspace --tables 'table1,table2,table3' Create targetkeyspace.workflowname
```

You can then monitor the workflow status:

```sh
vtctlclient --server vtctld.host:15999 Workflow -- targetkeyspace listall
Following workflow(s) found in keyspace targetkeyspace.workflowname
vtctldclient --server vtctld.host:15999 MoveTables -- Progress targetkeyspace.workflowname
```
If you want more detailed information you can also run:

```sh
vtctlclient --server vtctld.host:15999 Workflow -- targetkeyspace.workflowname show
```
The output for `Workflow ... show` is shown below in the --v1 commands.

## Confirm MoveTables has completed

You can tell if the MoveTables workflow is done copying by inspecting workflow “State” and “CopyState” fields.  
The MoveTables workflow is done when the state has transitioned to “Running” from “Copying”, and the CopyState is empty (null).

### Performing the VDiff

Depending on the size of the table(s), the VDiff process may need increased timeouts for two things:

- If you are running VDiff using vtctldclient (i.e. vtctld is doing the VDiff) you will need to increase the vtctldclient gRPC action timeout. This increase could be something like `--action_timeout 12h` as the default is 1 hour.
- Increase the `--filtered_replication_wait_time` parameter for VDiff as the default is 30 seconds. You many need to increase this to hours on large and/or busy tables.

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