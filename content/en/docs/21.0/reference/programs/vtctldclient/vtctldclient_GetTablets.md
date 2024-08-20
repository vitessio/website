---
title: GetTablets
series: vtctldclient
commit: cd0c2b594b2d5178a9c8ac081eaee7d1b7eef28a
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

### Options Inherited from Parent Commands

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### See Also

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

