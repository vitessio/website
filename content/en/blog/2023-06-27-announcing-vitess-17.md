---
author: 'Vitess Maintainer Team'
date: 2023-06-27
slug: '2023-06-27-announcing-vitess-17'
tags: ['release','Vitess','MySQL','kubernetes','operator','sharding', 'Orchestration', 'Failover', 'High-Availability']
title: 'Announcing Vitess 17'
description: "Vitess 17 is now Generally Available"
---

We are pleased to announce the general availability of [Vitess 17](https://github.com/vitessio/vitess/releases/tag/v17.0.0)!

## Major Themes in Vitess 17

In this release of Vitess, several significant enhancements have been introduced to improve the compatibility, performance, and usability of the system.

## GA Announcements

The [VTTablet settings connection pool](https://vitess.io/docs/17.0/reference/features/connection-pools/#vttablet-settings-pool) feature, introduced in v15, is now enabled by default in this release. This feature simplifies the management and configuration of system settings, providing users with a more streamlined and convenient experience.

The new [Topology Service](https://vitess.io/docs/reference/features/topology-service/) based [Tablet Throttler](https://vitess.io/docs/17.0/reference/features/tablet-throttler/) (AKA lag throttler) is now GA and [enabled by default](https://vitess.io/docs/17.0/reference/features/tablet-throttler/#v17-and-forward).

## MySQL Compatibility Improvements

Vitess now supports additional statements such as `Prepare`, `Execute`, and `Deallocate` along with many additional functions including comparison operators, numeric functions, date & time functions, `JSON` functions and more.

The query planner has undergone several improvements resulting in more efficient query plans, especially for complex operations such as aggregation, grouping, and ordering – leading to improved query performance. The evaluation engine used when executing queries has also been significantly improved – showing an over a 2x performance improvement. We also added a [new virtual machine](https://github.com/vitessio/vitess/pull/12369) based engine which will eventually replace the AST based one and offer even greater performance improvements (not enabled by default in v17).

Schema tracking has also been enhanced in this release, enabling the Vitess query planner to quickly detect any changes in the database schema. This ensures that queries remain up-to-date with the latest schema modifications, improving overall data consistency.

## Replication Enhancements

Vitess now supports much more efficient [MySQL replication](https://dev.mysql.com/doc/refman/en/replication.html) within each replica set that corresponds to a [Vitess shard](https://vitess.io/docs/concepts/shard/).

We have [added support](https://github.com/vitessio/vitess/pull/12905) for the `noblob` <code>[binlog_row_image](https://dev.mysql.com/doc/refman/en/replication-options-binary-log.html#sysvar_binlog_row_image)</code> type. If you are using [TEXT, BLOB](https://dev.mysql.com/doc/refman/en/blob.html), or [JSON](https://dev.mysql.com/doc/refman/en/json.html) columns this can drastically reduce the overall size of your [binary logs](https://dev.mysql.com/doc/refman/en/binary-log.html), reducing disk I/O and storage along with network I/O and related CPU overhead. Unlike the default (image type <code>full</code>), where each row change event contains the full <code>BEFORE</code> <em>and</em> <code>AFTER</code> images for all columns, with <code>noblob</code> these large columns are <em>only included in the event if they are modified</em>.

We have also [added support](https://github.com/vitessio/vitess/pull/12950) for the [new binary log transaction compression added in MySQL 8.0](https://dev.mysql.com/doc/refman/8.0/en/binary-log-transaction-compression.html). <code>[Zstandard](https://facebook.github.io/zstd)</code> is used to compress the contents of each <code>[GTID](https://dev.mysql.com/doc/refman/en/replication-gtids.html)</code> before storing the [compressed events](https://dev.mysql.com/doc/dev/mysql-server/latest/classbinary__log_1_1Transaction__payload__event.html) in the binary log. This also greatly reduces disk I/O and storage along with network I/O – at the cost of some extra CPU cycles when reading and writing the log.

These features can also be combined for even greater efficiency gains. Aside from the reduced hardware/service costs around disk, network, and CPU resources these new features make it practical to [retain binary logs for a longer period of time](https://dev.mysql.com/doc/refman/8.0/en/replication-options-binary-log.html#sysvar_binlog_expire_logs_auto_purge). This can aid in

backups, restores, and disaster recovery related operations.

## Usability Enhancements

### Traffic Throttling Improvements

* The transaction throttler can now [throttle DMLs even in autocommit mode](https://github.com/vitessio/vitess/pull/13040). Previously it only throttled on explicit `BEGIN` statements.
* The transaction throttler has a new `--tx-throttler-tablet-types` flag to [control the types of tablets](https://github.com/vitessio/vitess/pull/12174) influencing the throttler

### VTorc Improvements

* [VTOrc](https://vitess.io/docs/user-guides/configuration-basic/vtorc/) has had many bug fixes and is now able to handle dead primary recoveries much faster than before.

### VTAdmin Improvements

* We migrated [vtadmin-web](https://vitess.io/docs/17.0/reference/programs/vtadmin-web/) from `create-react-app` to <code>[Vite](https://vitejs.dev/)</code> which allows us to easily keep dependencies up to date and vulnerability-free.

### Other Improvements

You can find the full set of fixes and improvements in the release notes: [https://github.com/vitessio/vitess/releases/tag/v17.0.0](https://github.com/vitessio/vitess/releases/tag/v17.0.0)

## Try It Out

We are very pleased with the great strides we have made with v17 and hope that you will be as well. We encourage all current users of Vitess and everyone who has been considering it to [try this new release](https://github.com/vitessio/vitess/releases/tag/v17.0.0)! We also look forward to your feedback, which can be provided via [Vitess GitHub issues](https://github.com/vitessio/vitess/issues/new/choose) or the [Vitess Slack](https://vitess.slack.com/).
