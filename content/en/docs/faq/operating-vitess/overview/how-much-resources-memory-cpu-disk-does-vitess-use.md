---
title: "How much resources (memory, CPU, disk) does Vitess use?"
shorten_nav_links: true
notoc: true
weight: 6
---

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
