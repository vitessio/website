---
title: ls
series: zk
commit: 6eddcaeac58bed83ebfa3b9ada903ddc8ff36ff6
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

