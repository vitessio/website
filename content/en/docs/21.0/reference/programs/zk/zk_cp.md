---
title: cp
series: zk
commit: 6cd09cce61fa79a1b7aacb36886b7dc44ae82a94
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

### See Also

* [zk](../)	 - zk is a tool for wrangling zookeeper.

