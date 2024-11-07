---
title: rm
series: zk
commit: d9bc0da8c46a6f69fec4dd3d50187501d1d6268b
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

