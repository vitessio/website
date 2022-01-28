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

Migrate is used to start and manage workflows to move one or more tables from an external cluster into a new Vitess keyspace. The target keyspace can be unsharded or sharded.

Migrate is typically used for migrating data into Vitess from an external cluster. See [Mount command](../mount) for more information on external clusters.


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


### Differences between MoveTables and Migrate

MoveTables has separate semantics than Migrate. MoveTables can migrate data from one keyspace to another, but both keyspaces need to be in the same Vitess Cluster. Migrate is intended as a one-way copy whereas MoveTables allows you to serve either data from the source or target keyspace and switch between each other until you finalize MoveTables.

* MoveTables sets up routing rules so that Vitess routes queries to the Source keyspace until a cut over.
* While switching Write traffic, in MoveTables, is possible to set up a reverse replication workflow so that the Source can be in sync with the Target, allowing you to revert back to the Source.

However this requires that the Target can create vreplication streams (in the \_vt database) on the Source database. This may not be always possible, for example, if the Source is a production system.

* In MoveTables the tables already exist, just in a different keyspace. So the VSchema already contains these tables. While migrating, these tables will be available only after the Migrate is completed.
* Switching traffic is not meaningful in the case of Migrate since there is no query traffic to the original tables, as the Source is in a different cluster.


### A Migrate Workflow lifecycle

1. Mount the external cluster using [Mount](../mount).<br/>
`Mount -type vitess -topo_type etcd2 -topo_server localhost:12379 -topo_root /vitess/global ext1`
1. Initiate the migration using [Create](../create).<br/>
`Migrate -all -source ext1.commerce Create commerce.wf`
1. Monitor the workflow using [Show](../show).<br/>
`Workflow commerce.wf Show`
1. Confirm that data has been copied over correctly using [VDiff](../vdiff).<br/>
`VDiff commerce.wf`
1. Stop the application from writing to the source Vitess cluster.<br/>

{{< info >}}
This is important as there is no reverse replication flow with Migrate. Any writes to the source Vitess cluster performed after the migration completes will not be carried over to the target Vitess Cluster. 
{{< /info >}}

1. Confirm again the data has been copied over correctly using [VDiff](../vdiff).<br/>
`VDiff commerce.wf`
1. Cleanup vreplication artifacts and source tables with [Complete](../complete).<br/>
`Migrate Complete commerce.wf`
1. Migrate over relevant vSchema from the source Vitess cluster.<br/>
`ApplyVSchema -vschema_file commerceVschema.json commerce`
1. Validate migration and Start the application pointed to the target Vitess Cluster
1. Unmount the external cluster<br/>
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
