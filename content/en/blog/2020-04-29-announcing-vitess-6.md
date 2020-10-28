---
author: 'Morgan Tocker'
date: 2020-04-29T08:00:21-07:00
slug: '2020-04-29-announcing-vitess-6'
tags: ['Guides']
title: 'Announcing Vitess 6'
---

I am excited to announce the general availability of Vitess 6, the second release to follow our [new accelerated release schedule](https://github.com/vitessio/enhancements/blob/master/veps/vep-1.md).

While only 12 weeks have elapsed since the previous release, it feels like a few key investments have started to pay dividends all at once. To provide some personal highlights:

### Improved SQL Support
Vitess now understands much more of MySQL’s syntax. We have taken the approach of studying the queries issued by common applications and frameworks, and baking them right into the end-to-end test suite.

Common issues such as `SHOW` commands not returning correct results or MySQL’s `SQL_CALC_FOUND_ROWS` feature have now been fixed. In Vitess 7, we plan to add support for setting session variables, which will address one of the largest outstanding compatibility issues.

### Kubernetes Topology Service
The Helm charts now default to using Kubernetes as the [Topology Service](https://vitess.io/docs/concepts/topology-service/). This helps remove a dependency on etcd-operator, which has since been [discontinued](https://github.com/coreos/etcd-operator/pull/2169).

This change also unlocked the adoption of Helm 3 and support for a wider range of Kubernetes versions, making installing Vitess much easier.

### General Availability of VReplication-based Workflows
While VReplication made its appearance in Vitess 4, it has now been promoted from experimental to general availability and the documentation now points to [MoveTables](https://vitess.io/docs/user-guides/migration/move-tables/) and [Resharding](https://vitess.io/docs/user-guides/configuration-advanced/resharding/).

These workflows require significantly fewer steps than their predecessors (Vertical Split Clone and Horizontal Sharding), of which we intend to deprecate at some point in the future.

--

In addition to this, the end-to-end testsuite is now [fully migrated to Golang](https://www.planetscale.com/blog/planetscale-migrates-open-source-vitess-test-suite-from-python-to-go), and we’ve improved the health of the code base by removing a lot of legacy code specific to Statement-Based Replication and “V2” query routing.

There is a slightly higher number of incompatible changes than in prior releases, so we encourage you to spend a moment reading the [release notes](https://github.com/vitessio/vitess/releases/tag/v6.0.20-20200429).

Please download Vitess 6, and take it for a spin!
