---
title: SetKeyspaceDurabilityPolicy
series: vtctldclient
commit: a7f80a82e5d99cf00c253c3902367bec5fa40e5d
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

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

