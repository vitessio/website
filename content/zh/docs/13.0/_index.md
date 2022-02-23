---
title: v13.0 (Stable)
description: Latest stable release. 因为这些文档不维护，所以它们是旧的。你想了解的有关世界上最具扩展性的开源MySQL平台的一切，都在这里
notoc: true
cascade:
  version: v13.0
weight: 1000
---

Vitess是一个用于部署、扩展和管理大型MySQL实例集群的数据库解决方案。它可以运行在本地硬件环境、私有云、公用云架构上，效率相差无几。

## Vitess 和 MySQL

Vitess集Mysql数据库的很多重要特性和NoSQL数据库的可扩展性于一体。 Vitess可以帮助您解决各种问题，包括：

1. 支持您对MySQL数据库进行分片来扩展MySQL数据库，应用程序无需做太多更改。
2. 从物理机迁移到私有云或公共云。
3. 部署和管理大量的MySQL实例。

## Vitess 数据库驱动

Vitess包括使用与本机查询协议兼容的[JDBC](https://github.com/vitessio/vitess/tree/master/java) 和[Go](https://godoc.org/vitess.io/vitess/go) (Golang)数据库驱动。此外，它还实现了[mysql服务器协议](https://dev.mysql.com/doc/internals/en/client-server-protocol.html)，该协议几乎与任何其他语言都兼容。

## Vitess 在行动

自2011年以来，Vitess一直为YouTube所有的数据库提供服务，现在已被许多企业采用并应用于实际生产。
