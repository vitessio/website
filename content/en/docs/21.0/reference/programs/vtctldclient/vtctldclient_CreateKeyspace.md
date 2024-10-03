---
title: CreateKeyspace
series: vtctldclient
commit: 14b6873142558358a99a68d2b5ef0ec204f3776a
---
## vtctldclient CreateKeyspace

Creates the specified keyspace in the topology.

### Synopsis

Creates the specified keyspace in the topology.
	
For a SNAPSHOT keyspace, the request must specify the name of a base keyspace,
as well as a snapshot time.

```
vtctldclient CreateKeyspace <keyspace> [--force|-f] [--type KEYSPACE_TYPE] [--base-keyspace KEYSPACE --snapshot-timestamp TIME] [--served-from DB_TYPE:KEYSPACE ...] [--durability-policy <policy_name>] [--sidecar-db-name <db_name>]
```

### Options

```
  -e, --allow-empty-vschema         Allows a new keyspace to have no vschema.
      --base-keyspace string        The base keyspace for a snapshot keyspace.
      --durability-policy string    Type of durability to enforce for this keyspace. Default is none. Possible values include 'semi_sync' and others as dictated by registered plugins. (default "none")
  -f, --force                       Proceeds even if the keyspace already exists. Does not overwrite the existing keyspace record.
  -h, --help                        help for CreateKeyspace
      --sidecar-db-name string      (Experimental) Name of the Vitess sidecar database that tablets in this keyspace will use for internal metadata. (default "_vt")
      --snapshot-timestamp string   The snapshot time for a snapshot keyspace, as a timestamp in RFC3339 format.
      --type cli.KeyspaceTypeFlag   The type of the keyspace. (default NORMAL)
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

