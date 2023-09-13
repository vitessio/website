---
title: Workflow
series: vtctldclient
---
## vtctldclient Workflow

Administer VReplication workflows (Reshard, MoveTables, etc) in the given keyspace.

### Synopsis

Workflow commands: List, Show, Start, Stop, Update, and Delete.
See the --help output for each command for more details.

```
vtctldclient Workflow --keyspace <keyspace> [command] [command-flags]
```

### Options

```
  -h, --help              help for Workflow
  -k, --keyspace string   Keyspace context for the workflow (required).
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.
* [vtctldclient Workflow delete](./vtctldclient_workflow_delete/)	 - Delete a VReplication workflow.
* [vtctldclient Workflow list](./vtctldclient_workflow_list/)	 - List the VReplication workflows in the given keyspace.
* [vtctldclient Workflow show](./vtctldclient_workflow_show/)	 - Show the details for a VReplication workflow.
* [vtctldclient Workflow start](./vtctldclient_workflow_start/)	 - Start a VReplication workflow.
* [vtctldclient Workflow stop](./vtctldclient_workflow_stop/)	 - Stop a VReplication workflow.
* [vtctldclient Workflow update](./vtctldclient_workflow_update/)	 - Update the configuration parameters for a VReplication workflow.

