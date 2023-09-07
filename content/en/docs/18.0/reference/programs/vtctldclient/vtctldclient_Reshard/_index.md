---
title: Reshard
series: vtctldclient
---
## vtctldclient Reshard

Perform commands related to resharding a keyspace.

### Synopsis

Reshard commands: Create, Show, Status, SwitchTraffic, ReverseTraffic, Stop, Start, Cancel, and Delete.
See the --help output for each command for more details.

### Options

```
      --format string            The format of the output; supported formats are: text,json (default "text")
  -h, --help                     help for Reshard
      --target-keyspace string   Target keyspace for this workflow exists (required)
  -w, --workflow string          The workflow you want to perform the command on (required)
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.
* [vtctldclient Reshard Cancel](./vtctldclient_reshard_cancel/)	 - Cancel a reshard VReplication workflow.
* [vtctldclient Reshard Complete](./vtctldclient_reshard_complete/)	 - Complete a MoveTables VReplication workflow.
* [vtctldclient Reshard Create](./vtctldclient_reshard_create/)	 - Create and optionally run a reshard VReplication workflow.
* [vtctldclient Reshard ReverseTraffic](./vtctldclient_reshard_reversetraffic/)	 - Reverse traffic for a reshard VReplication workflow.
* [vtctldclient Reshard Show](./vtctldclient_reshard_show/)	 - Show the details for a reshard VReplication workflow.
* [vtctldclient Reshard Start](./vtctldclient_reshard_start/)	 - Start a reshard workflow.
* [vtctldclient Reshard Status](./vtctldclient_reshard_status/)	 - Show the current status for a reshard VReplication workflow.
* [vtctldclient Reshard Stop](./vtctldclient_reshard_stop/)	 - Stop a reshard workflow.
* [vtctldclient Reshard SwitchTraffic](./vtctldclient_reshard_switchtraffic/)	 - Switch traffic for a reshard VReplication workflow.

