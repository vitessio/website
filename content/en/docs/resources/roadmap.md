---
title: Vitess Roadmap
description: Upcoming features planned for development
weight: 2
---

As an open source project, Vitess is developed by a community of contributors. Many of the contributors run Vitess in production, and add features to address their specific pain points. As a result of this, we can not guarantee features listed here will be implemented in any specfic order.

{{< info >}}
If you have a specific question about the Roadmap, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

## Short Term

- VReplication
  - Improve the resharding workflow (flexibility, speed and reliability)
  - Materialized Views
  - VStream (unified stream of events across shards and sharding events)
- Support for Prepared Statements
- Support for Point in Time Recovery
- Remove python dependency when running the testsuite (tests should be pure Go).
- Reduce the time required to execute the test suite (evaluate alternatives to Travis CI if it makes sense to switch.)
- Adopt a consistent release cycle for new GAs of Vitess
- Improve Documentation
- Improve Usability

## Medium Term

- VReplication
  - Support for Schema Changes
  - Backfill lookup indexes
  - Support for Data Migration
- Topo Server: Reduce dependencies on the topo server. i.e. Vitess should be operable normally even if topo server is down for several hours. Topo server should be used only for passive discovery.
- Support for PostgreSQL: Vitess should be able to support PostgreSQL for both storing data, and speaking the protocol in VTGate.
- Host more offline events for Vitess, including meetups and a summit for contributors.