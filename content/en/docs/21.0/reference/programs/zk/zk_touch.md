---
title: touch
series: zk
commit: d9bc0da8c46a6f69fec4dd3d50187501d1d6268b
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

