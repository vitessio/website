---
title: Keyspace ID
---
*keyspace ID*是用于确定给定行所在的分片的值。 [基于范围的分片]（../../sharding/#key-ranges-and-partitions）是指创建分片，每个分片覆盖特定范围的keyspace ID。

使用此技术意味着您可以通过将两个或多个新分片替换为一个给定分片，这些分片组合起来覆盖原始范围的keyspace ID，而不必移动其他分片中的任何记录。

keyspace ID本身是使用数据中某些列的函数计算出来的，例如用户ID。 Vitess允许您从各种功能中选择（[vindexes]（../../ schema-management/vschema/））来执行映射规则。这允许您选择适合您业务场景的跨分片数据的最佳分布。


