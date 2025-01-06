---
title: Overview
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

## How much resources (memory, CPU, disk) does Vitess use?

**CPU**

Vitess components (excluding the underlying MySQL server) tend to be CPU-bound processes. It is recommended to:

* Allocate 2-4 CPU cores for each VTGate server.
* And allocate the same number of cores for VTTablet as with MySQLd.
  * If you are provisioning for a new workload, we recommend projecting that MySQLd will require 1 core per 1500 QPS.

Assuming tablets are kept to the recommended size of 250GB:
* Start with a baseline CPU requirement of 2-4 cores for MySQLd
* And allocate 2-4 cores for the VTTablet process.

{{< info >}}
Note that this is very workload-dependent. We recommend testing the configuration for yourself as performance can vary depending on your query pattern, query size, concurrency, etc.
{{< /info >}}

**Memory**

The memory requirements for VTGate and VTTablet servers will depend on QPS and query result set sizes. We recommend:

* Provisioning a baseline of 1GB per core.
* Allocating additional memory if you are increasing the Vitess default row limits and/or expect many concurrent queries returning large result sets. Note that this may not be necessary if your large result set queries use streaming.

**Latency**

The impact of network latency can be a factor when migrating from MySQL to Vitess. A simple rule of thumb is to estimate 2ms of round trip latency added to each query.  This may be higher in a cloud environment, depending on your choice of load balancer, availability zone placement, etc.

**Topology Service**

For estimating CPU/memory/disk requirements of your chosen Topology Service, you can use the minimum requirements recommended by the topology server implementation.

## How do reparents work in Vitess?

Reparenting is the process of changing a shard’s primary tablet from one host to another or changing a replica tablet to have a different primary. Reparenting can be initiated manually or it can occur automatically in response to particular database conditions. Vitess supports two types of reparenting: [Active reparenting](https://vitess.io/docs/user-guides/configuration-advanced/reparenting/#active-reparenting) and [External reparenting](https://vitess.io/docs/user-guides/configuration-advanced/reparenting/#external-reparenting).
- Active reparenting occurs when Vitess manages the entire reparenting process. There are two types of active reparenting that can be done: [Planned reparenting](https://vitess.io/docs/user-guides/configuration-advanced/reparenting/#plannedreparentshard-planned-reparenting) and [Emergency reparenting](https://vitess.io/docs/user-guides/configuration-advanced/reparenting/#emergencyreparentshard-emergency-reparenting).
- External reparenting occurs when another tool handles the reparenting process, and Vitess just updates its components to accurately reflect the new primary-replica relationships.

You can read more about reparenting in Vitess [here](https://vitess.io/docs/user-guides/configuration-advanced/reparenting/).

