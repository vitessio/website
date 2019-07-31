---
title:  Keyspace graph
---

Vitess 使用*keyspace graph* 记录Cell下有多少keyspaces，每个keyspace下有多少shard，每个shard下有多少个tablet，每个tablet的类型是什么。

## Partitions
在水平拆分（将表数据通过路由重新打散到各个新分片的）过程中，会出现具有重叠范围的分片。例如，拆分的源分片范围“c0-d0”，而其目标分片的范围是“c0-c8”和“c8-d0”。

由于这些分片在迁移期间需要同时存在，因此keyspace graph维护一套分片的列表（也称分区)，其范围涵盖所有可能的keyspace ID值，同时不重叠且连续。分片可以移入和移出此列表确定它们是否有效。

keyspace Graph为每个`(cell，tablet type)` 对存储一个单独的分区。这允许迁移分阶段进行：首先迁移*donly*和*replica*请求，一次一个单元，最后迁移*master*请求。

## Served From

在垂直拆分期间（将源keyspace中的某个表移到新的keyspace中），多个keyspace会同时共存同样的表。

由于表S（表名）的多个副本需要在迁移期间同时存在，因此keyspace graph支持keyspace重定向，称为“ServedFrom”记录。这使得迁移流程如下：

1. 创建新的`keyspace B` 设置 `ServedFrom` 指向旧的`keyspace A`。
2. 更新应用程序配置，重启应用，从新的`keyspace B`中查找表S。 Vitess会自动重定向这些请求到旧的`keyspace A`上。
3. 执行垂直拆分，将数据复制到新的`keyspace B`上，静态数据追平后开启过滤复制，继续同步binglog产生的增量数据。
4. 删除`ServedFrom`，请求将重定向到`keyspace B`
5. 删除`keyspace A`中的表S.

对于每个 `(cell, tablet type)` 元组会有不同的`ServedFrom`追踪. 这允许迁移分阶段进行：首先迁移*rdonly*和*replica*请求，一次一个单元，最后迁移*master*请求。

