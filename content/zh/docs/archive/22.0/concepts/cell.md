---
title: Cell
description: 数据中心, 可用区域或计算资源组
---
一个Cell是指一个网络资源区域，在这个区域里，放置一组服务器或网络基础设施。它通常对应物理部署中的数据中心，有时称为*区域*或者*可用区域*。Cell的主要作用是网络隔离。Vitess可以优雅的处置Cell级别的网络故障，如果有其他的Cell故障并不会影响到当前Cell。


Vitess中的每个Cell里都有一个[本地拓扑服务托管服务集群](../topology-service)，本地拓扑服务负责存储和管理注册在此Cell下的所有网络资源的相关元数据信息。其中包括这个Cell下所有的路由及vttabelt的信息。这样的设计使得Cell更加易于模块化管理，方便拆卸和组装。


vitess支持跨Cell的读写操作，考虑如下情况，假设一个shard有3个实例，1主2从，其中一个master,一个replica，一个rdonly。同样有3个cell, A cell 、 B cell 、C cell,我们可以将master放在A cell， replica放在B cell, rdonly放在C cell。这样，当B cell由于机房故障或者网络故障不能提供服务的时候，我们仍然有master和rdonly提供服务，如果运气不好master节点所在机器或者机房故障，vitess的另一个神器orc可以自动发现deadmaster并进行故障迁移，将replica提升为主。从而实现异地灾备。

