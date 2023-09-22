---
title: VDiff
series: vtctldclient
---
## vtctldclient VDiff

Perform commands related to diffing tables involved in a VReplication workflow between the source and target.

### Synopsis

VDiff commands: create, resume, show, stop, and delete.
See the --help output for each command for more details.

### Options

```
      --format string            The format of the output; supported formats are: text,json. (default "text")
  -h, --help                     help for VDiff
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
* [vtctldclient VDiff create](./vtctldclient_vdiff_create/)	 - Create and run a VDiff to compare the tables involved in a VReplication workflow between the source and target.
* [vtctldclient VDiff delete](./vtctldclient_vdiff_delete/)	 - Delete VDiffs.
* [vtctldclient VDiff resume](./vtctldclient_vdiff_resume/)	 - Resume a VDiff.
* [vtctldclient VDiff show](./vtctldclient_vdiff_show/)	 - Show the status of a VDiff.
* [vtctldclient VDiff stop](./vtctldclient_vdiff_stop/)	 - Stop a running VDiff.

