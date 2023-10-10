---
title: LookupVindex show
series: vtctldclient
commit: e73ce917ed97a6a8586cd3647cb2f498fe908a0e
---
## vtctldclient LookupVindex show

Show the status of the VReplication workflow that backfills the Lookup Vindex.

```
vtctldclient LookupVindex show
```

### Examples

```
vtctldclient --server localhost:15999 LookupVindex --name corder_lookup_vdx --table-keyspace customer show
```

### Options

```
  -h, --help   help for show
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --name string               The name of the Lookup Vindex to create. This will also be the name of the VReplication workflow created to backfill the Lookup Vindex.
      --server string             server to use for connection (required)
      --table-keyspace string     The keyspace to create the lookup table in. This is also where the VReplication workflow is created to backfill the Lookup Vindex.
```

### SEE ALSO

* [vtctldclient LookupVindex](../)	 - Perform commands related to creating, backfilling, and externalizing Lookup Vindexes using VReplication workflows.

