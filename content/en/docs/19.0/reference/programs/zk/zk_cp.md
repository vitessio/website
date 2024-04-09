---
title: cp
series: zk
commit: cb5464edf5d7075feae744f3580f8bc626d185aa
---
## zk cp



```
zk cp <src> <dst> [flags]
```

### Examples

```
zk cp /zk/path .
zk cp ./config /zk/path/config

# Trailing slash indicates directory
zk cp ./config /zk/path/
```

### Options

```
  -h, --help   help for cp
```

### SEE ALSO

* [zk](../)	 - zk is a tool for wrangling zookeeper.

