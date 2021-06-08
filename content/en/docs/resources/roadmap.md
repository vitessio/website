---
title: Vitess Roadmap
description: Upcoming features planned for development
weight: 2
---

As an open source project, Vitess is developed by a community of contributors. Many of the contributors run Vitess in production, and add features to address their specific pain points. As a result of this, we can not guarantee features listed here will be implemented in any specific order.

{{< info >}}
If you have a specific question about the Roadmap, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

Last Updated: May 25, 2021

## Short Term (1-3 months)

- Improve Documentation
- Improve Usability
- Support more MySQL Syntax (improve compatibility as a drop-in replacement)
  - Certify popular frameworks like Ruby on Rails, Django etc.
- Nightly benchmarking (regression testing)
- VReplication
  - Performance
  - Usability
  - Online schema changes
- Technical debt
  - grpc
  - protobuf
  - golang 1.16

## Medium Term (3-9 months)

- MySQL compatibility
  - More frameworks
- Query Planning improvements
  - Performance
  - More supported queries
- Schema changes
  - Usability
- VSchema improvements
  - Vtgates auto-detect schema changes
- Vitess-native unplanned failovers (vtorc)
- Pluggable durability policies (vtorc)
- Rewrite of vtctld UI including visualization of VReplication
- VReplication throttling
- Topology Service: Reduce dependencies on the topology service. i.e. Vitess should be operable normally even if topology service is down for several hours. Topology service should be used only for passive discovery.
