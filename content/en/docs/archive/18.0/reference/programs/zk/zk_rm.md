---
title: rm
series: zk
commit: d3ff5982ddbbb04da1c9ac3c0bff9b09c904c749
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

