---
title: touch
series: zk
commit: cb5464edf5d7075feae744f3580f8bc626d185aa
---
## zk touch

Change node access time.

### Synopsis

Change node access time.
		
NOTE: There is no mkdir - just touch a node.
The disntinction between file and directory is not relevant in zookeeper.

```
zk touch <path> [flags]
```

### Examples

```
zk touch /zk/path

# Don't create, just touch timestamp.
zk touch -c /zk/path

# Create all parts necessary (think mkdir -p).
zk touch -p /zk/path
```

### Options

```
  -p, --createparent   create parents
  -h, --help           help for touch
  -c, --touchonly      touch only - don't create
```

### SEE ALSO

* [zk](../)	 - zk is a tool for wrangling zookeeper.

