---
title: Vitess Roadmap
description: Upcoming features planned for development
weight: 2
---

As an open source project, Vitess is developed by a community of contributors. Many of the contributors run Vitess in production, and add features to address their specific pain points. As a result of this, we can not guarantee that the features listed here will be implemented in any specific order.

{{< info >}}
If you have a specific question about the Roadmap, we recommend posting in our [Slack channel](https://vitess.slack.com), click the Slack icon in the top right to join. This is a very active community forum and a great place to interact with other users.
{{< /info >}}

Last Updated: Jan 16, 2024

## Short Term (1-4 months)

- Query serving
  - Support more MySQL Syntax (improve compatibility as a drop-in replacement)
    - Better information_schema support
  - Improve error messages
  - Foreign Key constraints
- Improve Usability
  - Viper framework for flags
- VReplication
  - Benchmarking
  - Performance improvements
  - Migrating data with Foreign Key constraints
- VTAdmin
  - Schema management APIs

## Medium / Long Term (4-18 months)

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
- Vitess operator
  - Documentation
- Read-After-Write consistency
- Distributed Transactions
