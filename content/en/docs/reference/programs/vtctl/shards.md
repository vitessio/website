---
title: vtctl Shard Command Reference
series: vtctl
---

The following `vtctl` commands are available for administering shards.

## Commands

### CreateShard

`CreateShard [-force] [-parent] <keyspace/shard>`

### GetShard

`GetShard <keyspace/shard>`

### ValidateShard

`ValidateShard [-ping-tablets] <keyspace/shard>`

### ShardReplicationPositions

`ShardReplicationPositions <keyspace/shard>`

### ListShardTablets

`ListShardTablets <keyspace/shard>`

### SetShardIsMasterServing

`SetShardIsMasterServing <keyspace/shard> <is_master_serving>`

### SetShardTabletControl

`SetShardTabletControl [--cells=c1,c2,...] [--blacklisted_tables=t1,t2,...] [--remove] [--disable_query_service] <keyspace/shard> <tablet type>`

### UpdateSrvKeyspacePartition

`UpdateSrvKeyspacePartition [--cells=c1,c2,...] [--remove] <keyspace/shard> <tablet type>`

### SourceShardDelete

`SourceShardDelete <keyspace/shard> <uid>`

### SourceShardAdd

`SourceShardAdd [--key_range=<keyrange>] [--tables=<table1,table2,...>] <keyspace/shard> <uid> <source keyspace/shard>`

### ShardReplicationFix

`ShardReplicationFix <cell> <keyspace/shard>`

### WaitForFilteredReplication

`WaitForFilteredReplication [-max_delay <max_delay, default 30s>] <keyspace/shard>`

### RemoveShardCell

`RemoveShardCell [-force] [-recursive] <keyspace/shard> <cell>`

### DeleteShard

`DeleteShard [-recursive] [-even_if_serving] <keyspace/shard> ...`

### ListBackups

`ListBackups <keyspace/shard>`

### BackupShard

`BackupShard [-allow_master=false] <keyspace/shard>`

### RemoveBackup

`RemoveBackup <keyspace/shard> <backup name>`

### InitShardMaster

`InitShardMaster [-force] [-wait_slave_timeout=<duration>] <keyspace/shard> <tablet alias>`

### PlannedReparentShard

`PlannedReparentShard -keyspace_shard=<keyspace/shard> [-new_master=<tablet alias>] [-avoid_master=<tablet alias>] [-wait_slave_timeout=<duration>]`

### EmergencyReparentShard

`EmergencyReparentShard -keyspace_shard=<keyspace/shard> -new_master=<tablet alias>`

### TabletExternallyReparented

`TabletExternallyReparented <tablet alias>`


## See Also

* [vtctl command index](../../vtctl)
