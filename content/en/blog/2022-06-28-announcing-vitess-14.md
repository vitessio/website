---
author: 'Vitess Engineering Team'
date: 2022-06-28
slug: '2022-06-28-announcing-vitess-14'
tags: ['release','Vitess','MySQL','kubernetes','operator','cloud','GKE','sharding']
title: 'Announcing Vitess 14'
description: "We are pleased to announce the general availability of Vitess 14"
---

We are pleased to announce the general availability of [Vitess 14](https://github.com/vitessio/vitess/releases/tag/v14.0.0).

## Major Themes #  
In this new release, major improvements have been made in several areas of Vitess, including usability and reliability.
- Online DDL is now GA.
- Gen4 planner is the new default planner.
- VTAdmin and VTOrc are officially in beta with Vitess 14.

## Usability #
### Command-Line Syntax Deprecation #
This release marks the beginning of Vitess standardizing its command-line and flags syntax. Some former syntaxes have been deprecated and will break in the next release. For details, as well as migration instructions, please refer to the [release notes](https://github.com/vitessio/vitess/blob/main/doc/releasenotes/14_0_0_summary.md#command-line-syntax-deprecations).

### VtctldServer and Client #
The new gRPC API for `vtctld` cluster management, [`VtctldServer`](https://github.com/vitessio/vitess/issues/7058), is ready for use. We are targeting Vitess 15 to begin deprecating the old interface, so users should begin transitioning now. Refer to the [`grpc-vtctld` documentation](https://vitess.io/docs/14.0/reference/programs/vtctld/#grpc-vtctld-mdash-new-in-v14) for how to enable the new service.

Vitess 14 also provides a new vtctld client (`vtctldclient`) to correspond to the new gRPC server interface. After enabling the new service, users may begin using the new client for executing cluster management commands. Please refer to the [client documentation](https://vitess.io/docs/14.0/reference/programs/vtctldclient/) for the list of available commands, as well as their options. Both `vtctldclient` and the legacy `vtctlclient` provide shim mechanisms to use each other’s CLI syntaxes to ease the transition, which is described in the [transition documentation](https://vitess.io/docs/14.0/reference/vtctldclient-transition/). Just as with the legacy service, we are targeting Vitess 15 to begin deprecating `vtctlclient`, so users should begin transitioning now.

### VTAdmin #
Vitess 14 includes the beta release of [VTAdmin](https://vitess.io/docs/14.0/reference/programs/vtadmin/), the next generation of cluster management API and UIs for Vitess. VTAdmin provides a single control plane to manage multiple Vitess clusters and will replace the legacy VTCtld Web UI. We are targeting Vitess 15 for general availability, so we encourage users to try out VTAdmin and [provide feedback](https://github.com/vitessio/vitess/issues/new/choose) in this release cycle. A [guide](https://vitess.io/docs/14.0/reference/vtadmin/operators_guide/) on how to configure and run VTAdmin is available on the website.

Note that the new `grpc-vtctld` service is required for VTAdmin to make RPCs to the clusters you would like it to manage, so you must run your `vtctld` components with that service enabled.

Those interested in the details can read the original [architecture RFC](https://github.com/vitessio/vitess/issues/7117) and join the #feat-vtadmin channel in the [Vitess Slack](https://vitess.io/slack).

## GA Announcements #
### Online DDL #
Vitess-native and `gh-ost`-based [online DDL functionality](https://vitess.io/docs/14.0/user-guides/schema-changes/) is now GA. `pt-osc` is still considered experimental, mainly because there has not been sufficient adoption or feedback from the community.

Online DDL has many other improvements in this release. Please refer to the release notes for details.

### Query Planner  #
The Vitess team started working on a new query planner two years ago for [several reasons](https://vitess.io/blog/2021-11-02-why-write-new-planner/). This query planner, called Gen4, is the default in Vitess 14. It replaces the older query planner called V3. Please be sure to read the [related section of the release notes](https://github.com/vitessio/vitess/blob/main/doc/releasenotes/14_0_0_summary.md#gen4-is-now-the-default-planner) if you want to learn more or switch back to V3. The new planner has enabled us to add support for many more queries. Some examples of new query support include  UPDATE/INSERT from SELECT and cross-shard aggregation queries.

## Reliability #
### VTOrc #
[VTOrc](https://vitess.io/docs/14.0/user-guides/configuration-basic/vtorc/) remains experimental in Vitess 14. In this release, the work to make VTOrc a first-class component of Vitess is taken a step further.
- VTOrc now integrates cleanly with VTCtld and running cluster operations from VTCtld does not cause VTOrc to take unnecessary actions.
- Federation has been addressed in this release. It is now possible to run multiple instances of VTOrc watching the same set of keyspaces without them stepping on each other's toes.

The durability policy configuration has been refactored. Instead of being provided as command-line configuration, it is now stored in the topology server. Both VTOrc and VTCtld will read it from there and honor the provided durability policies.

Emergency Reparent Shard’s capabilities have been augmented to now allow for more than 1 failure based on the durability policies set for the keyspace.

You can follow the progress of VTOrc by watching the original [RFC](https://github.com/vitessio/vitess/issues/6612) and the [durability RFC](https://github.com/vitessio/vitess/issues/8975).

## Performance #
Our benchmarking system, [arewefastyet](https://github.com/vitessio/arewefastyet), benchmarked this new version of Vitess. The comparison between v14.0.0 and v13.0.0 is available on [the Vitess Benchmark page](https://benchmark.vitess.io/macrobench?ltag=13.0.0&rtag=14.0.0). We can observe a performance improvement of about ~10%. This improvement mainly comes from the removal of internal SAVEPOINT query execution.


Please download [Vitess 14](https://github.com/vitessio/vitess/releases/tag/v14.0.0) and try it out! Issues can be reported via [GitHub](https://github.com/vitessio/vitess/issues).
