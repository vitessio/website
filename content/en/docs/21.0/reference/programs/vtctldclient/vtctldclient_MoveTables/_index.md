---
title: MoveTables
series: vtctldclient
commit: 376c478ce7daca627d063f22af9121e173787e31
---
## vtctldclient MoveTables

Perform commands related to moving tables from a source keyspace to a target keyspace.

### Options

```
      --format string            The format of the output; supported formats are: text,json. (default "text")
  -h, --help                     help for MoveTables
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
* [vtctldclient MoveTables cancel](./vtctldclient_movetables_cancel/)	 - Cancel a MoveTables VReplication workflow.
* [vtctldclient MoveTables complete](./vtctldclient_movetables_complete/)	 - Complete a MoveTables VReplication workflow.
* [vtctldclient MoveTables create](./vtctldclient_movetables_create/)	 - Create and optionally run a MoveTables VReplication workflow.
* [vtctldclient MoveTables mirrortraffic](./vtctldclient_movetables_mirrortraffic/)	 - Mirror traffic for a MoveTables MoveTables workflow.
* [vtctldclient MoveTables reversetraffic](./vtctldclient_movetables_reversetraffic/)	 - Reverse traffic for a MoveTables VReplication workflow.
* [vtctldclient MoveTables show](./vtctldclient_movetables_show/)	 - Show the details for a MoveTables VReplication workflow.
* [vtctldclient MoveTables start](./vtctldclient_movetables_start/)	 - Start a MoveTables workflow.
* [vtctldclient MoveTables status](./vtctldclient_movetables_status/)	 - Show the current status for a MoveTables VReplication workflow.
* [vtctldclient MoveTables stop](./vtctldclient_movetables_stop/)	 - Stop a MoveTables workflow.
* [vtctldclient MoveTables switchtraffic](./vtctldclient_movetables_switchtraffic/)	 - Switch traffic for a MoveTables VReplication workflow.

