---
title: SetKeyspaceDurabilityPolicy
series: vtctldclient
commit: cd0c2b594b2d5178a9c8ac081eaee7d1b7eef28a
---

## vtctldclient SetKeyspaceDurabilityPolicy

Sets the durability-policy used by the specified keyspace.

### Synopsis

Sets the durability-policy used by the specified keyspace. 
Durability policy governs the durability of the keyspace by describing which tablets should be sending semi-sync acknowledgements to the primary.
Possible values include 'semi_sync', 'none' and others as dictated by registered plugins.

To set the durability policy of customer keyspace to semi_sync, you would use the following command:
SetKeyspaceDurabilityPolicy --durability-policy='semi_sync' customer

```
vtctldclient SetKeyspaceDurabilityPolicy [--durability-policy=policy_name] <keyspace name>
```

### Options

```
      --durability-policy string   Type of durability to enforce for this keyspace. Default is none. Other values include 'semi_sync' and others as dictated by registered plugins. (default "none")
  -h, --help                       help for SetKeyspaceDurabilityPolicy
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

