---
title: Mount unregister
series: vtctldclient
commit: d3012c188ea0cfc6837917fc6642ea23be9bb1ff
---
## vtctldclient Mount unregister

Unregister a previously mounted external Vitess Cluster.

```
vtctldclient Mount unregister
```

### Examples

```
vtctldclient --server localhost:15999 mount unregister --name ext1
```

### Options

```
  -h, --help          help for unregister
      --name string   Name of the mount.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient Mount](./vtctldclient_mount/)	 - Mount is used to link an external Vitess cluster in order to migrate data from it.

