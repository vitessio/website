---
title: LookupVindex
series: vtctldclient
commit: b9b567acbb1f36404f46b5daa168d37831dd137f
---
## vtctldclient LookupVindex

Perform commands related to creating, backfilling, and externalizing Lookup Vindexes using VReplication workflows.

### Options

```
  -h, --help                    help for LookupVindex
      --name string             The name of the Lookup Vindex to create. This will also be the name of the VReplication workflow created to backfill the Lookup Vindex.
      --table-keyspace string   The keyspace to create the lookup table in. This is also where the VReplication workflow is created to backfill the Lookup Vindex.
```

### Options inherited from parent commands

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.
* [vtctldclient LookupVindex cancel](./vtctldclient_lookupvindex_cancel/)	 - Cancel the VReplication workflow that backfills the Lookup Vindex.
* [vtctldclient LookupVindex create](./vtctldclient_lookupvindex_create/)	 - Create the Lookup Vindex in the specified keyspace and backfill it with a VReplication workflow.
* [vtctldclient LookupVindex externalize](./vtctldclient_lookupvindex_externalize/)	 - Externalize the Lookup Vindex. If the Vindex has an owner the VReplication workflow will also be deleted.
* [vtctldclient LookupVindex show](./vtctldclient_lookupvindex_show/)	 - Show the status of the VReplication workflow that backfills the Lookup Vindex.

