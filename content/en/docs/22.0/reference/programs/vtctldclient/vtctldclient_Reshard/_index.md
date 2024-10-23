---
title: Reshard
series: vtctldclient
commit: b0b79813f21f8ecbf409f558ad6f8864332637cf
---
## vtctldclient Reshard

Perform commands related to resharding a keyspace.

### Options

```
      --format string            The format of the output; supported formats are: text,json. (default "text")
  -h, --help                     help for Reshard
      --target-keyspace string   Target keyspace for this workflow.
  -w, --workflow string          The workflow you want to perform the command on.
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
* [vtctldclient Reshard cancel](./vtctldclient_reshard_cancel/)	 - Cancel a Reshard VReplication workflow.
* [vtctldclient Reshard complete](./vtctldclient_reshard_complete/)	 - Complete a Reshard VReplication workflow.
* [vtctldclient Reshard create](./vtctldclient_reshard_create/)	 - Create and optionally run a Reshard VReplication workflow.
* [vtctldclient Reshard reversetraffic](./vtctldclient_reshard_reversetraffic/)	 - Reverse traffic for a Reshard VReplication workflow.
* [vtctldclient Reshard show](./vtctldclient_reshard_show/)	 - Show the details for a Reshard VReplication workflow.
* [vtctldclient Reshard start](./vtctldclient_reshard_start/)	 - Start a Reshard workflow.
* [vtctldclient Reshard status](./vtctldclient_reshard_status/)	 - Show the current status for a Reshard VReplication workflow.
* [vtctldclient Reshard stop](./vtctldclient_reshard_stop/)	 - Stop a Reshard workflow.
* [vtctldclient Reshard switchtraffic](./vtctldclient_reshard_switchtraffic/)	 - Switch traffic for a Reshard VReplication workflow.

