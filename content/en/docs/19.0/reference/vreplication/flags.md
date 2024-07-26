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

#### vreplication-parallel-insert-workers

**Type** integer\
**Default** 1\
**Applicable on** target

This flag is intended as an option to improve the performance of the [VReplication copy phase](https://vitess.io/docs/design-docs/vreplication/life-of-a-stream/#copy).

During the VReplication copy phase, the target tablet reads batches of rows in VStream packets (the size of which is managed by the [`--vstream_packet_size` flag](#vstream_packet_size)) from the source tablet and inserts them on the target. By default, the target does this sequentially: it reads a batch, then it inserts a batch, then it reads a batch, etc. This flag adds a degree of parallelism so that, while a new batch is being read from the source, up to `--vreplication-parallel-insert-workers` may be inserting previously read batches.

{{< info >}}
Batches of rows insert in parallel, but commit in order. In other words, given two batches B1 and B2 with all primary key IDs in B1 less than those in B2, rows in B2 may be inserted before those in B1, but the B1 transaction will commit before the B2 transaction.

Though this limits performance, it ensures the target will be eventually consistent.
{{< /info >}}

The performance of a VReplication stream is dependent on a number of factors, such as the hardware of the source and target tablets, the latency of the network between them, and utilization of those resources by the VReplication stream and concurrent workloads. Whether this flag improves performance depends on those factors and many others not mentioned here.

A rule of thumb to follow is to see if there are idle resources (especially CPU and disk IO) on both the source and target side. If so, then increasing this flag may increase utilization of those resources, and improve copy phase performance. To measure effectiveness of the flag, compare the values of the [`VReplicationCopyRowCount` metric](../metrics/#vreplicationcopyrowcount-vreplicationcopyrowcounttotal) or [`VReplicationPhaseTimings` metric](../metrics/#vreplicationphasetimings-vreplicationphasetimingscounts-vreplicationphasetimingstotal) with and without the flag.

It is recommended **not** to increase this flag beyond the number of vCPUs available to the target tablet.

#### vreplication_copy_phase_duration

**Type** duration\
**Default** 1h (1 hour)\
**Applicable on** source and target

When copying the contents of a table we go through 1+ cycles of copying rows, catching up on changes made (binlog events) while we copied rows, and applying those changes to the rows that have been copied (copy,catchup,fastforward). This flag determines at most how long we copy rows before moving through the other stages in the cycle. These cycles will continue until all of the rows have been copied. This value is used by the target tablet for the context timeout in the RPC call and it is used on the source tablet for the `MAX_EXECUTION_TIME` query timeout hint.

* You can see metrics related to the copy phase in the following values at the `/debug/vars` vttablet endpoint: `VReplicationPhaseTimings`, `VReplicationPhaseTimingsCounts`, `VReplicationPhaseTimingsTotal`, `VReplicationCopyLoopCount`, `VReplicationCopyLoopCountTotal`, `VReplicationCopyRowCount`, `VReplicationCopyRowCountTotal`, `VStreamerPhaseTiming`, and `VStreamerErrors`

{{< info >}}
You should not generally need to change this. But, you may want to increase this duration if the source has little to no write traffic occurring during the copy phase (to speed things along) and you may want to decrease it if the write rate is very high on the source during the copy phase (to ensure we can stay caught up with changes that are happening).
{{< /info >}}

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

For an idle source shard, the source vstreamer sends a heartbeat. Currently, that is once per second. On receiving the heartbeat the target VReplication module updates the time_updated column of the relevant row of `_vt.vreplication`. For some setups this is a problem, for example:

* If there are too many streams the extra write QPS or CPU load due to these updates are unacceptable
* If there are too many streams and/or a large source field (lot of participating tables) which generates unacceptable increase in the binlog size
* Even for a single stream, if the server is of a lower configuration, then the resulting increase in the QPS or binlog increase may become significant as a percentage of resources

_vreplication_heartbeat_update_interval_ determines how often the time_updated column is updated if there is no activity on the source and the source vstream is only sending heartbeats. Use a low value if you expect a high QPS or you are monitoring this column to alert about potential outages. Keep this high if:

* You have too many streams and the extra write QPS or CPU load due to these updates is unacceptable OR
* You have too many streams and/or a large binlogsource field (i.e., there are a lot of participating tables) which generates unacceptable increase in your binlog size

Some internal processes (like OnlineDDL) depend on the heartbeat updates for operating properly. Hence there is an upper limit on this interval, which is 60 seconds.

#### vstream-binlog-rotation-threshold

**Type** integer\
**Unit** bytes\
**Default** 67108864 (64MiB)\
**Applicable on** source

When starting a vstream which executes a query based on a [GTID](https://dev.mysql.com/doc/refman/en/replication-gtids-concepts.html) snapshot/position (e.g. RowStreamers and ResultStreamers) we will attempt to rotate the binary log (binlog) file if the currently open binlog file on the source is larger than this value in order to limit the [GTID auto positioning](https://dev.mysql.com/doc/refman/en/replication-gtids-auto-positioning.html) overhead. The currently open binlog file — [which can be up to 1GiB in size by default](https://dev.mysql.com/doc/refman/en/replication-options-binary-log.html#sysvar_max_binlog_size) — will always need to be scanned *even when there is little to no replication lag* and empty events will be streamed for those GTIDs in the log that we are skipping. In total, this can add significant overhead on both the `mysqld` instance and the `vttablet` when starting a number of vstreams. Rotating the binlog when it's above this size helps to ensure that we are processing a relatively small open binary log file that will be minimal in both size and number of GTID events. Attempting to rotate the log if the current binlog file is of any significant size (64MiB by default) avoids too many unecessary rotations. If you're on a very fast network with low latency — and plenty of spare CPU capacity — then you may want to increase this size even further to avoid unnecessary rotations. Conversely, if you're on a very slow network with high latency then you may want to decrease this size even further to avoid longer delays when vstreams start (e.g. you may see this exhibited as a slow [`VDiff`](../vdiff) or [`MoveTables`](../movetables) operation on a number of very small tables).

* You can see the number of successful binlog rotations that vstreams have performed (an attempt can fail e.g. due to lack of permissions) using the `VStreamerFlushedBinlogs` status variable in the running process at the [`/debug/vars` `vttablet` endpoint](../../../user-guides/configuration-basic/monitoring/#debugvars)

#### vstream_packet_size

**Type** integer\
**Unit** bytes\
**Default** 250000\
**Applicable on** source

On the source, events are buffered and batched where applicable, to minimize network overhead. For example, multiple row events in a transaction or the set of begin/dml/commit event sets are buffered and sent together. Commits, DDLs, and synthetic events generated by VReplication like heartbeats and resharding journals cause the events buffered on the source to be sent immediately.

**vstream_packet_size** specifies the suggested packet size for VReplication vstreamer. This is used only as a recommendation. The actual packet size may be more or less than this amount depending on the number and type of events yet to be sent on the source.

#### watch_replication_stream

**Type** bool\
**Default** false\
**Applicable on** source

By default vttablets reload their schema every `--queryserver-config-schema-reload-time` seconds (default 30 minutes). This can cause a problem while streaming events if DDLs are applied on the source and streaming is started _after_ the DDL was applied but _before_ vttablet refreshed its schema. This is alleviated by enabling the _watcher_.

When enabled, vttablet will start the _watcher_ which streams the MySQL replication stream from the local database, and uses it to proactively update its schema when it encounters a DDL.

#### track_schema_versions

**Type** bool\
**Default** false\
**Applicable on** source

All vstreams on a tablet share a common engine. vstreams that are lagging might see a newer (and hence incorrect) version of the schema in case DDLs were applied in between. Also, reloading schemas is an expensive operation. If there are multiple vstreams, each of them will separately receive a DDL event resulting in multiple reloads for the same DDL. The [tracker](../internal/tracker) addresses these issues.

When enabled, vttablet will start the _tracker_ which runs a separate vstream that monitors DDLs and stores the version of the schema at the position that a DDL is applied in the schema version table. So if we are streaming events from the past we can get the corresponding schema and interpret the fields from the event correctly.

#### schema-version-max-age-seconds

**Type** integer\
**Unit** seconds\
**Default** 0\
**Applicable on** source

By default the historian loads up to 10,000 rows from the `_vt.schema_version` table into memory which contain a blob of the entire database schema. For clusters with large schemas each of these rows can become very large (>1MB) and can eventually lead to out of memory errors on the tablet if frequent DDLs are run triggering a new `_vt.schema_version` row to be written and stored in the tablet's memory.

`schema-version-max-age-seconds` provides a way to periodically purge those schema version rows from the tablet's memory by removing rows older than the max age in seconds. The default of 0 means no records will be purged. This option **only** controls removing the records in the tablet's memory and does not remove the rows stored in the database. A safe option is to choose a max age at least as old as your [binlog retention seconds](https://dev.mysql.com/doc/refman/8.0/en/replication-options-binary-log.html#sysvar_binlog_expire_logs_seconds) to avoid removing schema versions that are needed to serialize binlog events that require a schema different from the most recent schema.

#### vreplication_retry_delay

**Type** integer\
**Unit** seconds\
**Default** 5\
**Applicable on** target

The target might encounter connection failures during a workflow. VReplication automatically retries
stalled streams after _vreplication_retry_delay_ seconds

#### vreplication_max_time_to_retry_on_error

**Type** duration\
**Default** 0 (unlimited)\
**Applicable on** target

Stop automatically retrying when we've had consecutive failures with the same error for this long after the first occurrence (default 0, meaning no time limit).

#### vreplication_experimental_flags

**Type** bitmask\
**Default** 3 (VReplicationExperimentalFlagOptimizeInserts | VReplicationExperimentalFlagAllowNoBlobBinlogRowImage)\
**Applicable on** target

Features that are not yet adequately field-tested, that are not backward-compatible, or need to be proven in production environments are put behind _vreplication_experimental_flags_. These features are temporary and will either be made permanent, removed, or put behind a separate vttablet option. Currently, the only experimental features are expected to be performance improvements.

This will be a bitmask for each such feature. The ones currently defined:

* bitmask: _0x1_ => If set then we optimize the catchup phase by not sending inserts for rows that are outside the range of primary keys already copied. For more details see: https://github.com/vitessio/vitess/pull/7708

* bitmask: _0x2_ => If set then we support MySQL's [`binlog_row_image=NOBLOB`](https://dev.mysql.com/doc/refman/en/replication-options-binary-log.html#sysvar_binlog_row_image) option. For more details see: https://github.com/vitessio/vitess/pull/12905

* bitmask: _0x4_ => If set then we optimize the replay of events during the running phase by batching statements and transactions in order to limit the number of queries and thus round-trips to MySQL. For more details see: https://github.com/vitessio/vitess/pull/14502
