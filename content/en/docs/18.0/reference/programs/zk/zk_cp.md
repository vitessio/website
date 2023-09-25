---
title: cp
series: zk
commit: 5d802ee3aed9099ee325ff27425099d05090b0e0
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

* [zk](../)	 - zk is a tool for wrangling the zookeeper.

