---
title: CreateKeyspace
series: vtctldclient
---
## vtctldclient CreateKeyspace

Creates the specified keyspace in the topology.

### Synopsis

Creates the specified keyspace in the topology.
	
For a SNAPSHOT keyspace, the request must specify the name of a base keyspace,
as well as a snapshot time.

```
vtctldclient CreateKeyspace <keyspace> [--force|-f] [--type KEYSPACE_TYPE] [--base-keyspace KEYSPACE --snapshot-timestamp TIME] [--served-from DB_TYPE:KEYSPACE ...]  [--durability-policy <policy_name>]
```

### Options

```
  -e, --allow-empty-vschema              Allows a new keyspace to have no vschema.
      --base-keyspace string             The base keyspace for a snapshot keyspace.
      --durability-policy string         Type of durability to enforce for this keyspace. Default is none. Possible values include 'semi_sync' and others as dictated by registered plugins. (default "none")
  -f, --force                            Proceeds even if the keyspace already exists. Does not overwrite the existing keyspace record.
  -h, --help                             help for CreateKeyspace
      --served-from cli.StringMapValue   Specifies a set of db_type:keyspace pairs used to serve traffic for the keyspace.
      --snapshot-timestamp string        The snapshot time for a snapshot keyspace, as a timestamp in RFC3339 format.
      --type cli.KeyspaceTypeFlag        The type of the keyspace. (default NORMAL)
```

### Options inherited from parent commands

```
      --action_timeout duration           timeout for the total command (default 1h0m0s)
      --emit_stats                        If set, emit stats to push-based monitoring and stats backends
      --server string                     server to use for connection (required)
      --stats_backend string              The name of the registered push-based monitoring/stats backend to use
      --stats_combine_dimensions string   List of dimensions to be combined into a single "all" value in exported stats vars
      --stats_common_tags strings         Comma-separated list of common tags for the stats backend. It provides both label and values. Example: label1:value1,label2:value2
      --stats_drop_variables string       Variables to be dropped from the list of exported variables.
      --stats_emit_period duration        Interval between emitting stats to all registered backends (default 1m0s)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

