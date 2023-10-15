---
title: Mount show
series: vtctldclient
commit: 314ebcf13923f98945595208d5099eca4a7184ea
---
## vtctldclient Mount show

Show attributes of a previously mounted external Vitess Cluster.

```
vtctldclient Mount show
```

### Examples

```
vtctldclient --server localhost:15999 Mount Show ext1
```

### Options

```
  -h, --help   help for show
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient Mount](../)	 - Mount is used to link an external Vitess cluster in order to migrate data from it.

