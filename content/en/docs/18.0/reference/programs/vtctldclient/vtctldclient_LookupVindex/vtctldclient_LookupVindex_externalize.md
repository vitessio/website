---
title: LookupVindex externalize
series: vtctldclient
commit: 9a6f5262f7707ff80ce85c111d2ff686d85d29cc
---
## vtctldclient LookupVindex externalize

Externalize the Lookup Vindex. If the Vindex has an owner the VReplication workflow will also be deleted.

```
vtctldclient LookupVindex externalize
```

### Examples

```
vtctldclient --server localhost:15999 LookupVindex --name corder_lookup_vdx --table-keyspace customer externalize
```

### Options

```
  -h, --help              help for externalize
      --keyspace string   The keyspace containing the Lookup Vindex. If no value is specified then the table-keyspace will be used.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --name string               The name of the Lookup Vindex to create. This will also be the name of the VReplication workflow created to backfill the Lookup Vindex.
      --server string             server to use for the connection (required)
      --table-keyspace string     The keyspace to create the lookup table in. This is also where the VReplication workflow is created to backfill the Lookup Vindex.
```

### SEE ALSO

* [vtctldclient LookupVindex](../)	 - Perform commands related to creating, backfilling, and externalizing Lookup Vindexes using VReplication workflows.

