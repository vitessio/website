---
title: ls
series: zk
commit: 6cd09cce61fa79a1b7aacb36886b7dc44ae82a94
---
## zk ls



```
zk ls <path> [flags]
```

### Examples

```
zk ls /zk
zk ls -l /zk

# List directory node itself)
zk ls -ld /zk

# Recursive (expensive)
zk ls -R /zk
```

### Options

```
  -d, --directorylisting   list directory instead of contents
  -f, --force              no warning on nonexistent node
  -h, --help               help for ls
  -l, --longlisting        long listing
  -R, --recursivelisting   recursive listing
```

### See Also

* [zk](../)	 - zk is a tool for wrangling zookeeper.

