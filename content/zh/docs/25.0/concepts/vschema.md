---
title: VSchema
---

[VSchema]（../../schema-management/vschema/）用于描述如何在keyspace和分片中存储数据。Vschma用于带路由键的SQL查询，也用于拆分分片操作。

对于keyspace，你可以指定它是否分片。对于分片的keyspace来说，你可以指定每张表的vindexes(路由键)。

Vitess支持[全局自增键](../../schema-management/vschema/#sequences)
可以用来生成像MySQL自动序列一样的全局唯一ID。 你可以设定表的某列是全局自增的列。写入时不加此列写入，VTGate会使用全局唯一自增功能为其生成全局唯一ID。

