---
title: Reshard
series: vtctldclient
commit: b089f78945653f6acd17c66f896820e36df49437
---
## vtctldclient Reshard

Perform commands related to resharding a keyspace.

### Synopsis

Reshard commands: Create, Show, Status, SwitchTraffic, ReverseTraffic, Stop, Start, Cancel, and Delete.
See the --help output for each command for more details.

### Options

```
      --format string            The format of the output; supported formats are: text,json. (default "text")
  -h, --help                     help for Reshard
      --target-keyspace string   Target keyspace for this workflow.
  -w, --workflow string          The workflow you want to perform the command on.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.
* [vtctldclient Reshard cancel](./vtctldclient_reshard_cancel/)	 - Cancel a Reshard VReplication workflow.
* [vtctldclient Reshard complete](./vtctldclient_reshard_complete/)	 - Complete a MoveTables VReplication workflow.
* [vtctldclient Reshard create](./vtctldclient_reshard_create/)	 - Create and optionally run a reshard VReplication workflow.
* [vtctldclient Reshard reversetraffic](./vtctldclient_reshard_reversetraffic/)	 - Reverse traffic for a Reshard VReplication workflow.
* [vtctldclient Reshard show](./vtctldclient_reshard_show/)	 - Show the details for a Reshard VReplication workflow.
* [vtctldclient Reshard start](./vtctldclient_reshard_start/)	 - Start a Reshard workflow.
* [vtctldclient Reshard status](./vtctldclient_reshard_status/)	 - Show the current status for a Reshard VReplication workflow.
* [vtctldclient Reshard stop](./vtctldclient_reshard_stop/)	 - Stop a Reshard workflow.
* [vtctldclient Reshard switchtraffic](./vtctldclient_reshard_switchtraffic/)	 - Switch traffic for a Reshard VReplication workflow.

