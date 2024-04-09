---
title: Materialize
series: vtctldclient
commit: cb5464edf5d7075feae744f3580f8bc626d185aa
---
## vtctldclient Materialize

Perform commands related to materializing query results from the source keyspace into tables in the target keyspace.

### Options

```
      --format string            The format of the output; supported formats are: text,json. (default "text")
  -h, --help                     help for Materialize
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
* [vtctldclient Materialize cancel](./vtctldclient_materialize_cancel/)	 - Cancel a Materialize VReplication workflow.
* [vtctldclient Materialize create](./vtctldclient_materialize_create/)	 - Create and run a Materialize VReplication workflow.
* [vtctldclient Materialize show](./vtctldclient_materialize_show/)	 - Show the details for a Materialize VReplication workflow.
* [vtctldclient Materialize start](./vtctldclient_materialize_start/)	 - Start a Materialize workflow.
* [vtctldclient Materialize stop](./vtctldclient_materialize_stop/)	 - Stop a Materialize workflow.

