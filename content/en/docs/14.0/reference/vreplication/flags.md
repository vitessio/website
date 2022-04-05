---
title: VTTablet Flags
description: vttablet flags related to VReplication functionality
weight: 80
---

There are several flags that can be specified when `vttablet` is launched that are related to the
VReplication functionality. Some of the flags are relevant when tablets are acting as targets and others when tablets are acting as sources in a VReplication workflow.

#### relay_log_max_size

**Type** integer\
**Unit** bytes\
**Default** 250000\
**Applicable on** target

The target tablet receives events from the source and applies the corresponding DML to the underlying MySQL database. Depending on the load on the target the query execution times can change. Also during the copy
phase, we are doing bulk inserts. For both of these reasons VReplication introduces a buffer between receiving the events and applying them: the _relay log_.

The relay log buffers events on the target as they are received from the source. This is done in a separate thread concurrently with the thread that applies the events.

**relay_log_max_size** defines the maximum buffer size (in bytes). As events arrive they are stored in the relay log. The apply thread consumes these events as fast as it can. When the relay log fills up we no longer pull
events from the source until some events are consumed. If single rows are larger than the specified buffer size, a single row is buffered at a time.

#### vreplication_copy_phase_max_innodb_history_list_length

**Type** integer\
**Default** 1000000\
**Applicable on** source

When copying the contents of a table we go through 1+ cycles of copy,catchup,fastforward in the copy phase. When preparing to copy a batch of rows (row streamer) we check the [InnoDB history list length](https://dev.mysql.com/doc/refman/en/innodb-purge-configuration.html) on the source MySQL instance and wait for it to become less than or equal to this value before beginning. This helps to limit the impact of VReplication operations such as `MoveTables` on the source tablet (especially important if the source is a PRIMARY).

* You can see the current configuration value as `RowStreamerMaxInnoDBTrxHistLen` in the running process at the `/debug/vars` vttablet endpoint
* You can modify the current configuration value as `RowStreamerMaxInnoDBTrxHistLen` in the running process at the `/debug/env` vttablet endpoint
* You can see the total (global) number of waits and time spent waiting for MySQL on the source tablet as `waitForMySQL` in `RowStreamerWaits` at the `/debug/vars` vttablet endpoint 
* You can see the number of waits and time spent waiting for MySQL on the source tablet by table (we do not have the workflow name on the source) as `<tablename>:waitForMySQL` in `VStreamerPhaseTiming` at the `/debug/vars` vttablet endpoint 

#### vreplication_copy_phase_max_mysql_replication_lag

**Type** integer\
**Unit** seconds\
**Default** 43200 (12 hours)\
**Applicable on** source

When copying the contents of a table we go through 1+ cycles of copy,catchup,fastforward in the copy phase. When preparing to copy a batch of rows (row streamer) we check the [Seconds_Behind_Source](https://dev.mysql.com/doc/refman/en/replication-administration-status.html) value on the source MySQL instance and wait for it to become less than or equal to this value before beginning. This helps to limit the impact of VReplication operations such as `MoveTables` on the source tablet.

* You can see the current configuration value as `RowStreamerMaxMySQLReplLagSecs` in the running process at the `/debug/vars` vttablet endpoint
* You can modify the current configuration value as `RowStreamerMaxMySQLReplLagSecs` in the running process at the `/debug/env` vttablet endpoint
* You can see the total (global) number of waits and time spent waiting for MySQL on the source tablet as `waitForMySQL` in `RowStreamerWaits` at the `/debug/vars` vttablet endpoint 
* You can see the number of waits and time spent waiting for MySQL on the source tablet by table (we do not have the workflow name on the source) as `<tablename>:waitForMySQL` in `VStreamerPhaseTiming` at the `/debug/vars` vttablet endpoint 

#### vreplication_heartbeat_update_interval

**Type** integer\
**Unit** seconds\
**Default** 1\
**Maximum** 60 (one minute)\
**Applicable on** target

For an idle source shard, the source vstreamer sends a heartbeat. Currently, that is once per second. On receiving the heartbeat the target VReplication module updates the time_updated column of the relevant row of `\_vt.vreplication`. For some setups this is a problem, for example:

* if there are too many streams the extra write QPS or CPU load due to these updates are unacceptable
* if there are too many streams and/or a large source field (lot of participating tables) which generates unacceptable increase in the binlog size
* even for a single stream, if the server is of a lower configuration, then the resulting increase in the QPS or binlog increase may become significant as a percentage of resources

**vreplicationHeartbeatUpdateInterval** determines how often the time_updated column is updated if there is no activity on the source and the source vstream is only sending heartbeats. Use a low value if you expect a high QPS or you are monitoring this column to alert about potential outages. Keep this high if:

* you have too many streams and the extra write QPS or CPU load due to these updates is unacceptable OR
 * you have too many streams and/or a large binlogsource field (i.e., there are a lot of participating tables) which generates unacceptable increase in your binlog size

Some internal processes (like online ddl) depend on the heartbeat updates for operating properly. Hence there is an upper limit on this interval, which is 60 seconds.

#### vstream_packet_size

**Type** integer\
**Unit** bytes\
**Default** 250000\
**Applicable on** source

On the source, events are buffered where applicable, to minimize network overhead. For example, multiple row events in a transaction or the set of begin/dml/commit event sets are buffered and sent together. Commits, DDLs, and synthetic events generated by VReplication like heartbeats, resharding journals cause the events buffered on the source to be sent immediately.

**vstream_packet_size** specifies the suggested packet size for VReplication streamer. This is used only as a recommendation. The actual packet size may be more or less than this amount depending on the number and type of events yet to be sent on the source.

#### watch_replication_stream

**Type** bool\
**Default** false\
**Applicable on** source

By default vttablets reload their schema every `queryserver-config-schema-reload-time` seconds (default 30 minutes). This can cause a problem while streaming events if DDLs are applied on the source and streaming is started _after_ the DDL was applied but _before_ vttablet refreshed its schema. This is alleviated by the _watcher_.

When enabled, vttablet will start the _watcher_ which streams the MySQL replication stream from the local database, and uses it to proactively update its schema when it encounters a DDL.

#### track_schema_versions

**Type** bool\
**Default** false\
**Applicable on** source

All vstreams on a tablet share a common engine. vstreams that are lagging might see a newer (and hence incorrect) version of the schema in case DDLs were applied in between. Also, reloading schemas is an expensive operation. If there are multiple vstreams, each of them will separately receive a DDL event resulting in multiple reloads for the same DDL. The [tracker](../../../design-docs/vreplication/vstream/tracker/) addresses these issues.

When enabled, vttablet will start the _tracker_ which runs a separate vstream that monitors DDLs and stores the version of the schema at the position that a DDL is applied in the schema version table. So if we are streaming events from the past we can get the corresponding schema and interpret the fields from the event correctly.

#### vreplication_retry_delay

**Type** integer\
**Unit** seconds\
**Default** 5\
**Applicable on** target

The target might encounter connection failures during a workflow. VReplication automatically retries
stalled streams after _vreplication_retry_delay_ seconds

#### vreplication_tablet_type

**Type** string\
**Default** in_order:REPLICA,PRIMARY\
**Applicable on** target

This parameter specifies the default tablet_types that will be used by the tablet picker to find sources for a VReplication stream. It can be overridden, per workflow, by passing a different list to the workflow commands like MoveTables and Reshard.

#### vreplication_experimental_flags

**Type** bitmask\
**Default** 0\
**Applicable on** target

Features that are not field-tested, that are not backward-compatible, or need to be proven in production environments are put behind _vreplication_experimental_flags_. These features are temporary and will either be made permanent, removed, or put behind a separate vttablet option. Currently, the only experimental features are expected to be performance improvements.

This will be a bit-mask for each such feature. The ones currently defined:

bitmask: *0x1* => If set then we optimize the catchup phase by not sending inserts for rows that are outside the range of primary keys already copied. More details at https://github.com/vitessio/vitess/pull/7708
