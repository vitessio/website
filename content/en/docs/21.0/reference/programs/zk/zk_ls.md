---
title: ls
series: zk
commit: d9bc0da8c46a6f69fec4dd3d50187501d1d6268b
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

### SEE ALSO

* [zk](../)	 - zk is a tool for wrangling zookeeper.

