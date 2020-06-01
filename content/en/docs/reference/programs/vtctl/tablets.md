---
title: vtctl Tablet Command Reference
series: vtctl
---

The following `vtctl` commands are available for administering tablets.

## Commands

### InitTablet

```
InitTablet [-allow_update] [-allow_different_shard] [-allow_master_override] [-parent] [-db_name_override=<db name>] [-hostname=<hostname>] [-mysql_port=<port>] [-port=<port>] [-grpc_port=<port>] [-tags=tag1:value1,tag2:value2] -keyspace=<keyspace> -shard=<shard> <tablet alias> <tablet type>
```

### GetTablet

```
GetTablet <tablet alias>
```

### UpdateTabletAddrs

```
UpdateTabletAddrs [-hostname <hostname>] [-ip-addr <ip addr>] [-mysql-port <mysql port>] [-vt-port <vt port>] [-grpc-port <grpc port>] <tablet alias>
```

### DeleteTablet

```
DeleteTablet [-allow_master] <tablet alias> ...
```

### SetReadOnly

```
SetReadOnly <tablet alias>
```

### SetReadWrite

```
SetReadWrite <tablet alias>
```

### StartSlave

```
StartSlave <tablet alias>
```

### StopSlave

```
StopSlave <tablet alias>
```

### ChangeSlaveType

```
ChangeSlaveType [-dry-run] <tablet alias> <tablet type>
```

### Ping

```
Ping <tablet alias>
```

### RefreshState

```
RefreshState <tablet alias>
```

### RefreshStateByShard

```
RefreshStateByShard [-cells=c1,c2,...] <keyspace/shard>
```

### RunHealthCheck

```
RunHealthCheck <tablet alias>
```

### IgnoreHealthError

```
IgnoreHealthError <tablet alias> <ignore regexp>
```

### Sleep

```
Sleep <tablet alias> <duration>
```

### ExecuteHook

```
ExecuteHook <tablet alias> <hook name> [<param1=value1> <param2=value2> ...]
```

### ExecuteFetchAsApp

```
ExecuteFetchAsApp [-max_rows=10000] [-json] [-use_pool] <tablet alias> <sql command>
```

### ExecuteFetchAsDba

```
ExecuteFetchAsDba [-max_rows=10000] [-disable_binlogs] [-json] <tablet alias> <sql command>
```

### VReplicationExec

```
VReplicationExec [-json] <tablet alias> <sql command>
```

### Backup

```
Backup [-concurrency=4] [-allow_master=false] <tablet alias>
```

### RestoreFromBackup

```
RestoreFromBackup <tablet alias>
```

### ReparentTablet

```
ReparentTablet <tablet alias>
```

## See Also

* [vtctl command index](../../vtctl)
