---
title: Migrate
description: Move tables from an external cluster
weight: 85
---

{{< info >}}
This documentation is for a new (v2) set of vtctld commands that start in Vitess 11.0. See [RFC](https://github.com/vitessio/vitess/issues/7225) for more details.
{{< /info >}}

### Command

```
Migrate <options> <action> <workflow identifier>
```


### Description

Migrate is used to start and manage vReplication workflows for copying keyspaces and/or tables from a source Vitess cluster, to a target Vitess cluster.
This command is built off of [MoveTables](../movetables) but has been extended to work with source and target topology services. It should be 
utilized when moving Keyspaces or Tables between two separate Vitess environments. Migrate is an advantageous strategy for large sharded environments
for a few reasons:

* Data can be migrated while the source Vitess cluster, typically the production environment, continues to serve traffic.
* Shard mapping between Source and Target Vitess clusters is handled automatically by Migrate.
    * Similar to MoveTables, you may have different shard counts between the source and target Vitess clusters.
* VDiffs and read-only SQL can be performed to verify data integrity before the Migration completes.
* Migrate works as a copy of data not a move, source data remains once the Migrate completes.
* Could be used for configuring lower environments with production data.

Please note the Migrate command works with an externally mounted source cluster. See the related [Mount command](../mount) for more information
on external Vitess clusters.

#### Differences between Migrate and MoveTables

Migrate has separate semantics and behaviors from MoveTables:

* MoveTables migrates data from one keyspace to another, within the same Vitess cluster; Migrate functions between two separated Vitess clusters. 
* MoveTables erases the source data upon completion by default; Migrate keeps the source data intact.
    * There are flags available in MoveTables to change the default behavior in regards to the source data.
* MoveTables sets up routing rules and reverse replication, allowing for rollback prior to completion.
    * Switching read/write traffic is not meaningful in the case of Migrate, as the Source is in a different cluster.
    * Switching traffic requires the Target to have the ability to create vreplication streams (in the _vt database) on the Source;
      this may not always be possible on production systems.
* Not all MoveTables options work with Migrate; for example [Progress](../progress) is unavailable with Migrate. 


### Parameters

#### action

Migrate is an "umbrella" command. The `action` sub-command defines the operation on the workflow.
The only actions supported by Migrate are `Create`, `Complete` and `Cancel`.

The `Create` action is also modified to accommodate the external mount. The proper syntax will be highlighted below:

```
Migrate <options> -source <mount name>.<source keyspace> Create <workflow identifier>
```

If needed, you can rename the keyspace while migrating, simply provide a different name for the target keyspace in the `<workflow identifier>`. 


#### options

Each `action` has additional options/parameters that can be used to modify its behavior.

The options for the supported commands are the same as [MoveTables](../movetables), with the exception of `reverse_replication`.

A common option to give if migrating all of the tables from a source keyspace is the `-all` option.


#### workflow identifier

All workflows are identified by `targetKeyspace.workflow` where `targetKeyspace` is the name of the keyspace to which the tables are being moved. `workflow` is a name you assign to the Migrate workflow to identify it.



### A Migrate Workflow lifecycle

{{< info >}}
NOTE: there is no reverse replication flow with Migrate. After the `Migrate Complete` command is given; no writes will be replicated between the Source and Target Vitess clusters. They are essentially two identical Vitess clusters running in two different environments. Once writing resumes on one of the clusters they will begin to drift apart. 
{{< /info >}}

1. Mount the source Vitess cluster using [Mount](../mount).<br/>
`Mount -type vitess -topo_type etcd2 -topo_server localhost:12379 -topo_root /vitess/global ext1`
1. Apply source vSchema to the Target's Keyspace.<br/>
`ApplyVSchema -vschema_file commerceVschema.json commerce`
1. Initiate the migration using [Create](../create).<br/>
`Migrate -all -source ext1.commerce Create commerce.wf`
1. Monitor the workflow using [Show](../show).<br/>
`Workflow commerce.wf Show`
1. Confirm that data has been copied over correctly using [VDiff](../vdiff).<br/>
`VDiff commerce.wf`
1. Stop the application from writing to the source Vitess cluster.<br/>
1. Confirm again the data has been copied over correctly using [VDiff](../vdiff).<br/>
`VDiff commerce.wf`
1. Cleanup vreplication artifacts and source tables with [Complete](../complete).<br />
`Migrate Complete commerce.wf`
1. Start the application pointed to the target Vitess Cluster.
1. Unmount the source cluster.<br/>
`Mount -unmount ext1`


### Network Considerations

For Migrate to function properly, you will need to ensure communication is possible between the target Vitess cluster and the source Vitess cluster. At a minimum the following network concerns must be implemented:

* Target vtctld/vttablet (PRIMARY) processes must reach the Source topo service.
* Target vtctld/vttablet (PRIMARY) processes must reach EACH source vttablet's grpc port.
    * You can limit your source vttablet's to just the replicas by using the `-tablet_types` option when creating the migration. 

If you're migrating a keyspace from a production system, you may want to target a replica to reduce your load on the primary vttablets. This will also assist you in reducing the number of network considerations you need to make. 

```
Migrate -all -tablet_types "REPLICA" -source <mount name>.<source keyspace> Create <workflow identifier>
```

To verify the Migration you can also perform VDiff with the `-tablet_types` option:

```
VDiff -tablet_types "REPLICA"  <target keyspace>.<workflow identifier>
```

### Troubleshooting Errors

Migrate fails right away with error:

```sh
E0224 23:51:45.312536     138 main.go:76] remote error: rpc error: code = Unknown desc = table table1 not found in vschema for keyspace sharded
```
<br />Solution:
* The target table has a vSchema which does not match the source vSchema
* Upload the source vSchema to the target vSchema and try the migrate again

---

Migrate fails right away with error:

```sh
E0224 18:55:29.275019     578 main.go:76] remote error: rpc error: code = Unknown desc = node doesn't exist
```

<br />Solution:
* Ensure there is networking communication between Target vtctld and Source topology
* Ensure the topology information is correct on the `Mount` command

---

After issuing Migrate command everything is stuck at 0% progress 
with errors found in target vttablet logs:

```sh
I0223 20:13:36.825110       1 tablet_picker.go:146] No tablet found for streaming
```

<br />Solution:
* Ensure there is networking communication between Target vttablets and Source vttablets
* Ensure there is networking communication between Target vttablets and the Source topology service
* Older versions of Vitess may be labeling vttablets as "master" instead of "primary"
  you can resolve this problem by adjusting your `tablet_types`:

      Migrate -all -tablet_types "MASTER,REPLICA,RDONLY" ...

---

The MySQL client fails with:

```sh
SQL error, errno = 1105, state = 'HY000': table 'table_name' does not have a primary vindex
```

<br />Solution:

* The write was sent to the Target Vitess cluster before the migration completed,
  solvable by writing to the source instead, or by completing the migration.