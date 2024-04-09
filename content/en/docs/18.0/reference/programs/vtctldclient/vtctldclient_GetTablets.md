---
title: GetTablets
series: vtctldclient
commit: b5b3114ab9371f882762dd66ae0efc5af3a3dbc0
---
## vtctldclient GetTablets

Looks up tablets according to filter criteria.

### Synopsis

Looks up tablets according to the filter criteria.

If --tablet-alias is passed, none of the other filters (tablet-type, keyspace,
shard, cell) may be passed, and tablets are looked up by tablet alias only.

If --keyspace is passed, then all tablets in the keyspace are retrieved. The
--shard flag may also be passed to further narrow the set of tablets to that
<keyspace/shard>. Passing --shard without also passing --keyspace will fail.

If --tablet-type is passed, only tablets of the specified type will be
returned. Valid tablet types are:
"backup", "drained", "experimental", "primary", "rdonly", "replica", "restore", "spare".

Passing --cell limits the set of tablets to those in the specified cells. The
--cell flag accepts a CSV argument (e.g. --cell "c1,c2") and may be repeated
(e.g. --cell "c1" --cell "c2").

Valid output formats are "awk" and "json".

```
vtctldclient GetTablets [--strict] [{--cell $c1 [--cell $c2 ...] [--tablet-type $t1] [--keyspace $ks [--shard $shard]], --tablet-alias $alias}]
```

### Options

```
  -c, --cell strings                        List of cells to filter tablets by.
      --format string                       Output format to use; valid choices are (json, awk). (default "awk")
  -h, --help                                help for GetTablets
  -k, --keyspace string                     Keyspace to filter tablets by.
  -s, --shard string                        Shard to filter tablets by.
      --strict                              Require all cells to return successful tablet data. Without --strict, tablet listings may be partial.
  -t, --tablet-alias strings                List of tablet aliases to filter by.
      --tablet-type topodatapb.TabletType   Tablet type to filter by (e.g. primary or replica). (default UNKNOWN)
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

