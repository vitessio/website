---
title: LookupVindex show
series: vtctldclient
commit: 5cb66a1797a17c05b447acda5f923c62e5912b27
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

* [vtctldclient LookupVindex](./vtctldclient_lookupvindex/)	 - Perform commands related to creating, backfilling, and externalizing Lookup Vindexes using VReplication workflows.

