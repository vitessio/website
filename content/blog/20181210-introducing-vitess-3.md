---
author: "Adrianna Tan"
published: 2018-12-09T07:35:00-07:00
slug: "2018-12-09-introducing-vitess-3.0"
tags: ['Major Versions, Announcements']
title: "Vitess Weekly Digest - Nov 12 2018"
---

We are pleased to announce Vitess 3.0, a major upgrade from Vitess 2.2. Every major release of Vitess brings new features and improvements for our community, and also sometimes introduces new ways of doing things.

Vitess 3.0 is built using “pure” go 1.11 (we do not need cgo now) and supports MySQL 8.0 and MariaDB 10.3.

The key features of Vitess 3.0 are:

* Usability
    * Simplified db parameters for vttablet
    * Formal support for externally managed mysql
    * More tutorials including how to run Vitess with Minikube
* Prometheus monitoring
* Performance improvements
    * Snappier InitShardMaster and PlannedReparentShard
    * Improved coordination with Orchestrator
    * vtbench for benchmarking
    * MySQL protocol performance improvements
    * Faster reparents
    * 4X faster parallelized backups
    * Many more performance improvements
* VReplication
* Improvements to resharding

We first showcased VReplication at the first ever Vitess meetup held at Slack in July 2018. One of Vitess’s superpowers has always been its ability to consume the MySQL binary replication log, apply sharding logic to it, and use it for transparent resharding. Now we have taken the same functionality and made it composable so that it can be used for cross-shard materialized views. This enables exciting functionality such as roll-ups and aggregates, in quasi-real time (of the order of replication lag).

We are really excited about this and we see practical applications of VReplication such as:

* Companies ingesting large time-series data who would mostly need to query roll ups and aggregates
* All types of companies that want the flexibility to not worry about being stuck with their original sharding key. VReplication allows you the ability to make changes to your sharding key as your product evolves. In fact the internal name for this feature for a long time was “the regret feature” :).

As with any major version upgrade, we recommend that you follow our [upgrading guide](../docs/user-guides/upgrading/). Reach out to the Vitess community on [our Slack channel](https://vitess.slack.com) (or click the Slack icon in the top right to join) at any time for assistance and discussion. We welcome everyone to our community.

Head on over to [check out Vitss 3.0](https://github.com/vitessio/vitess/release) now.
