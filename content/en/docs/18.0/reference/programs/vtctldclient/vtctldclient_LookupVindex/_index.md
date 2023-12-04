---
title: LookupVindex
series: vtctldclient
commit: 9a6f5262f7707ff80ce85c111d2ff686d85d29cc
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
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.
* [vtctldclient LookupVindex cancel](./vtctldclient_lookupvindex_cancel/)	 - Cancel the VReplication workflow that backfills the Lookup Vindex.
* [vtctldclient LookupVindex create](./vtctldclient_lookupvindex_create/)	 - Create the Lookup Vindex in the specified keyspace and backfill it with a VReplication workflow.
* [vtctldclient LookupVindex externalize](./vtctldclient_lookupvindex_externalize/)	 - Externalize the Lookup Vindex. If the Vindex has an owner the VReplication workflow will also be deleted.
* [vtctldclient LookupVindex show](./vtctldclient_lookupvindex_show/)	 - Show the status of the VReplication workflow that backfills the Lookup Vindex.

