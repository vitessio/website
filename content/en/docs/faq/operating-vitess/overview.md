---
title: Overview
description: Frequently Asked Questions about Vitess
weight: 1
---

## Am I really limited to 250 GB as my tablet size? Why?

Vitess recommends provisioning shard sizes to approximately 250GB. This is not a hard-limit, and is driven primarily by the recovery time should an instance fail. With 250GB a full-recovery from backup is expected within less than 15 minutes. 

For most workloads this results in shards instances with relatively few CPU cores and lighter memory requirements, which tend to be more economical than running large instance sizes.

For more information there is an in depth blog article [here](https://vitess.io/blog/2019-09-03-why-250gb-shards/).

## How does Vitess work with AWS, Azure, GCP?

Vitess can run in virtual machines on AWS, Azure, and GCP or in Kubernetes on those platforms. Vitess can run in two different manners on those platforms using either Kubernetes on virtual machines or using cloud Kubernetes managed service in AWS EKS, Azure AKS, or GCP GKE.

## What are my options to run Vitess? 

Vitess can run on bare metal, virtual machines, and kubernetes. It also doesn’t matter if your preference is for on-premises or in the cloud as Vitess can accommodate either option.

## Does Vitess only work on Kubernetes?

Vitess runs on a lot of different options. Kubernetes is only one of the available options. Vitess can also be run on AWS, GCP and bare metal configurations.

## What is the Vitess Operator?

The Vitess Operator is open source and is on [GitHub](https://github.com/planetscale/vitess-operator). You can see the repository for information on licensing and contribution.

The Vitess Operator automates the management and maintenance work of Vitess on Kubernetes by automating the tasks below:

- Deploy any number of Vitess clusters, cells, keyspaces, shards, and tablets to scale both reads and writes either horizontally or vertically.
- Deploy overlapping shards for Vitess resharding, allowing zero-downtime resizing of shards.
- Trigger manual planned failover via Kubernetes annotation.
- Replicate data across multiple Availability Zones in a single Kubernetes cluster to support immediate failover of read/write traffic to recover from loss of an Availability Zone.
- Automatically roll out updates to Vitess-level user credentials.

For information on using the Vitess Operator with AWS please follow the link [here](https://docs.planetscale.com/vitess-operator/aws-quickstart). For Google Cloud Platform please follow the link [here](https://docs.planetscale.com/vitess-operator/gcp-quickstart). 