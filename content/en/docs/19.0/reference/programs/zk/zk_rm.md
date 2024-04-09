---
title: rm
series: zk
commit: cb5464edf5d7075feae744f3580f8bc626d185aa
---
## zk rm



```
zk rm <path> [flags]
```

### Examples

```
zk rm /zk/path

# Recursive.
zk rm -R /zk/path

# No error on nonexistent node.
zk rm -f /zk/path
```

### Options

```
  -f, --force             no warning on nonexistent node
  -h, --help              help for rm
  -r, --recursivedelete   recursive delete
```

### SEE ALSO

* [zk](../)	 - zk is a tool for wrangling zookeeper.

