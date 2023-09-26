---
title: cp
series: zk
commit: 0e61ba498e0344d37d6e1cae933ae14aa2804fcd
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

