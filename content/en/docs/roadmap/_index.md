---
title: Roadmap
description: Upcoming features planned for development
weight: 10011
---

As an open source project, Vitess is developed by a community of contributors. Many of the contributors run Vitess in production, and add features to address their specific pain points. As a result of this, we can not guarantee that the features listed here will be implemented in any specific order.

{{< info >}}
If you have a specific question about the Roadmap, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

Last Updated: Jan 7, 2025

## Short Term (1-4 months)

- Query serving
  - Support more MySQL Syntax (improve compatibility as a drop-in replacement)
  - Performance improvements
  - Views GA
  - Better visibility through metrics
- Improve Usability
  - Use viper framework to implement dynamic flags
- VReplication
  - Benchmarking
  - Performance improvements
  - Improve unit test coverage
  - Deprecate vtctlclient
- VTAdmin
  - VReplication
  - Schema Management
- Throttler
  - Multi-metrics
- Online DDL
  - Range partition management
- VTOrc
  - Stalled Disk recovery
- Vitess operator
  - Multiple namespaces
  - Improve and document rollouts
  - Support for node draining

## Medium / Long Term (4-18 months)

- MySQL compatibility
  - Support more frameworks
  - Window Functions, JSON_TABLE etc.
- Query Serving improvements
  - Cost-based optimization
- VT/VExplain tooling to help with migration into Vitess
- VTAdmin UI enhancements
- Read-After-Write consistency
- Read Isolation
- Cross-shard Foreign Key support
