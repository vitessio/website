---
title: LookupVindex create
series: vtctldclient
commit: 7e8f008834c0278b8df733d606940a629b67a9d9
---
## vtctldclient LookupVindex create

Create the Lookup Vindex in the specified keyspace and backfill it with a VReplication workflow.

```
vtctldclient LookupVindex create
```

### Examples

```
vtctldclient --server localhost:15999 LookupVindex --name corder_lookup_vdx --table-keyspace customer create --keyspace customer --type consistent_lookup_unique --table-owner corder --table-owner-columns sku --table-name corder_lookup_tbl --table-vindex-type unicode_loose_xxhash
```

### Options

```
      --cells strings                      Cells to look in for source tablets to replicate from.
      --continue-after-copy-with-owner     Vindex will continue materialization after the backfill completes when an owner is provided. (default true)
  -h, --help                               help for create
      --ignore-nulls                       Do not add corresponding records in the lookup table if any of the owner table's 'from' fields are NULL.
      --keyspace string                    The keyspace to create the Lookup Vindex in. This is also where the table-owner must exist.
      --table-name string                  The name of the lookup table. If not specified, then it will be created using the same name as the Lookup Vindex.
      --table-owner string                 The table holding the data which we should use to backfill the Lookup Vindex. This must exist in the same keyspace as the Lookup Vindex.
      --table-owner-columns strings        The columns to read from the owner table. These will be used to build the hash which gets stored as the keyspace_id value in the lookup table.
      --table-vindex-type string           The primary vindex name/type to use for the lookup table, if the table-keyspace is sharded. If no value is provided then the default type will be used based on the table-owner-columns types.
      --tablet-types strings               Source tablet types to replicate from.
      --tablet-types-in-preference-order   When performing source tablet selection, look for candidates in the type order as they are listed in the tablet-types flag. (default true)
      --type string                        The type of Lookup Vindex to create.
```

### Options inherited from parent commands

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --name string                          The name of the Lookup Vindex to create. This will also be the name of the VReplication workflow created to backfill the Lookup Vindex.
      --server string                        server to use for the connection (required)
      --table-keyspace string                The keyspace to create the lookup table in. This is also where the VReplication workflow is created to backfill the Lookup Vindex.
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### SEE ALSO

* [vtctldclient LookupVindex](../)	 - Perform commands related to creating, backfilling, and externalizing Lookup Vindexes using VReplication workflows.

