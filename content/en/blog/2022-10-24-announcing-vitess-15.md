---
author: 'Vitess Maintainer Team'
date: 2022-10-24
slug: '2022-10-24-announcing-vitess-15'
tags: ['release','Vitess','MySQL','kubernetes','operator','cloud','GKE','sharding']
title: 'Announcing Vitess 15'
description: "Vitess 15 is now Generally Available"
---

[Vitess 15](https://vitess.io/docs/15.0/) is now Generally Available, with a number of new enhancements designed to make Vitess easier to use, more resilient and easier to scale!

[VTOrc](https://vitess.io/docs/15.0/reference/vtorc), a vitess-native cluster monitoring and recovery component is now GA.
VTOrc monitors and repairs Vitess clusters, eliminating paging and manual intervention and automating recovery.
This makes Vitess fully self-healing and resilient to MySQL server failures.
It also obsoletes the third-party integration with [Orchestrator](https://github.com/openark/orchestrator) that users have traditionally relied on to recover from MySQL server failures.
Users deploying VTOrc benefit by reducing both the operational burden of running Vitess and the amount of downtime they experience.

[VTAdmin](https://vitess.io/docs/15.0/reference/vtadmin/), the next generation of cluster management APIs and UIs for Vitess is also now GA.
Unlike the previous UI, which was available for use only on a per-cluster basis, VTAdmin provides a single control plane to manage multiple Vitess clusters (e.g. development versus production).
This makes it much easier for users to monitor and administer their Vitess deployments and significantly reduces the amount of time they spend doing so.
VTAdmin is built on a modern UI technology stack that will allow us to maintain a much richer Web UI as new features and functions are added.

**Old UI:**

<img src="/files/2022-10-26-announcing-vitess-15/old-ui-commerce-0.png" alt="Old UI showing keyspace commerce 0" style="width:600px"/>

<img src="/files/2022-10-26-announcing-vitess-15/old-ui-commerce-0-and-dropdown.png" alt="Old UI showing keyspace commerce 0 and dropdown" style="width:600px"/>

**New UI:**

<img src="/files/2022-10-26-announcing-vitess-15/new-ui-commerce-0.png" alt="New UI showing keyspace commerce 0" style="width:600px"/>

<img src="/files/2022-10-26-announcing-vitess-15/new-ui-commerce-0-and-settings.png" alt="New UI showing keyspace commerce 0 and settings" style="width:600px"/>


In addition to these major streams of work, we have made tremendous progress on [VEP-4, aka The Flag Situation](https://github.com/vitessio/enhancements/blob/main/veps/vep-4.md), reorganizing our code so that Vitess binaries and their flags are clearly aligned in help text.
An immediate win for usability, this positions us well to move on to a [viper](https://github.com/spf13/viper) implementation which will facilitate additional improvements including standardization of flag syntax and runtime configuration reloads.
We are also aligning with industry standards regarding the use of flags, ensuring a seamless experience for users migrating from or integrating with other platforms.

We are also pleased to announce that VDiff v2, used to check that data migrations have been conducted successfully, is now feature complete.
While previous versions were time- and memory-intensive and required that users start over if it failed, VDiff v2 distributes work so that memory issues are all but eliminated, and is resumable, so users can start where they left off if there is an interruption for any reason.
Error reporting improvements also help ensure that users know what needs to be fixed before it is resumed.
VDiff v2 greatly enhances usability, and we expect it to be GA in the next release.

We continue to make improvements in the areas of MySQL compatibility and performance.
For instance, we now produce more efficient query plans for subqueries and derived tables.
We have also improved our benchmarking infrastructure aka [arewefastyet](https://benchmark.vitess.io) to make it easier to add new benchmarks.

We are very pleased with the great strides we have made with v15, and hope that you will be as well.
We encourage all current users of Vitess and everyone who has been considering it to try this new [release](https://github.com/vitessio/vitess/releases/tag/v15.0.0)!
We also look forward to your feedback, which can be provided via [GitHub](https://github.com/vitessio/vitess/issues/new/choose) or [Slack](https://vitess.slack.com/).
