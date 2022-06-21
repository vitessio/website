---
title: Backfill Lookup Vindexes
weight: 11
---

Creating a lookup vindex after the main table already contains rows does not automatically backfill the lookup table for the existing entries. 
Only newer inserts cause automatic population of the lookup table. 

This backfill can be set up using the `CreateLookupVindex` command covered below.

### Checklist

Creating a unique lookup Vindex is an elaborate process. It is good to use the following checklist if this is done manually:

* Create the lookup table as sharded or unsharded. Make the `from` column the primary key.
* Create a VSchema entry for the lookup table. If sharded, assign a Primary Vindex for the `from` column.
* Create the lookup vindex in the VSchema of the sharded keyspace:
  * Give it a distinct name
  * Specify the type as `consistent_lookup_unique`
  * Under `params`: specify the properties of the lookup table
  * Specify the `Owner` as the main table
* Associate the column of the owner table with the new Vindex.

### CreateLookupVindex command

vtctld supports the [CreateLookupVindex](../../configuration-advanced/createlookupvindex) command that can perform all the above steps as well as the backfill.

{{< warning >}}
This will not work against the `vtcombo` based demo app because it does not support vreplication. You can only try this against a real Vitess cluster.
{{< /warning >}}

Save the following json into a file, say `corder_keyspace_idx.json`:

```json
{
  "sharded": true,
  "vindexes": {
    "corder_keyspace_idx": {
      "type": "consistent_lookup_unique",
      "params": {
        "table": "product.corder_keyspace_idx",
        "from": "corder_id",
        "to": "keyspace_id"
      },
      "owner": "corder"
    }
  },
  "tables": {
    "corder": {
      "column_vindexes": [{
          "column": "corder_id",
          "name": "corder_keyspace_idx"
      }],
    }
  }
}
```

And issue the vtctlclient command:

```sh
$ vtctlclient -server <vtctld_grpc_address> CreateLookupVindex -tablet_types=REPLICA customer "$(cat corder_keyspace_idx.json)"
```

The workflow automatically infers the schema and vschema for the lookup table and creates it. It also sets up the necessary VReplication streams to backfill the lookup table.

After the backfill is done, you should clean up the workflow. More detailed instructions are available in the  [CreateLookupVindex Reference](../../configuration-advanced/createlookupvindex)
