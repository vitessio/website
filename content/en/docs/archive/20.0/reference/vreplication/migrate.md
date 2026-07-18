---
title: Migrate
description: Move tables from an external cluster
weight: 85
---

### Description

[`Migrate`](../../programs/vtctldclient/vtctldclient_migrate/) is used to start and manage VReplication workflows for copying keyspaces and/or tables from a source Vitess cluster, to a target Vitess cluster.
This command is built off of [`MoveTables`](../movetables) but has been extended to work with independent source and target topology services. It should be 
utilized when moving Keyspaces or Tables between two separate Vitess environments. Migrate is an advantageous strategy for large sharded environments
for a few reasons:

* Data can be migrated while the source Vitess cluster, typically the production environment, continues to serve traffic.
* Shard mapping between Source and Target Vitess clusters is handled automatically by Migrate.
    * Similar to MoveTables, you may have different shard counts between the source and target Vitess clusters.
* VDiffs and read-only SQL can be performed to verify data integrity before the Migration completes.
* Migrate works as a copy of data not a move, source data remains once the Migrate completes.
* Could be used for configuring lower environments with production data.

Please note the Migrate command works with an externally mounted source cluster. See the related [Mount command](../mount) for more information
on working with external Vitess clusters.

#### Differences Between Migrate and MoveTables

[`Migrate`](../../programs/vtctldclient/vtctldclient_migrate/) has separate semantics and behaviors from [`MoveTables`](../../programs/vtctldclient/vtctldclient_movetables/):

* [`MoveTables`](../../programs/vtctldclient/vtctldclient_movetables/) migrates data from one keyspace to another, within the same Vitess cluster; [`Migrate`](../../programs/vtctldclient/vtctldclient_migrate/) functions between two separate Vitess clusters.
* [`MoveTables`](../../programs/vtctldclient/vtctldclient_movetables/) erases the source data upon completion by default; Migrate keeps the source data intact.
    * There are flags available in [`MoveTables`](../../programs/vtctldclient/vtctldclient_movetables/) to change the default behavior in regards to the source data.
* [`MoveTables`](../../programs/vtctldclient/vtctldclient_movetables/) sets up routing rules and reverse replication, allowing for rollback prior to completion.
    * Switching read/write traffic is not meaningful in the case of [`Migrate`](../../programs/vtctldclient/vtctldclient_migrate/), as the Source is in a different cluster.
    * Switching traffic requires the Target to have the ability to create vreplication streams (in the `_vt` database) on the Source;
      this may not always be possible on production systems.
* Not all [`MoveTables`](../../programs/vtctldclient/vtctldclient_movetables/) sub-commands work with [`Migrate`](../../programs/vtctldclient/vtctldclient_migrate/); for example `SwitchTraffic` and `ReverseTraffic` are unavailable with [`Migrate`](../../programs/vtctldclient/vtctldclient_migrate/).

## Command

Please see the [`Migrate` command reference](../../programs/vtctldclient/vtctldclient_migrate/) for a full list of sub-commands and their flags.

### An Example Migrate Workflow Lifecycle

{{< info >}}
NOTE: there is no reverse vreplication flow with [`Migrate`](../../programs/vtctldclient/vtctldclient_migrate/). After the [`Migrate complete`](../../programs/vtctldclient/vtctldclient_migrate/vtctldclient_migrate_complete/) command is given; no writes will be replicated between the Source and Target Vitess clusters. They are essentially two identical Vitess clusters running in two different environments. Once writing resumes on one of the clusters they will begin to drift apart. 
{{< /info >}}

1. Mount the source Vitess cluster using [Mount](../mount).<br/>
`Mount register --name ext1 --topo-type etcd2 --topo-server localhost:12379 --topo-root /vitess/global`
1. Apply source vSchema to the Target's Keyspace.<br/>
`ApplyVSchema --vschema-file commerceVschema.json commerce`
1. Initiate the migration using `create`.<br/>
`Migrate --workflow import --target-keyspace customer create --source-keyspace commerce --mount-name ext1 --tablet-types replica`
1. Monitor the workflow using `show` and `status`.<br/>
`Migrate --workflow import --target-keyspace customer show`
`Migrate --workflow import --target-keyspace customer status`
1. Confirm that data has been copied over correctly using [VDiff](../vdiff).<br/>
1. Stop the application from writing to the source Vitess cluster.<br/>
1. Confirm again the data has been copied over correctly using [VDiff](../vdiff).<br/>
1. Cleanup vreplication artifacts and source tables with `complete`.<br />
`Migrate --workflow import --target-keyspace customer complete`
1. Start the application pointed to the target Vitess Cluster.
1. Unmount the source cluster.<br/>
`Mount unregister --name ext1`

### Parameters

### Action

[`Migrate`](../../programs/vtctldclient/vtctldclient_migrate/) is an "umbrella" command. The [`action` or sub-command](../../programs/vtctldclient/vtctldclient_migrate/#see-also) defines the operation on the workflow.

### Options

Each [`action` or sub-command](../../programs/vtctldclient/vtctldclient_migrate/#see-also) has additional options/parameters that can be used to modify its behavior. Please see the [command's reference docs](../../programs/vtctldclient/vtctldclient_migrate/) for the full list of command options or flags.

The options for the supported commands are the same as [MoveTables](../movetables), with the exception of `--enable-reverse-replication` as setting
up the reverse vreplication streams requires modifying the source cluster's `_vt` sidecar database which we cannot do as that database is
specific to a single Vitess cluster and these streams belong to a different one (the target cluster).

A common option to give if migrating all of the tables from a source keyspace is the `--all-tables` option.

### Network Considerations

For Migrate to function properly, you will need to ensure communication is possible between the target Vitess cluster and the source Vitess cluster. At a minimum the following network concerns must be implemented:

* Target vtctld/vttablet (PRIMARY) processes must reach the Source topo service.
* Target vtctld/vttablet (PRIMARY) processes must reach EACH source vttablet's grpc port.
    * You can limit your source vttablet's to just the replicas by using the `--tablet-types` option when creating the migration. 

If you're migrating a keyspace from a production system, you may want to target a replica to reduce your load on the primary vttablets. This will also assist you in reducing the number of network considerations you need to make. 

```
Migrate --workflow <workflow> --target-keyspace <target-keysapce> create --source-keyspace <source-keyspace> --mount-name <mount-name> --tablet-types replica
```

To verify the Migration you can also perform VDiff with the `--tablet-types` option:

```
VDiff --workflow <workflow> --target-keyspace <target-keyspace> create --tablet-types REPLICA  
```

### Troubleshooting Errors

`Migrate` fails right away with error:

```shell
E0224 23:51:45.312536     138 main.go:76] remote error: rpc error: code = Unknown desc = table table1 not found in vschema for keyspace sharded
```
<br />Solution:
* The target table has a VSchema which does not match the source VSchema
* Upload the source VSchema to the target VSchema and try the `Migrate` again

---

`Migrate` fails right away with error:

```shell
E0224 18:55:29.275019     578 main.go:76] remote error: rpc error: code = Unknown desc = node doesn't exist
```

<br />Solution:
* Ensure there is networking communication between Target vtctld and Source topology
* Ensure the topology information is correct on the `Mount` command

---

After issuing `Migrate` command everything is stuck at 0% progress 
with errors found in target vttablet logs:

```shell
I0223 20:13:36.825110       1 tablet_picker.go:146] No tablet found for streaming
```

<br />Solution:
* Ensure there is networking communication between Target vttablets and Source vttablets
* Ensure there is networking communication between Target vttablets and the Source topology service
* Older versions of Vitess may be labeling vttablets as "master" instead of "primary"
  you can resolve this problem by adjusting your `tablet-types`:

      Migrate ... create --tablet-types "MASTER,REPLICA,RDONLY" ...

---

The MySQL client fails with:

```sh
SQL error, errno = 1105, state = 'HY000': table 'table_name' does not have a primary vindex
```

<br />Solution:

* The write was sent to the Target Vitess cluster before the migration completed,
  solvable by writing to the source instead, or by completing the migration.
