---
author: 'Vitess Maintainer Team'
date: 2023-02-28
slug: '2023-02-28-announcing-vitess-16'
tags: ['release','Vitess','MySQL','kubernetes','operator','cloud','GKE','sharding', 'Orchestration', 'Failover', 'High-Availability', 'Backup']
title: 'Announcing Vitess 16'
description: "Vitess 16 is now Generally Available"
---

We are pleased to announce the general availability of [Vitess 16](https://vitess.io/docs/16.0/)!

## Documentation improvements

In this release the maintainer team has decided to put an emphasis on reviewing, editing, and rewriting the [website documentation](https://vitess.io/docs/) to be current with the code. 
With help from [CNCF](https://www.cncf.io/), we have also improved the search experience. We welcome feedback on the current incarnation of the docs.

## GA announcements

We are marking [VDiff v2](https://vitess.io/docs/16.0/reference/vreplication/vdiff/) as Generally Available or production-ready in v16. 
We now recommend that you use v2 rather than v1 going forward. Version 1 will be deprecated and eventually removed in future releases.

This new version of VDiff should offer a much improved overall user experience, especially when migrating very large tables. 
You can read more about VDiff v2 in the [Introducing VDiff V2 blog post](https://vitess.io/blog/2022-11-22-vdiff-v2/).

## VTOrc is now mandatory

[VTOrc](https://vitess.io/blog/2022-09-21-vtorc-vitess-native-orchestrator/) is a required component of Vitess starting from this release. 
It is necessary to run at least one instance of VTOrc in order for Vitess to automatically manage the backing MySQL clusters.

## MySQL compatibility improvements

We have been making steady progress on adding query support for more MySQL constructs. In this release we have added support for Views in Vitess. 
It is now possible to create views that access data across shards and they will work as intended in Vitess. Note that this is considered an experimental feature. It will move to GA in a future release.

## [Other improvements](https://github.com/vitessio/vitess/releases/tag/v16.0.0)

Support for native incremental backups and point in time recoveries has been added. It is now possible to take an incremental backup, starting with the last known (full or incremental) backup, 
and up to either a specified (GTID) position, or the current ("auto") position. Using these incremental backups it is then possible to restore a backup up to a given point in time (GTID position) without 
relying on a binlog server. Note that this is only supported for the file-based builtin backup method, not for xtrabackup.

A [new `VEXPLAIN` command](https://vitess.io/docs/16.0/user-guides/sql/vexplain/) has been introduced to help the users gain more insight into query planning in Vitess. 
This gives users the ability to inspect the query plan produced by vtgate, all the queries executed on the MySQL instances, and the MySQL explain output for the executed queries.

## Try it out
We are very pleased with the great strides we have made with v16, and hope that you will be as well. 
We encourage all current users of Vitess and everyone who has been considering it to [try this new release](https://github.com/vitessio/vitess/releases/tag/v16.0.0)! 
We also look forward to your feedback, which can be provided via [Vitess GitHub issues](https://github.com/vitessio/vitess/issues/new/choose) or [Vitess Slack](https://vitess.slack.com/).

