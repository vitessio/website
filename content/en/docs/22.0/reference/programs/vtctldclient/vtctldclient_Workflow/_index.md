---
title: Workflow
series: vtctldclient
commit: 14b6873142558358a99a68d2b5ef0ec204f3776a
---
## vtctldclient Workflow

Administer VReplication workflows (Reshard, MoveTables, etc) in the given keyspace.

```
vtctldclient Workflow --keyspace <keyspace> [command] [command-flags]
```

### Options

```
  -h, --help              help for Workflow
  -k, --keyspace string   Keyspace context for the workflow.
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
* [vtctldclient Workflow delete](./vtctldclient_workflow_delete/)	 - Delete a VReplication workflow.
* [vtctldclient Workflow list](./vtctldclient_workflow_list/)	 - List the VReplication workflows in the given keyspace.
* [vtctldclient Workflow show](./vtctldclient_workflow_show/)	 - Show the details for a VReplication workflow.
* [vtctldclient Workflow start](./vtctldclient_workflow_start/)	 - Start a VReplication workflow.
* [vtctldclient Workflow stop](./vtctldclient_workflow_stop/)	 - Stop a VReplication workflow.
* [vtctldclient Workflow update](./vtctldclient_workflow_update/)	 - Update the configuration parameters for a VReplication workflow.

