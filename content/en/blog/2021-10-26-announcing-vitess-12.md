---
author: 'Alkin Tezuysal'
date: 2021-10-26
slug: '2021-10-26-announcing-vitess-12'
tags: ['release','Vitess','MySQL','kubernetes','operator','cloud','GKE','aws','sharding']
title: 'Announcing Vitess 12'
description: 'We are pleased to announce the general availability of Vitess 12'
---
On behalf of the Vitess maintainers, I am pleased to announce the general availability of [Vitess 12](https://github.com/vitessio/vitess/releases/tag/v12.0.0).

## Major Themes
In this release, Vitess Maintainers have made significant progress in several areas, including Gen4 planner, VTAdmin, and other improvements. 
Please take a moment to review the [Release Notes](https://github.com/vitessio/vitess/blob/master/doc/releasenotes/11_0_0_release_notes.md). Please read them carefully and report any issues via [GitHub](https://github.com/vitessio/vitess/issues).

### Gen4 Planner
The newest version of the query planner, Gen4, becomes an experimental feature as part of this release. While Gen4 has been under development for a few release cycles, we have now reached parity with its predecessor, v3.
To use Gen4, VTGate's `-planner_version` flag needs to be set to Gen4Fallback.

A series of blog posts regarding Gen4 is coming up, stay tuned.

### VTAdmin
Vitess 10.0 introduced an experimental multi-cluster admin API and web UI called VTAdmin, and Vitess 11.0 brought improvements to the vreplication-based Reshard workflows. 

Vitess 12.0 introduces an [experimental implementation](https://github.com/vitessio/vitess/pull/8515) for role-based access control (RBAC), allowing Vitess operators to allow or deny API endpoints based on their Vitess environment’s particular authorization implementation. This lays a foundation for the (upcoming vtctld2 UI deprecation work)[https://github.com/vitessio/vitess/projects/13]. Note that VTAdmin provides (no authentication)[https://github.com/vitessio/vitess/blob/7f6e627c0d9573fbcc2f6485305d721f21922aee/go/vt/vtadmin/rbac/authentication.go#L34-L50] implementations; users may provide their own that works with the particular details of their deployment.

Deploying the vtadmin-api and vtadmin-web components is completely opt-in. If you’re interested in trying it out and providing early feedback, come find us in #feat-vtadmin in the Vitess slack. Note that VTAdmin relies on the new VtctldServer API, so you must be running the new grpc-vtctld service on your vtctlds in order to use it.

### Benchmarking 
Since the last release, there have been slight changes to (arewefastyet)[https://benchmark.vitess.io/]. The web server uses a new benchmark queue that consumes less computational resources and avoids running the same benchmark twice. To enhance our trust in the performance of the new Gen4 planner, we developed a feature that lets us visualize the query plans produced by macro benchmarks, along with their statistics (i.e execution time, execution count). This gives us more leverage when comparing the performance of V3 and Gen4.

### Inclusive Naming 
Significant naming changes have been made to remove references to `master` and replace them with `primary` or `source`. These changes are all backward-compatible right now. However, in the next release, deprecated commands will be removed which means that scripts that use the deprecated commands should be modified to use new commands.

Please download [Vitess 11](https://github.com/vitessio/vitess/releases/tag/v12.0.0) and try it out!
