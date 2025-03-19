---
title: "What is the Vitess Operator?"
shorten_nav_links: true
notoc: true
weight: 5
---

The Vitess Operator is open source and is on [GitHub](https://github.com/planetscale/vitess-operator). You can see the repository for information on licensing and contribution.

The Vitess Operator automates the management and maintenance work of Vitess on Kubernetes by automating the tasks below:

- Deploy any number of Vitess clusters, cells, keyspaces, shards, and tablets to scale both reads and writes either horizontally or vertically.
- Deploy overlapping shards for Vitess resharding, allowing zero-downtime resizing of shards.
- Trigger manual planned failover via Kubernetes annotation.
- Replicate data across multiple Availability Zones in a single Kubernetes cluster to support immediate failover of read/write traffic to recover from loss of an Availability Zone.
- Automatically roll out updates to Vitess-level user credentials.

For information on using the Vitess Operator with AWS please follow the link [here](https://docs.planetscale.com/vitess-operator/aws-quickstart). For Google Cloud Platform please follow the link [here](https://docs.planetscale.com/vitess-operator/gcp-quickstart).
