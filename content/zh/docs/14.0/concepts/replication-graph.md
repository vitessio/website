---
title: Replication Graph
---

*replication graph*标识master与其相关replicas间的关系。在master故障切换后，replication graph可以使Vitess将所有replicas指向的新的master,组成新的集群提供服务,保持主从复制。


