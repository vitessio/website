---
title: SetShardTabletControl
series: vtctldclient
commit: b9b567acbb1f36404f46b5daa168d37831dd137f
---
## vtctldclient SetShardTabletControl

Sets the TabletControl record for a shard and tablet type. Only use this for an emergency fix or after a finished MoveTables.

### Synopsis

Sets the TabletControl record for a shard and tablet type.

Only use this for an emergency fix or after a finished MoveTables.

Always specify the denied-tables flag for MoveTables, but never for Reshard operations.

To set the DisableQueryService flag, keep denied-tables empty, and set --disable-query-service
to true or false. This is useful to fix Reshard operations gone wrong.

To change the list of denied tables, specify the --denied-tables parameter with
the new list. This is useful to fix tables that are being blocked after a
MoveTables operation.

To remove the ShardTabletControl record entirely, use the --remove flag. This is
useful after a MoveTables has finished to remove serving restrictions.

```
vtctldclient SetShardTabletControl [--cells=c1,c2...] [--denied-tables=t1,t2,...] [--remove] [--disable-query-service[=0|false]] <keyspace/shard> <tablet_type>
```

### Options

```
  -c, --cells strings           Specifies a comma-separated list of cells to update.
      --denied-tables strings   Specifies a comma-separated list of tables to add to the denylist (for MoveTables). Each table name is either an exact match, or a regular expression of the form '/regexp/'.
      --disable-query-service   Sets the DisableQueryService flag in the specified cells. This flag requires --denied-tables and --remove to be unset; if either is set, this flag is ignored.
  -h, --help                    help for SetShardTabletControl
  -r, --remove                  Removes the specified cells for MoveTables operations.
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

