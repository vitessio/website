---
title: touch
series: zk
commit: 5d802ee3aed9099ee325ff27425099d05090b0e0
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

* [zk](../)	 - zk is a tool for wrangling the zookeeper.

