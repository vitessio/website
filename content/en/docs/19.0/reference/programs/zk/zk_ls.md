---
title: ls
series: zk
commit: cb5464edf5d7075feae744f3580f8bc626d185aa
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

