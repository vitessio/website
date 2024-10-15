---
title: rm
series: zk
commit: 6cd09cce61fa79a1b7aacb36886b7dc44ae82a94
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

