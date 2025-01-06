---
title: cat
series: zk
commit: d9bc0da8c46a6f69fec4dd3d50187501d1d6268b
---
## zk cat



```
zk cat <path1> [<path2> ...] [flags]
```

### Examples

```
zk cat /zk/path

# List filename before file data
zk cat -l /zk/path1 /zk/path2
```

### Options

```
  -p, --decodeProto   decode proto files and display them as text
  -f, --force         no warning on nonexistent node
  -h, --help          help for cat
  -l, --longListing   long listing
```

### SEE ALSO

* [zk](../)	 - zk is a tool for wrangling zookeeper.

