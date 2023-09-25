---
title: zip
series: zk
commit: 5d802ee3aed9099ee325ff27425099d05090b0e0
---
## zk zip

Store a zk tree in a zip archive.

### Synopsis

Store a zk tree in a zip archive.
	
Note this won't be immediately useful to the local filesystem since znodes can have data and children;
that is, even "directories" can contain data.

```
zk zip <path> [<path> ...] <archive> [flags]
```

### Options

```
  -h, --help   help for zip
```

### SEE ALSO

* [zk](../)	 - zk is a tool for wrangling the zookeeper.

