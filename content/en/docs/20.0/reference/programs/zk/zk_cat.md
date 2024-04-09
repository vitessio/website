---
title: cat
series: zk
commit: 6cd09cce61fa79a1b7aacb36886b7dc44ae82a94
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

