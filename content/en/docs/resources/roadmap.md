---
title: Vitess Roadmap
description: Upcoming features planned for development
weight: 2
---

As an open source project, Vitess is developed by a community of contributors. Many of the contributors run Vitess in production, and add features to address their specific pain points. As a result of this, we can not guarantee features listed here will be implemented in any specific order.

{{< info >}}
If you have a specific question about the Roadmap, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

Last Updated: Dec 13, 2022

## Short Term (1-3 months)

- Improve Documentation
- Improve Usability
  - Viper framework for flags
- Query serving
  - Support more MySQL Syntax (improve compatibility as a drop-in replacement)
    - Views
    - Better information_schema support
  - Improve error messages
  - New UI for [benchmarking](https://benchmark.vitess.io)
- VReplication
  - VDiff v2
  - Vtctld Server API including online DDL
  - Benchmarking
  - Performance improvements
- VTAdmin
  - Single component
  - Ease of deployment
  - More UIs
- Technical debt
  - Port VDiff tests to v2
  - Delete old web UI
  - VTOrc cleanup
  - Remove usage of deprecated VExec
- Vitess operator
  - Documentation
  - Kubernetes 1.25 support

## Medium / Long Term (3-18 months)

- MySQL compatibility
  - Support more frameworks
- Query Serving improvements
  - Performance
  - More supported queries
- Schema changes
  - Usability
- VTAdmin UI
  - VReplication
  - Schema Management
- VTOrc improvements
  - Reduce client downtime
- Read-After-Write consistency
- Distributed Transactions
