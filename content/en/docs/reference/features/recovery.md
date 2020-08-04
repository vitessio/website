---
title: Point In Time Recovery
aliases: ['/docs/recovery/pitr','/docs/reference/pitr/']
---

## Point in time recovery

### Supported Databases
- MySQL 5.7

### Introduction

The Point in Time Recovery feature in Vitess enables recovery of data to a past point in time. There can be multiple recovery requests active at the same time. It is possible to recover across sharding actions, i.e. you can recover to a time when there were two shards even though at present there are four.

### Usecases
- Accidental deletion of data.
- Corruption of data due to application bugs.

### Preconditions
- There should be a vitess backup taken before the desired point in time.
- There should be continuous binlogs available from the backup time to the desired point in time.
- As of now, this feature is tested with [ripple](https://github.com/google/mysql-ripple) as the binlog server.

### Usage

To use this feature, you need a usable backup of vitess data and continuous binlogs. .

Here is how you can create a backup.

`vtctlclient -server localhost:15999 Backup zone1-101`

Here `localhost:15999` is the address of vtctld grpc server. `zone1-101` is the tablet alias of a replica tablet in shard.

To maintain continuous binlogs, you need to have a binlog server pointing to the master. You can use [ripple](https://github.com/google/mysql-ripple). You need to take care of the following.
 - You need to have a highly available binlog server setup, if it is down, we should be able to catch up before master rotates the binlog.
 - The binlog files should be safely kept at some reliable and recoverable location (i.e. AWS S3, remote file storage). 
 - In case of any reparenting or master failover, the binlog server should be able to switch to the new master.
 
 Once above is done, you can proceed to send a recovery request. Here is how you can do a recovery.
 
#### Procedure
 First, you need to create a `SNAPSHOT` keyspace with base pointing to original keyspace. This can be done by using following. The snapshot time is UTC time.
 
 `vtctlclient -server localhost:15999 CreateKeyspace -keyspace_type=SNAPSHOT -base_keyspace=ks -snapshot_time=2020-07-17T18:25:20Z restoreks`
 
 Here, `ks` is the base keyspace, `snapshot_time` is the time upto which you want to recover, `restoreks` is the name of recovery keyspace.
 
 Next, you can launch the vttablet, which will actually restore a specific shard. Here are the command line arguments for vttablet.
 - `-init_keyspace restoreks` - here `restoreks` is the recovery keyspace name which we created earlier
 - `-init_shard 0` - here `0` is the shard which we want to recover back.
 - `-backup_storage_implementation file` - for backup type
 - `-file_backup_storage_root /tmp` - back storage location.
 - `-binlog_host localhost` - host of binlog server
 - `-binlog_port` - port of binlog server
 - `-binlog_user` - username of binlog server
 - `-binlog_password` - password for binlog server
 
 On starting vttablet with there arguments, it will look for the the most recent usable backup of the base keyspace, that is earlier than the snapshot time and then restore from that. Once this is done and `binlog_*` command line arguments are passed, then it will apply all the events from binlog server upto the snapshot time.
 
 To restore to specified snapshot time, we need to find the GTID upto the snapshot time from binlog server, by default the timeout for this operation is 1m. This can be changed by setting `-pitr_gtid_lookup_timeout` flag.
 
 
VTGate will automatically exclude tablets belonging to snapshot keyspaces from query routing unless they are specifically addressed using `use ks` or by using queries of the form `select ... from ks.table`.

The base keyspace's vschema will be copied over to the new snapshot keyspace as a default. If desired this can be overwritten by the operator. Care needs to be taken to set `require_explicit_routing` to true when modifying a snapshot keyspace's vschema.
