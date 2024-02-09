---
title: Topology Service
description: 拓扑或分布式锁服务
---

[*拓扑服务*](../../user-guides/topology-service)是一个包含服务器信息、分片方案和主从信息的元数据信息存储服务。拓扑服务是基于一致性存储方案来实现数据一致性， 例如：zookeeper和etcd。 用户可以通过使用vtctl（命令行）和vtctld（web）访问拓扑服务。


Vitess使用插件系统来支持各种后端服务用于存储拓扑数据，为这些后端服务提供式分布式一致性键值存储。默认情况下[本地示例](../../tutorials/local)使用ZooKeeper插件，而[Kubernetes示例](../../tutorials/kubernetes)使用etcd。

使用拓扑服务有以下几个原因：

*Vitess*将tablets作为一个集群进行协调和管理。
*Vitess*使用拓扑服务用作服务发现，tablets会注册到拓扑服务中，Vitess从而知道一个查询请求路由到何处。
*拓扑服务存储数据库管理员设定的Vitess配置，该配置是群集中服务器共需的，并且必须保证持久性。


Vitess集群具有一个全局拓扑服务，并且每个cell中具有本地拓扑服务。由于*cluster*是一个重载项，并且一个Vitess集群通过每个Vitess集群都有自己的全局拓扑服务来区分，我们将每个Vitess集群称为**toposphere**。

## 全局拓扑服务

全局拓扑用以存储不频繁更改的Vitess范畴内的数据。具体来说，它包含有keyspaces和shard的数据以及每个shard的扮演master角色tablet的别名。

全局拓扑用于某些操作，包括reparent(重新设置master)和(resharding)重新拆分。按照设计原则，全局拓扑服务器使用不会太频繁。

为了避免一个cell down掉影响到全局拓扑的服务，全局拓扑服务需要在各个cell中部署有节点，确保有足够的节点以维持仲裁，提供服务。

## 本地拓扑服务

每个本地拓扑里存储了与其自己所属cell的相关信息。具体来说，它包含cell中所有tablet的数据，该cell的keyspace graph、replication graph也存储在本地拓扑里。

本地拓扑服务非常重要，它必须工作正常以供Vitess发现tablets的动向，在tablets注册和退出注册后能够及时的调整路由。值得注意的是，在提供查询的关键路径中并不涉及到调用拓扑服务，所以，及时本地拓扑服务暂时不能提供服务，仍然不影响Vitess提供正常的查询服务。

