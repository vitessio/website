---
author: 'Florent Poinsard'
date: 2022-02-22
slug: '2022-02-22-announcing-vitess-13'
tags: ['release','Vitess','MySQL','kubernetes','operator','cloud','GKE','sharding']
title: 'Announcing Vitess 13'
description: "We are pleased to announce the general availability of Vitess 13"
---

The Vitess maintainers are pleased to announce the general availability of [Vitess 13](https://github.com/vitessio/vitess/releases/tag/v13.0.0).

## Major Themes #

In this release, Vitess maintainers have made significant progress in several areas, including query serving and cluster management.

## Compatibility #

This release comes with major compatibility improvements. We added support for a large number of [character sets](https://vitess.io/docs/13.0/user-guides/configuration-basic/collations/) and improved our evaluation engine to perform more evaluations at the VTGate level. [Gen4 planner](https://vitess.io/docs/13.0/reference/compatibility/query_planner/) is no longer experimental and we have used it to add support for a number of previously unsupported complex queries.

## Cluster Management #

[VTOrc](https://vitess.io/docs/13.0/user-guides/configuration-basic/vtorc/) is now more tightly integrated with other components in Vitess.
It has been enhanced with errant GTID detection during emergency failovers.
User-initiated emergency failovers are now more robust and should almost always succeed.

## Multi-Column Vindexes #

While we have had some support for [multi-column vindexes](https://vitess.io/docs/13.0/user-guides/vschema-guide/subsharding-vindex/) since Vitess 5.0, this release brings better support and performance improvements. We can now route to a [subset of shards](https://vitess.io/docs/13.0/user-guides/vschema-guide/subsharding-vindex/) when a partial column list is provided in a `WHERE` clause instead of scattering to all shards.

## Website docs #

Previously, we had only one version of the documentation on the website.
Docs for older releases were archived as PDFs, which made it difficult for users to find information relevant to the specific release they might be running.
We now have versioned docs on the website for [this release](https://vitess.io/docs/13.0/) and the past two releases.
Eventually, we will have documentation for all supported releases.

Please download [Vitess 13](https://github.com/vitessio/vitess/releases/tag/v13.0.0) and try it out! Issues can be reported via [GitHub](https://github.com/vitessio/vitess/issues).
