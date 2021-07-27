---
author: 'Alkin Tezuysal'
date: 2021-07-27
slug: '2021-07-27-announcing-vitess-11'
tags: ['release','Vitess','MySQL','kubernetes','operator','cloud','GKE','sharding']
title: 'Announcing Vitess 11'
description: 'We are pleased to announce the general availability of Vitess 11'
---
On behalf of the Vitess maintainers, I am pleased to announce the general availability of [Vitess 11](https://github.com/vitessio/vitess/releases/tag/v11.0.0).

## Major Themes

In this release, Vitess Maintainers have made significant progress in several areas, including Benchmarking, VTAdmin, Schema Tracking, Online DDL, and Performance improvements. While Schema Tracking is experimental, we’re very excited to have Gen4 planner evolving as well. 

Please take a moment to review the [Release Notes](https://github.com/vitessio/vitess/blob/master/doc/releasenotes/11_0_0_release_notes.md). Please read them carefully and report any issues via [GitHub](https://github.com/vitessio/vitess/issues).


### Schema Tracking

Until now certain queries required that VTGate have authoritative column information provided to it separately even though the information already exists at the individual database level. Schema tracking communicates schema changes at the database level to VTGate so that a manual step is no longer required to keep VTGate’s view of the underlying schemas in sync. This allows the query planner to plan more queries and improves our compatibility with MySQL.[Link to enable the feature](https://vitess.io/docs/reference/features/schema-tracking/)

### Schema Management

Online DDL continues to evolve on top of version 10. New and noteworthy:

* Report rows_copied, progress, eta_seconds throughout the migration.
* SHOW VITESS_MIGRATION '...' LOGS: Vitess now retains migration logs up to 24 hours after migration completion/failure, and makes them available upon request.
* Deprecating topo flow: Online DDL now goes directly to tablets. We are deprecating the involvement of topo. Version v12  will complete the deprecation.
  - The command `vtctl OnlineDDL revert …`  is deprecated. Instead, use `vtctl ApplySchema -sql "REVERT VITESS_MIGRATION …"`
  - The command `vtctl VExec` is deprecated.
   To view online DDL migration status use `SHOW VITESS_MIGRATIONS LIKE '...'`
  - To control online DDL migrations, use `ALTER VITESS_MIGRATION '...' CANCEL|RETRY` or `ALTER VITESS_MIGRATION CANCEL ALL`


### Performance Optimizations

This new version of Vitess sports shorter request latencies and significantly reduced CPU and memory usage when serving queries at scale, thanks to the newly upgraded GRPC and ProtoBuf dependencies. We developed a custom Protocol Buffers compiler that allowed us to benefit from the performance improvements in the latest versions of GRPC without sacrificing serialization speed.

### VTAdmin

Vitess 10.0 introduced an experimental multi-cluster admin API and web UI called VTAdmin which has continued to improve, with an emphasis on managing Resharding  workflows. For further documentation on running and configuring VTAdmin, see the [README](https://github.com/vitessio/vitess/blob/407de8b63771471af8e71b0862aa44b9d4495bf1/go/vt/vtadmin/README.md), [documentation tree](https://github.com/vitessio/vitess/tree/407de8b63771471af8e71b0862aa44b9d4495bf1/doc/vtadmin), and [example configuration](https://github.com/vitessio/vitess/blob/407de8b63771471af8e71b0862aa44b9d4495bf1/doc/vtadmin/clusters.yaml).

Deploying the vtadmin-api and vtadmin-web components is completely opt-in. If you're interested in trying it out and providing early feedback, come find us in #feat-vtadmin in the Vitess slack. Note that VTAdmin relies on the new VtctldServer API, so you must be running the new grpc-vtctld service on your vtctlds in order to use it.

### VReplication

The v2 CLI flows are now the default. We are still terming them as experimental until we see more extensive usage. v1 workflows can still be run by passing the -v1 parameter to MoveTables and Reshard. Local examples have been updated to use the v2 flows.
 
CPU utilization and memory footprint have been improved both as part of the performance optimizations mentioned above and VReplication-specific improvements.

Over the last few months, several at-scale MoveTables, Resharding and VStream API deployments have been run successfully. Some edge cases exposed bugs which were fixed and showed the need for additional metrics or functionality which were added.


### Benchmarking 

Since the last release, the continuous benchmarking tool of Vitess: [arewefastyet](https://benchmark.vitess.io/), has finished its main development phase and has been announced through a [blog post](https://vitess.io/blog/2021-07-08-announcing-vitess-arewefastyet/). The post contains a detailed description of arewefastyet’s implementation and UI. 

Please download [Vitess 11](https://github.com/vitessio/vitess/releases/tag/v11.0.0) and try it out!
