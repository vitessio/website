---
title: wait
series: zk
commit: cb5464edf5d7075feae744f3580f8bc626d185aa
---
## zk wait

Sets a watch on the node and then waits for an event to fire.

```
zk wait <path> [flags]
```

### Examples

```
 # Wait for node change or creation.
zk wait /zk/path

# Trailing slash waits on children.
zk wait /zk/path/children/
```

### Options

```
  -e, --exit   exit if the path already exists
  -h, --help   help for wait
```

### SEE ALSO

* [zk](../)	 - zk is a tool for wrangling zookeeper.

