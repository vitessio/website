---
title: Migrate
description: Move tables from an external cluster
weight: 85
---
##### _Experimental_
This documentation is for a new (v2) set of vtctld commands. See [RFC](https://github.com/vitessio/vitess/issues/7225) for more details.

### Command

```
Migrate <options> <action> <workflow identifier>
```

### Description

Migrate is used to start and manage workflows to move one or more tables from an external cluster into a new Vitess keyspace. The target keyspace can be unsharded or sharded.

Migrate is typically used for migrating data into Vitess from an external cluster. See [Mount command](../mount) for more information on external clusters.

### Parameters

#### action

<div class="cmd">

Migrate is an "umbrella" command. The `action` sub-command defines the operation on the workflow.
The only actions supported by Migrate are Create, Complete and Cancel.

</div>

#### options
<div class="cmd">

Each `action` has additional options/parameters that can be used to modify its behavior.

The options for the supported commands are the same as for `MoveTables`.

</div>

#### workflow identifier

<div class="cmd">

All workflows are identified by `targetKeyspace.workflow` where `targetKeyspace` is the name of the keyspace to which the tables are being moved. `workflow` is a name you assign to the MoveTables workflow to identify it.

</div>


### A Migrate Workflow lifecycle

1. Mount the external cluster using [Mount](../mount)<br/>
`Mount -type vitess -topo_type etcd2 -topo_server localhost:12379 -topo_root /vitess/global ext1`
1. Initiate the migration using [Create](../create)<br/>
`Migrate -all -source ext1.load Create commerce.wf`
1. Monitor the workflow using [Show](../show)<br/>
`Workflow Show commerce.wf`
1. Confirm that data has been copied over correctly using [VDiff](../vdiff)
1. Cleanup vreplication artifacts and source tables with [Complete](../complete) <br/>
`Migrate Complete commerce.wf`


#### Differences between MoveTables and Migrate

MoveTables has separate semantics than Migrate. MoveTables can migrate data from one keyspace to another, but both keyspaces need to be in the same Vitess Cluster. Migrate is intended as a one-way copy whereas MoveTables allows you to serve either data from the source or target keyspace and switch between each other until you finalize MoveTables.

* MoveTables sets up routing rules so that Vitess routes queries to the Source keyspace until a cutover
* While switching Write traffic, in MoveTables, is possible to set up a reverse replication workflow so that the Source can be in sync with the Target, allowing you to revert back to the Source.

However this requires that the Target can create vreplication streams (in the \_vt database) on the Source database. This may not be always possible, for example, if the Source is a production system.

* In MoveTables the tables already exist, just in a different keyspace. So the VSchema already contains these tables. While migrating, these tables will be available only after the Migrate is completed
* Switching traffic is not meaningful in the case of Migrate since there is no query traffic to the original tables, as the Source is in a different cluster.
