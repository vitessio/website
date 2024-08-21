---
title: VDiff
series: vtctldclient
commit: 7e8f008834c0278b8df733d606940a629b67a9d9
---
## vtctldclient VDiff

Perform commands related to diffing tables involved in a VReplication workflow between the source and target.

### Options

```
      --format string            The format of the output; supported formats are: text,json. (default "text")
  -h, --help                     help for VDiff
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
* [vtctldclient VDiff create](./vtctldclient_vdiff_create/)	 - Create and run a VDiff to compare the tables involved in a VReplication workflow between the source and target.
* [vtctldclient VDiff delete](./vtctldclient_vdiff_delete/)	 - Delete VDiffs.
* [vtctldclient VDiff resume](./vtctldclient_vdiff_resume/)	 - Resume a VDiff.
* [vtctldclient VDiff show](./vtctldclient_vdiff_show/)	 - Show the status of a VDiff.
* [vtctldclient VDiff stop](./vtctldclient_vdiff_stop/)	 - Stop a running VDiff.

