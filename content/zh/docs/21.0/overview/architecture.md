---
title: 架构 
weight: 2
featured: true
---

Vitess平台由许多服务器进程、命令行实用程序和基于Web的实用程序组成，由一致的元数据存储提供支持。

根据您当前的业务状态，您可以选择不同的方式最终实现vitess的完整部署。举例来说，如果是从头开始构建服务，那么使用Vitess的第一步就是定义数据库拓扑。如果是扩展现有的数据库， 那么可能需要先部署连接代理。

无论您是从一整套数据库开始，还是决定从小规模开始(今后再慢慢扩展)。Vitess工具和服务器都能贴心的帮助到您。对于较小规模的数据库，vttablet功能（如连接池和查询重写）可帮助您从现有硬件中榨取更多性能。对于大规模的数据库，Vitess提供的自动化工具在为更大规模的实施时给予更多的便利。

下图说明了Vitess的组件

![Vitess Overview Architecture Diagram](../img/VitessOverview.png)

## Topology

[拓扑服务](../../user-guides/topology-service) 一个元数据存储，包含有关正在运行的服务器、分片方案和复制图的信息。拓扑由一致的数据存储支持。您可以使用**vtctl** (命令行) 和 **vtctld** (web)查看拓扑.

在Kubernetes中，数据存储是etcd。 Vitess源代码还附带[Apache ZooKeeper](http://zookeeper.apache.org/)支持。

## vtgate

**vtgate** 是一个轻型代理服务器，它将流量路由到正确的vttablet，并将合并的结果返回给客户端。应用程序向vtgate发起查询。客户端使用起来非常简单，它只需要能够找到vtgate实例就能使vitess。

为了路由查询，vtgate综合考虑了分片方案、数据延迟以及vttablet及其对应底层MySQL实例的可用性。

## vttablet

**vttablet** 是一个位于MySQL数据库前面的代理服务器。vitess实现中每个MySQL实例都有一个vttablet。

执行的任务试图最大化吞吐量，同时保护mysql不受有害查询的影响。它的特性包括连接池、查询重写和重用重复数据。此外，vtTablet执行vtcl启动的管理任务，并提供用于过滤复制和数据导出的流式服务。

通过在MySQL数据库前运行vttablet并更改您的应用程序以使用Vitess客户端而不是MySQL驱动程序，您的应用程序将受益于vttablet的连接池，查询重写和重用数据集等功能。

## vtctl

**vtctl** vtctl是一个用于管理Vitess集群的命令行工具。它允许用户或应用程序轻松地与Vitess实现交互。使用vtctl，您可以识别主数据库和副本数据库，创建表，启动故障转移，执行分片（和重新分片）操作等。

当vtctl执行操作时，它会根据需要更lockserver。其他Vitess服务器会观察这些变化并做出相应的反应。例如，如果使用vtctl故障转移到新的主数据库，则vtgate会查看更改并将将写入流量切到新主服务器。

## vtctld

**vtctld** vtctld是一个HTTP服务器，允许您浏览存储在lockserver中的信息。它对于故障排除或获取服务器及其当前状态的高层概观非常有用。

## vtworker

**vtworker** 托管长时间运行的进程。它支持插件架构并提供代码库，以便您可以轻松选择要使用的vttablet。插件可用于以下类型的作业：

* 水平拆分或合并过程中检查数据的完整性
* 垂直拆分或合并过程中检查数据的完整性

vtworker还可以让您轻松添加其他验证程序。例如，如果一个keyspace中的索引表引用到另一keyspace中的数据，则可以执行片内完整性检查以验证类似外键的关系或跨分片完整性检查。

