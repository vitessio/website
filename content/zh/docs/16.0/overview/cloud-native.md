---
title: 私有云
---

Vitess非常适合云部署，因为它使数据库能够逐步增加容量。运行Vitess的最简单方法是通过Kubernetes。

## Vitess on Kubernetes

Kubernetes是Docker容器的开源编排系统，Vitess可以作为Kubernetes的云原生分布式数据库运行。

Kubernetes负责在计算集群中节点上进行资源调度，并主动管理这些节点的负载。并将包含应用程序的容器分组以便于管理和发现。这为Vitess在YouTube上运行的方式提供了类似的开源环境，这是Kubernetes的前身。

**相关的Vitess文档**

* [Kubernetes 快速入门](../../get-started/kubernetes)

