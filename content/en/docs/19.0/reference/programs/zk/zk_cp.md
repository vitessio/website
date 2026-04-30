---
title: cp
series: zk
commit: 087964bd26b69c5b16c3af9d26515966de9f14bf
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

