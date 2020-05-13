---
title: Vitess Roadmap
description: Upcoming features planned for development
weight: 2
---

As an open source project, Vitess is developed by a community of contributors. Many of the contributors run Vitess in production, and add features to address their specific pain points. As a result of this, we can not guarantee features listed here will be implemented in any specific order.

{{< info >}}
If you have a specific question about the Roadmap, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

## Short Term

- Support for Point in Time Recovery
- Improve Documentation
- Improve Usability
- Support more MySQL Syntax (improve compatibility as a drop-in replacement)
- VReplication
  - Support "Dry Run"
- Componentize Tablet Server (lift restriction on one-tablet per MySQL schema)

## Medium Term

- VReplication
  - Support for Schema Changes
  - Backfill lookup indexes
  - Support for Data Migration
- Topology Service: Reduce dependencies on the topology service. i.e. Vitess should be operable normally even if topology service is down for several hours. Topology service should be used only for passive discovery.
- Support for PostgreSQL: Vitess should be able to support PostgreSQL for both storing data, and speaking the protocol in VTGate.
