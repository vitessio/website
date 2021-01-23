---
title: MoveTables
description: Move tables between keyspaces without downtime
weight: 10
---
##### _Experimental_
This documentation is for a new (v2) set of vtctld commands. See [RFC](https://github.com/vitessio/vitess/issues/7225) for more details.

### Command

```
MoveTables  -v2 <options> <action> <workflow identifier>
```

### Description

MoveTables is used to start and manage workflows to move one or more tables from an external database or an existing Vitess keyspace into a new Vitess keyspace. The target keyspace can be unsharded or sharded.

MoveTables is typically used for migrating data into Vitess or to implement vertical sharding. You might use the former when you first start using Vitess and the latter if you want to distribute your load across servers without sharding tables.

### Parameters

#### action

<div class="cmd">

MoveTables is an "umbrella" command. The `action` sub-command defines the operation on the workflow.

</div>

#### options
<div class="cmd">

Each `action` has additional options/parameters that can be used to modify its behavior.

`actions` are common to both MoveTables and Reshard v2 workflows. Only the `create` action has different parameters, all other actions have common options and similar semantics. These actions are documented separately.

</div>

#### workflow identifier

<div class="cmd">

All workflows are identified by `targetKeyspace.workflow` where `targetKeyspace` is the name of the keyspace to which the tables are being moved. `workflow` is a name you assign to the MoveTables workflow to identify it.

</div>


### The most basic MoveTables Workflow lifecycle

1. Initiate the migration using [Create](../create)<br/>
`MoveTables -source=<sourceKs> -tables=<tableSpecs> Create <targetKs.workflow>`
1. Monitor the workflow using [Show](../show) or [Progress](../progress)<br/>
`MoveTables Show <targetKs.workflow>` _*or*_ <br/>
`MoveTables Progress <targetKs.workflow>`<br/>
1. Confirm that data has been copied over correctly using [VDiff](../../vdiff)
1. Cutover to the target keyspace with [SwitchTraffic](../switchtraffic) <br/>
`MoveTables SwitchTraffic <targetKs.workflow>`
1. Cleanup vreplication artifacts and source tables with [Complete](../complete) <br/>
`MoveTables Complete <targetKs.workflow>`


### Common use cases for MoveTables

#### Adopting Vitess

For those wanting to try out Vitess for the first time, MoveTables provides an easy way to route part of their workload
to Vitess with the ability to migrate back at any time without any risk. You point a vttablet to your existing MySQL installation, spin up an unsharded Vitess cluster and use a MoveTables workflow to start serving some tables from Vitess. You can also go further and use a Reshard workflow to experiment with a sharded version of a part of your database.

See [user guide](../../../../../docs/user-guides/configuration-advanced/unmanaged-tablet/#move-legacytable-to-the-commerce-keyspace) for detailed steps

#### Vertical Sharding

For existing Vitess users you can easily move one or more tables to another keyspace, either for balancing load or
as preparation for sharding your tables.

See [user guide](../../../../../docs/user-guides/migration/move-tables/) which describes how MoveTables works in the local example provided in the Vitess repo.

#### More Reading
* [MoveTables in practice](../../../../../docs/concepts/move-tables/)
