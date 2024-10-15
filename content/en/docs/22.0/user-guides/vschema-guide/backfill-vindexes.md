---
title: Backfill Lookup Vindexes
weight: 11
---

Creating a Lookup Vindex after the main table already contains rows does not automatically backfill the lookup table for the existing entries.
Only newer inserts cause automatic population of the lookup table.

This backfill can be set up using the [LookupVindex create](../../../reference/programs/vtctldclient/vtctldclient_lookupvindex/vtctldclient_lookupvindex_create/) command covered below.

### Manual Backfill Checklist

Creating a unique Lookup Vindex is an elaborate process. It is good to use the following checklist if this is done manually:

* Create the lookup table as sharded or unsharded. Make the `from` column the primary key.
* Create a VSchema entry for the lookup table. If sharded, assign a Primary Vindex for the `from` column.
* Create the lookup vindex in the VSchema of the sharded keyspace:
  * Give it a distinct name
  * Specify the type from one of [predefined vindexes](../../../reference/features/vindexes/#predefined-vindexes)
  * Under `params`: specify the properties of the lookup table
  * Specify the `Owner` as the main table
* Associate the column of the owner table with the new Vindex.

### Creating a Lookup Vindex

vtctldclient supports the [LookupVindex create](../../../reference/programs/vtctldclient/vtctldclient_lookupvindex/vtctldclient_lookupvindex_create/) command that can perform all the above steps as well as the backfill.

{{< warning >}}
This will not work against the `vtcombo` based demo app because it does not support vreplication. You can only try this against a real Vitess cluster.
{{< /warning >}}

The workflow automatically infers the schema and vschema for the lookup table and creates it. It also sets up the necessary VReplication streams to backfill the lookup table.

After the backfill is done, you should clean up the workflow. More detailed instructions are available in the  [Creating a Lookup Vindex Guide](../../configuration-advanced/createlookupvindex)

To create such a lookup vindex on a real Vitess cluster, you can use the following instructions:

#### Unique Lookup Vindex Example

*Continued from [Unique Lookup Vindex Page](../unique-lookup)*

Issue the `vtctldclient` command:

```bash
vtctldclient --server localhost:15999 LookupVindex --name corder_keyspace --table-keyspace product create --keyspace product --type consistent_lookup_unique --table-owner corder --table-owner-columns corder_id --tablet-types=PRIMARY
```

The workflow will automatically create the necessary Primary Vindex entries for vindex table `corder_keyspace` knowing that it is sharded.

#### Non-unique Lookup Vindex Example

*Continued from [Non-unique Lookup Vindex Page](../non-unique-lookup)*

Issue the `vtctldclient` command:

```bash
vtctldclient --server localhost:15999 LookupVindex --name oname_keyspace --table-keyspace customer create --keyspace customer --type consistent_lookup --table-owner corder --table-owner-columns 'oname,corder_id' --tablet-types=PRIMARY
```

The workflow will automatically create the necessary Primary Vindex entries for vindex table `oname_keyspace` knowing that it is sharded.
