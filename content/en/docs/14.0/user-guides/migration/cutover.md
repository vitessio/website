---
title: Cutover Steps and Troubleshooting
weight: 4
---

## Prerequisites

In this guide we assume that the change being done is going from unsharded to unsharded keyspace and that all of the following names are used:

- The source keyspace is called:  sourcekeyspace
- The target keyspace is called:  targetkeyspace
- The tables to be moved:  table1, table2, table3

## Setup

Before starting the cutover process you will want to:
 
1.  Save your routing rules just in case the are needed to revert the process:

```sh
vtctlclient -server vtctld.host:15999 GetRoutingRules > /var/tmp/routingrules.backup.json
```

2. Check that the source keyspace(s) have the necessary tablet types in them (e.g. RDONLY).
3. Check that there is free diskspace in the target keyspace (i.e. on the target keyspace tablets). This is because the process will use at least as much diskspace as is in the source keyspace for the tables being moved.

### Performance notes

- In newer Vitess versions (e.g. v7, v8, or v9) MoveTable performance is usually limited by the downstream MySQL instance insert performance.
- In very recent Vitess versions (e.g. v10 or v11), the various database row and gRPC packet buffers are sized dynamically for improved performance.
- With Vitess versions before v10, be careful of making the row and packet buffers too large, since you might run into an issue where [vreplication catchup mode may be unable to terminate](https://github.com/vitessio/vitess/issues/8104).

## Start MoveTables

### Using -v2 commands

To begin MoveTables run the following command:

```sh
vtctlclient -server vtctld.host:15999 MoveTables -source sourcekeyspace -tables 'table1,table2,table3' Create targetkeyspace.workflowname
```

You can then monitor the workflow status:

```sh
vtctlclient -server vtctld.host:15999 Workflow targetkeyspace listall
Following workflow(s) found in keyspace targetkeyspace.workflowname
vtctlclient -server vtctld.host:15999 MoveTables Progress targetkeyspace.workflowname
```
If you want more detailed information you can also run:

```sh
vtctlclient -server vtctld.host:15999 Workflow targetkeyspace.workflowname show 
```
The output for `Workflow ... show` is shown below in the -v1 commands.

### Using -v1 commands

To begin MoveTables run the following command:

```sh
vtctlclient -server vtctld.host:15999 MoveTables -workflow=workflowname sourcekeyspace targetkeyspace table1,table2,table3
```

You can then monitor the workflow status:

```sh
vtctlclient -server vtctld.host:15999 Workflow targetkeyspace listall
Following workflow(s) found in keyspace targetkeyspace: workflowname
vtctlclient -server vtctld.host:15999 Workflow targetkeyspace.workflowname show
    {
    "Workflow": "workflowname",
    "SourceLocation": {
        "Keyspace": "sourcekeyspace",
        "Shards": [
            "0"
        ]
    },
    "TargetLocation": {
        "Keyspace": "targetkeyspace",
        "Shards": [
            "0"
        ]
    },
    "MaxVReplicationLag": 0,
    "ShardStatuses": {
        "0/zone1-0000000900": {
            "MasterReplicationStatuses": [
                {
                    "Shard": "0",
                    "Tablet": "zone1-0000000900",
                    "ID": 1,
                    "Bls": {
                        "keyspace": "sourcekeyspace",
                        "shard": "0",
                        "filter": {
                            "rules": [
                                {
                                    "match": "table1",
                                    "filter": "select * from table1"
                                },
                                {
                                    "match": "table2",
                                    "filter": "select * from table2"
                                },
                                {
                                    "match": "table3",
                                    "filter": "select * from table3"
                                }
                            ]
                        }
                    },
                    "Pos": "MySQL56/82e3ebcd-d2bc-11eb-821e-00259085bb84:1-33",
                    "StopPos": "",
                    "State": "Running",
                    "DBName": "vt_targetkeyspace",
                    "TransactionTimestamp": 0,
                    "TimeUpdated": 1624299797,
                    "Message": "",
                    "CopyState": null
                }
            ],
            "TabletControls": null,
            "MasterIsServing": true
        }
    }
}
```

### Potential errors or issues when starting MoveTables

1. Syntax or other issue where MoveTables doesn’t start

- Use `Workflow .. listall` to verify that MoveTables did not start
- Check the information in -h to see what might need to be adjusted
- Fix the syntax issue and re-run the MoveTables command

2. MoveTables starts but does not do what was expected

- Use `Workflow .. listall` and `Workflow .. show` as described above to determine what happened 
- You may need to collect vttablet log information on the source(s) and/or target(s) to diagnose some issues

For example, if you set your `-vreplication_tablet_type` for your vttablets to RDONLY and you are not passing an override `-tablet_types` for MoveTables.  

The result will be that the MoveTables vreplication streams will only use RDONLY tablet types as their source. 
If no tablets of this type are available in the same cell as the target keyspace’s primary tablet, the vreplication streams will never start and will loop while searching for eligible tablets to copy from. 
You would only be able to diagnose this problem by looking at the vttablet logs for the target keyspace primary tablet.

- In most cases, it would be appropriate to stop and delete the workflow using the following:

```sh
vtctlclient -server vtctld.host:15999 Workflow targetkeyspace.workflowname stop
vtctlclient -server vtctld.host:15999 Workflow targetkeyspace.workflowname delete
```

- Then fix underlying issue and re-run the MoveTables command

## Confirm MoveTables has completed

You can tell if the MoveTables workflow is done copying by inspecting workflow “State” and “CopyState” fields.  
The MoveTables workflow is done when the state has transitioned to “Running” from “Copying”, and the CopyState is empty (null).

### Performing the VDiff

Depending on the size of the table(s), the VDiff process may need increased timeouts for two things:

- If you are running VDiff using vtctlclient (i.e. vtctld is doing the VDiff) you will need to increase the vtctlclient gRPC action timeout. This increase could be something like `-action_timeout 12h` as the default is 1 hour.
- Increase the `-filtered_replication_wait_time` parameter for VDiff as the default is 30 seconds. You many need to increase this to hours on large and/or busy tables.

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

VDiff may not start because tablets of the `-tablet_type` specified may not be available in the cells specified. 
This is often the case if you are using the optional parameters of `-source_cell` and `-target_cell`. 
In a case like this VDiff will appear to run, but will not actually make any progress. 
This can be observed via messages in the vtctld log like:

```sh
`I0804 14:43:46.664273   64656 tablet_picker.go:146] No tablet found for streaming, shard keyspacename.0, cells [cellname], tabletTypes [RDONLY], sleeping for 30 seconds`
```

In a case like this, you should stop the VDiff, then adjust the options appropriately, and restart.

### How do you stop and restart VDiff

Since VDiff is synchronous, just using CTRL-C on the vtctlclient VDiff command is sufficient.
Executing another VDiff immediately afterwards will return the workflow back to the proper state.  

If you do NOT plan to execute another VDiff, you will need to double check the current state of the workflow to ensure that it’s running after you interrupted the vtctlclient process. 
If a VDiff is interrupted in certain phases it can leave the workflow stopped.

To check workflow state:

```sh
vtctlclient … Workflow targetkeyspace.workflowname show
```

If the workflow state is STOPPED and the message field is empty you can simply start the workflow again:

```sh
vtctlclient … Workflow targetkeyspace.workflowname start
```

If the workflow state is STOPPED and the message field is “Stop position … already reached”, then you will have to clear the stop_pos field in the _vt.vreplication table before starting the workflow again.
There are detailed notes and test cases on interrupted VDiffs for further reading [here](https://gist.github.com/mattlord/2205e7b4e5c7e393fe645122ea869e8b).

### How do you stop and restart Workflows

For general Workflow-based operations (MoveTables, Materialize and CreateLookupVindex), cleanup can be performed directly against the underlying workflows. 
Depending on the use-case, additional or alternative cleanup methods may be available.

1. The general procedure is as follows:

```sh
vtctlclient … Workflow targetkeyspace.workflowname show
vtctlclient … Workflow targetkeyspace.workflowname stop
vtctlclient … Workflow targetkeyspace.workflowname delete
```

In the case of MoveTables, additional operations are done at various stages against the Vitess routing rules, which are global for a Vitess cluster.
As a result, you may have to dump the routing rules, edit them, and then apply the edited routing rules in order to fully clean up your workflows. 
Usually, it is also advisable to save the routing rules before starting your MoveTables operation.

2. To save or dump routing rules:

```sh
vtctlclient -server ...  GetRoutingRules > /path/to/save/routingrules.json
```

3. You should then be able to edit the routingrules.json file and then apply the new routing rules using:

```sh
vtctlclient -server ...  ApplyRoutingRules -rules=($cat /path/to/save/routingrules.json) -dry-run
```
That will not actually execute ApplyRoutingRules due to the `-dry-run` flag, instead it will enable you to see what would happen when you run that command and address any issues that may occur.

4. Once you have verified the command works as intended run it without -dry-run:

```sh
vtctlclient -server ...  ApplyRoutingRules -rules=($cat /path/to/save/routingrules.json) 
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

### When using -v2 commands

With MoveTables v2 instead of performing SwitchReads/Writes you will use MoveTables --SwitchTraffic. 
It is recommended you first run SwitchTraffic with -dry_run so you understand what actions are going to be taken before actually taking them. 
`-dry_run` needs to be added before SwitchTraffic along with any other [SwitchTraffic parameters](../../../reference/vreplication/switchtraffic) you want to pass.
Reads and writes no longer need to be switched in specific order, but both will need to be completed to run MoveTables Complete. 
The default SwitchTraffic behavior is to switch all traffic in a single command, Vitess switches all reads and then writes if you use this default option.

1. Depending on what `-table_type` you are using, you will use one of the four following commands:

- Default (switches all tablet types)

```
vtctlclient -server vtctld.host:15999 MoveTables -dry_run SwitchTraffic targetkeyspace.workflowname
```

- RDONLY:
  
```
vtctlclient -server vtctld.host:15999 MoveTables -tablet_types=rdonly -dry_run SwitchTraffic targetkeyspace.workflowname
```

- REPLICA:
  
```
vtctlclient -server vtctld.host:15999 MoveTables -tablet_types=replica -dry_run SwitchTraffic targetkeyspace.workflowname
```

- PRIMARY:  

```
vtctlclient -server vtctld.host:15999 MoveTables -tablet_types=primary -dry_run SwitchTraffic targetkeyspace.workflowname
```

The output of these commands will look similar to the following:

```sh
$ vtctlclient -server localhost:15999 MoveTables -tablet_types=rdonly -dry_run SwitchTraffic targetkeyspace.workflowname 
Dry Run results for SwitchReads run at 02 Jan 06 15:04 MST
Parameters: -tablet_types=rdonly -dry_run targetkeyspace.workflowname

Lock keyspace sourcekeyspace
Switch reads for tables [t1] to keyspace targetkeyspace for tablet types [RDONLY]
Routing rules for tables [t1] will be updated
Unlock keyspace sourcekeyspace
```

After you have tried the above command(s) with `-dry_run` remove just that flag to then actually run the command.

### When using -v1 commands

1. Depending on what `-table_type` you are using, you will use one of the two following commands:

- RDONLY:
  
```
vtctlclient -server vtctld.host:15999 SwitchReads -tablet_type=rdonly targetkeyspace.workflowname
```

- REPLICA:  

```
vtctlclient -server vtctld.host:15999 SwitchReads -tablet_type=replica targetkeyspace.workflowname
```

The output of these commands will look similar to the following:

```sh
$ vtctlclient -server localhost:15999 SwitchReads -tablet_type=rdonly -reverse -dry_run targetkeyspace.workflowname
Dry Run results for SwitchReads run at 02 Jan 06 15:04 MST
Parameters: -tablet_type=rdonly -reverse -dry_run targetkeyspace.workflowname

Lock keyspace sourcekeyspace
Switch reads for tables [t1] to keyspace sourcekeyspace for tablet types [RDONLY]
Routing rules for tables [t1] will be updated
Unlock keyspace sourcekeyspace
```
 
 After you have tried the above command(s) with `-dry_run` remove just that flag to then actually run the command.
 
2. You will then need to switch your writes using the following command:

It is recommended you first run SwitchWrites with -dry_run, so you understand what actions are going to be taken before actually taking them. 
`-dry_run` needs to be added before targetkeyspace.workflowname.

```
$ vtctlclient -server localhost:15999 SwitchWrites -dry_run targetkeyspace.workflowname 
```
The output of this command will look similar to the following:

```sh
$ vtctlclient -server localhost:15999 SwitchWrites -dry_run targetkeyspace.workflowname
Dry Run results for SwitchWrites run at 02 Jan 06 15:04 MST
Parameters: -dry_run targetkeyspace.workflowname

Lock keyspace sourcekeyspace
Lock keyspace targetkeyspace
Stop writes on keyspace sourcekeyspace, tables [t1]:
        Keyspace sourcekeyspace, Shard 0 at Position MySQL56/09e0a4fa-0b6f-11ec-8ef5-00259085bb84:1-62
Wait for VReplication on stopped streams to catchup for upto 30s
Create reverse replication workflow workflowname_reverse
Create journal entries on source databases
Enable writes on keyspace targetkeyspace tables [t1]
Switch routing from keyspace sourcekeyspace to keyspace targetkeyspace
Routing rules for tables [t1] will be updated
SwitchWrites completed, freeze and delete vreplication streams on:
        tablet 900
Start reverse replication streams on:
        tablet 100
Mark vreplication streams frozen on:
        Keyspace targetkeyspace, Shard 0, Tablet 900, Workflow workflowname, DbName vt_targetkeyspace
Unlock keyspace targetkeyspace
Unlock keyspace sourcekeyspace
```

After you have tried the above command(s) with `-dry_run` remove just that flag to then actually run the command.

### Potential errors or issues during the cutover

1. Attempting to cross Vitess cells

Unless you explicitly specify it, MoveTables flows will not cross Vitess cells. 
Also, if you do not have the source tablet_types for the MoveTables workflow, either implied or explicitly specified, in the local cell, the MoveTables workflow will not actually take any action. 
Any subsequent SwitchReads or SwitchWrites will fail.

You need to verify that the MoveTables workflow did complete successfully (i.e. copied all data), either manually or by using VDiff. 
At a minimum, you can use the `Workflow … show` command to validate that the workflow has not errored.

This example shows a healthy, completed MoveTables workflow:

```sh
$ vtctlclient -server localhost:15999 Workflow show targetkeyspace.workflowname
{
    "Workflow": "workflowname",
    "SourceLocation": {
        "Keyspace": "sourcekeyspace",
        "Shards": [
            "0"
        ]
    },
    "TargetLocation": {
        "Keyspace": "targetkeyspace",
        "Shards": [
            "0"
        ]
    },
    "MaxVReplicationLag": 1,
    "ShardStatuses": {
        "0/zone1-0000000900": {
            "MasterReplicationStatuses": [
                {
                    "Shard": "0",
                    "Tablet": "zone1-0000000900",
                    "ID": 1,
                    "Bls": {
                        "keyspace": "sourcekeyspace",
                        "shard": "0",
                        "filter": {
                            "rules": [
                                {
                                    "match": "t1",
                                    "filter": "select * from t1 where in_keyrange(c1, 'targetkeyspace.xxhash', '-')"
                                }
                            ]
                        }
                    },
                    "Pos": "c403da7f-05ec-11ec-94bd-00259085bb84:1-58",
                    "StopPos": "",
                    "State": "Running",
                    "DBName": "vt_targetkeyspace",
                    "TransactionTimestamp": 0,
                    "TimeUpdated": 1629928368,
                    "Message": "",
                    "CopyState": null
                }
            ],
            "TabletControls": null,
            "MasterIsServing": true
        }
    }
} 
```

2. Timeouts 

If the VReplication of changes from the sourcekeyspace to the targetkeyspace are lagging (possibly because of high write rate to the source keyspace), the SwitchWrites operation may fail.
This is because as part of SwitchWrites, traffic is paused, and Vitess then waits a short amount of time for the targetkeyspace shards to catch up to the point(s) where the sourcekeyspace shard(s) were stopped.
If this does not happen within that timeout period, the SwitchWrites will fail. 
The default for this wait period is 30 seconds;  and can be adjusted upwards or downwards by passing the -timeout flag to the SwitchWrites command.

{{< info >}}
Note that the above limitation does not apply to SwitchReads, since replica/rdonly instances are assumed to lag anyway.  You should accordingly manually validate that the replica lag is within acceptable limits for your purposes before you run SwitchReads.   You can do this by inspecting the MaxVReplicationLag value in the Workflow … show output (cf. above).  This value represents the maximum lag, in seconds, of the underlying streams.
{{< /info >}}

## Cutover rollback

### When using -v2 commands

MoveTables v2 supports cutover rollbacks via the MoveTables --ReverseTraffic command. 
ReverseTraffic supports the `-dry_run` flag and we recommend using it to verify what actions ReverseTraffic will take. 
Then remove -dry_run when you are prepared to actually ReverseTraffic.
The default ReverseTraffic behavior is to switch all traffic in a single command, meaning that Vitess switches all reads and then writes if you use this default option.

1. Depending on what `-table_type` you are using, you will use one of the four following commands:

- Default (switches all tablet types)

```
vtctlclient -server vtctld.host:15999 MoveTables -dry_run ReverseTraffic targetkeyspace.workflowname
```

- RDONLY:
  
```
vtctlclient -server vtctld.host:15999 MoveTables -tablet_types=rdonly -dry_run ReverseTraffic targetkeyspace.workflowname
```

- REPLICA:
  
```
vtctlclient -server vtctld.host:15999 MoveTables -tablet_types=replica -dry_run ReverseTraffic targetkeyspace.workflowname
```

- PRIMARY:  

```
vtctlclient -server vtctld.host:15999 MoveTables -tablet_types=primary -dry_run ReverseTraffic targetkeyspace.workflowname
```

### When using -v1 commands

#### Writes have not been switched 

{{< warning >}}
Only follow these steps if SwitchWrites has not yet been run.
{{< /warning >}}

1. Depending on what `-table_type` you are using, you will use one of the two following commands:

- RDONLY:
  
```
vtctlclient -server localhost:15999 SwitchReads -tablet_type=rdonly -dry_run sourcekeyspace.workflowname_reverse
```

- REPLICA:  

```
vtctlclient -server localhost:15999 SwitchReads -tablet_type=replica -dry_run sourcekeyspace.workflowname_reverse
```

#### Writes have been switched:

{{< warning >}}
Only follow these steps if SwitchWrites has already been run.
{{< /warning >}}

1. Depending on what `-table_type` you are using, you will use one of the two following commands:

- RDONLY:
  
```
vtctlclient -server vtctld.host:15999 SwitchReads -tablet_type=rdonly -reverse targetkeyspace.workflowname
```

- REPLICA:  

```
vtctlclient -server vtctld.host:15999 SwitchReads -tablet_type=replica -reverse targetkeyspace.workflowname
```

The output of this command will look similar to the following:

```sh
$ vtctlclient -server localhost:15999 SwitchReads -tablet_type=rdonly -dry_run sourcekeyspace.workflowname_reverse
Dry Run results for SwitchReads run at 02 Jan 06 15:04 MST
Parameters: -tablet_type=rdonly -dry_run sourcekeyspace.workflowname_reverse

Lock keyspace targetkeyspace
Switch reads for tables [t1] to keyspace sourcekeyspace for tablet types [RDONLY]
Routing rules for tables [t1] will be updated
Unlock keyspace targetkeyspace
```

```sh
$ vtctlclient -server localhost:15999 SwitchReads -tablet_type=replica -dry_run sourcekeyspace.workflowname_reverse
*** SwitchReads is deprecated. Consider using v2 commands instead, see https://vitess.io/docs/reference/vreplication/ ***
Dry Run results for SwitchReads run at 02 Jan 06 15:04 MST
Parameters: -tablet_type=replica -dry_run sourcekeyspace.workflowname_reverse

Lock keyspace targetkeyspace
Switch reads for tables [t1] to keyspace sourcekeyspace for tablet types [REPLICA]
Routing rules for tables [t1] will be updated
Unlock keyspace targetkeyspace
```

2. After the reads are switched you will then need to reverse the writes:

```
vtctlclient -server vtctld.host:15999 SwitchWrites sourcekeyspace.workflowname_reverse
```

The output of this command will look similar to the following:

```sh
$ vtctlclient -server localhost:15999 SwitchWrites -dry_run sourcekeyspace.workflowname_reverse
Dry Run results for SwitchWrites run at 02 Jan 06 15:04 MST
Parameters: -dry_run sourcekeyspace.workflowname_reverse

Lock keyspace targetkeyspace
Lock keyspace sourcekeyspace
Stop writes on keyspace targetkeyspace, tables [t1]:
        Keyspace targetkeyspace, Shard 0 at Position MySQL56/1aa1a03b-0b6f-11ec-a022-00259085bb84:1-133
Wait for VReplication on stopped streams to catchup for upto 30s
Create reverse replication workflow workflowname
Create journal entries on source databases
Enable writes on keyspace sourcekeyspace tables [t1]
Switch routing from keyspace targetkeyspace to keyspace sourcekeyspace
Routing rules for tables [t1] will be updated
SwitchWrites completed, freeze and delete vreplication streams on:
        tablet 100
Start reverse replication streams on:
        tablet 900
Mark vreplication streams frozen on:
        Keyspace sourcekeyspace, Shard 0, Tablet 100, Workflow workflowname_reverse, DbName vt_sourcekeyspace
Unlock keyspace sourcekeyspace
Unlock keyspace targetkeyspace
```

### Potential errors or issues during the rollback

1. Timeouts  

If the reverse workflow cannot keep the sourcekeyspace up to date with the targetkeyspace, which is now receiving the application writes, the reverse SwitchWrites may time out.  
If that occurs, you may need to temporarily stop the application writes to allow the sourcekeyspace to catch up to the target keyspace.  
You would then retry the SwitchWrites and then resume the application writes. 
This should not be an issue if the amount of writes to the keyspaces are similar before and after the switchover.

## Clean up of the cutover

### When using -v2 commands

#### After a successful cutover

If the cutover was successful, the MoveTables --Complete command will do the following:

```
vtctlclient -server vtctld.host:15999 MoveTables -dry_run Complete targetkeyspace.workflowname
```

1. Drop the tables involved in the MoveTables in the original keyspace (sourcekeyspace)
2. Remove the workflows related to the MoveTables operation
3. Clean up the routing rules. Applications pointed to the sourcekeyspace will no longer be transparently redirected to the targetkeyspace

#### After a cutover rollback

If a cutover was rolled back via ReverseTraffic, the MoveTables --Cancel command will clean up the targetkeyspace:

```
vtctlclient -server vtctld.host:15999 MoveTables Cancel targetkeyspace.workflowname
```

1. Drop the tables involved in the MoveTables in the new keyspace (targetkeyspace)
2. Remove the workflows related to the MoveTables operation
3. Clean up the routing rules. Applications pointed to the targetkeyspace will no longer be transparently redirected to the sourcekeyspace

### When using -v1 commands

#### After a successful cutover

If the cutover was successful, the DropSources command will do the following:

```
vtctlclient -server vtctld.host:15999 DropSources targetkeyspace.workflowname
```

1. Drop the tables involved in the MoveTables in the original keyspace (sourcekeyspace)
2. Remove the workflows related to the MoveTables operation
3. Clean up the routing rules. Applications pointed to the sourcekeyspace will no longer be transparently redirected to the targetkeyspace

#### After a cutover rollback

If a cutover was rolled back, a DropSources will clean up the targetkeyspace:

```
vtctlclient -server vtctld.host:15999 DropSources sourcekeyspace.workflowname_reverse
```

1. Drop the tables involved in the MoveTables in the new keyspace (targetkeyspace)
2. Remove the workflows related to the MoveTables operation
3. Clean up the routing rules. Applications pointed to the targetkeyspace will no longer be transparently redirected to the sourcekeyspace

{{< info >}}
Note that when rolling back a switchover, Vitess will attempt to revive the original workflow from sourcekeyspace to targetkeyspace.  If the intention is to retry the switchover at some later date, it may not be necessary to delete the original tables/workflow/etc in this fashion.
{{< /info >}}

### Potential errors or issues during the clean up

In certain older Vitess versions, those prior to v10.0, there were issues when cleaning the RoutingRules as part of DropSources. 
We recommend that you save the RoutingRules before and after each cutover and DropSources step. 
This will ensure that they have been appropriately updated. 
If not, you will need to update the RoutingRules manually by editing the RoutingRules JSON blob and then applying the new RoutingRules by using [ApplyRoutingRules](../../../reference/features/schema-routing-rules/#applyroutingrules).

