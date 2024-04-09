---
title: zk
series: zk
commit: cb5464edf5d7075feae744f3580f8bc626d185aa
---
## zk

zk is a tool for wrangling zookeeper.

### Synopsis

zk is a tool for wrangling zookeeper.

It tries to mimic unix file system commands wherever possible, but
there are some slight differences in flag handling.

The zk tool looks for the address of the cluster in /etc/zookeeper/zk_client.conf,
or the file specified in the ZK_CLIENT_CONFIG environment variable.

The local cell may be overridden with the ZK_CLIENT_LOCAL_CELL environment
variable.

### Options

```
  -h, --help                           help for zk
      --keep_logs duration             keep logs for this long (using ctime) (zero to keep forever)
      --keep_logs_by_mtime duration    keep logs for this long (using mtime) (zero to keep forever)
      --log_rotate_max_size uint       size in bytes at which logs are rotated (glog.MaxSize) (default 1887436800)
      --purge_logs_interval duration   how often try to remove old logs (default 1h0m0s)
      --security_policy string         the name of a registered security policy to use for controlling access to URLs - empty means allow all for anyone (built-in policies: deny-all, read-only)
      --server string                  server(s) to connect to
```

### SEE ALSO

* [zk addAuth](./zk_addauth/)	 - 
* [zk cat](./zk_cat/)	 - 
* [zk chmod](./zk_chmod/)	 - 
* [zk cp](./zk_cp/)	 - 
* [zk edit](./zk_edit/)	 - Create a local copy, edit, and write changes back to cell.
* [zk ls](./zk_ls/)	 - 
* [zk rm](./zk_rm/)	 - 
* [zk stat](./zk_stat/)	 - 
* [zk touch](./zk_touch/)	 - Change node access time.
* [zk unzip](./zk_unzip/)	 - 
* [zk wait](./zk_wait/)	 - Sets a watch on the node and then waits for an event to fire.
* [zk watch](./zk_watch/)	 - Watches for changes to nodes and prints events as they occur.
* [zk zip](./zk_zip/)	 - Store a zk tree in a zip archive.

