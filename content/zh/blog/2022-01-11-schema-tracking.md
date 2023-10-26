---
author: 'Florent Poinsard'
date: 2022-01-11
slug: '2022-01-11-schema-tracking'
tags: ['Vitess','CNCF', 'Schema', 'Tracking', 'Planner', 'Query', 'Serving', 'MySQL']
title: 'Vitess Schema Tracking'
description: "Insight into Vitess' Schema Tracking feature"
---

## What is Schema Tracking?

在像 Vitess 这样的分布式关系数据库系统中，由一个中心化组件负责跨多个分片提供查询服务。 对于 Vitess 来说，这个组件是 [VTGate](https://vitess.io/docs/concepts/vtgate/)。 
该组件面临的挑战之一是如何了解正在使用的底层 SQL schema，这些信息有助于查询规划。

表的 schema 存储在 MySQL 的 information_schema 表中，这意味着它们位于 [VTTablet](https://vitess.io/docs/concepts/tablet/) 管控的 MySQL 实例中，而不是 VTGate。
在规划查询时，VTGate 无法显式感知表的列定义(authoritative column list)，这种能力缺陷导致了下面列出的一些限制：

- 该查询是带有 order by 子句的跨分片查询。VTGate 需要创建一个计划，其中包含带有要排序的列的 order by 指令，如果不了解 schema，这是不可能的。

  ```sql
  SELECT * FROM tbl1, tbl2 WHERE tbl1.id = tbl2.id ORDER BY tbl1.name
  ```

- 在这个跨分片查询中，name 列不明确，我们不知道它属于哪个表。如果两个表中至少有一个具有 name 列，模式跟踪将告诉 VTGate，name 列属于哪个表，查询将不再含糊不清。
  
  ```sql
  SELECT name FROM tbl1, tbl2 WHERE tbl1.id = tbl2.id
  ```

- 由于这个查询是跨分片的，因此涉及到 VTGate 级别的 group by 操作。假设 tbl2.name 是一个文本列，那我们需要知道它的排序规则才能执行正确的字符串比较。 如果没有模式跟踪，这是不可能的，因为 VTGate 本身并不了解表的列排序规则。

  ```sql
  SELECT tbl2.name FROM tbl1, tbl2 WHERE tbl1.id = tbl2.id GROUP BY tbl2.name
  ```

仅当 VTGate 具有表的权威列定义时才能规划这些查询。在没有模式跟踪之前，可以使用 [VSchema](https://vitess.io/docs/concepts/vschema/) 来实现。
VSchema 允许我们为我们的表声明一个权威的列定义。
然而，这种技术并不完美，让我们看看为什么。

Vitess 拥有一些相当大规模的用户，例如 [Slack](https://slack.engineering/scaling-datastores-at-slack-with-vitess/) 和 [GitHub](https://github.blog/2021-09-27-partitioning-githubs-relational-databases-scale/)，他们使用数百或数千个分片，并由多个团队进行连续的 schema 更改，几乎不间断。
为了确保 VSchema 的持续权威性，他们需要在每次更改 MySQL schema 后更新其 VSchema，这绝对是不可持续的。
VSchema 缺乏可扩展性推动了模式跟踪功能的开发。

与上一代查询规划器 V3 相比，在[Gen4](https://vitess.io/blog/2021-11-02-why-write-new-planner/)我们开发了模式跟踪功能。
下一节将介绍这个新功能的工作原理。

## How does Schema Tracking work?

VTablet 会定期查询其底层 MySQL 数据库，以检测 schema 是否发生更改。
VTablet 在名为 schemacopy 的表中保留 schema 的副本，该表使用 VTablet 感知到的 SQL schema 的最新视图进行更新。
当比较 information_schema 和 schemacopy 表时，VTTablet 可以轻松检测到任何更改。
我们想要检测三种类型的变化：

- 新列
- 变更列
- 删除列

每一种变更检测都是使用特定的 SQL 查询来实现的。
例如，我们使用以下查询检测新列：

```sql
SELECT isc.table_name FROM information_schema.columns AS isc LEFT JOIN _vt.schemacopy AS c ON isc.table_name = c.table_name AND isc.table_schema = c.table_schema AND isc.ordinal_position = c.ordinal_position WHERE isc.table_schema = database() AND c.table_schema IS NULL
```

此查询的结果是一个表 (`isc.table_name`) 列表，与 schemacopy 表中列出的列相比，这些表具有新列。
如果用于检测 schema 更改的三个查询之一返回非空表列表，则在下一次发送到 VTGate 的健康检查数据包中包含更新表的列表。
一旦 VTGate 收到带有更新表列表的健康检查包，它就会将查询发送给该健康检查包的 VTablet，以获取每个更新表的实际元数据。
VTGate 发送针对 schemacopy 表的查询，如下所示：

```sql
SELECT table_name, column_name, data_type, collation_name FROM _vt.schemacopy WHERE table_schema = database() AND table_name IN ::tableNames ORDER BY table_name, ordinal_position
```

请注意，`::tableNames` 变量是我们通过健康检查收到的已更改表的列表。
有时，当我们收到的运行状况检查表明 VTablet 运行状况不佳时，下一次获取 schemacopy 表将要求对所有表进行更改，而不仅仅是运行状况检查响应中列出的表。
这允许完全重新加载键空间的 schema。

一旦 VTGate 更新了 schema 的本地视图，VSchema 就会使用新的权威列列表进行更新。
然后我们的查询规划器将使用这些列表。

如前所述，Vitess 的大规模部署可以在数千个分片上以非常高的节奏同时更改其 schema。
为了避免此类场景中的网络拥塞，Schema Tracker 在 VTGate 级别具有排队机制。
此机制将来自运行状况检查的所有传入模式更改排队，并以固定的时间间隔将所有不同的模式更改通知汇集到更新表的单个列表中。
这允许我们向 VTablet 发送单个查询来获取所有元数据更改。

## New capabilities

正如第一节中提到的，缺乏对 schema 的了解导致我们无法支持更多查询。
之前列出的不可能的查询现在是可以规划的。
通过模式跟踪，所有表的 schema 都变得具有权威性，而无需在 VSchema 中手动指定它们。

使用权威列列表的一个示例是`select *`的查询，
我们现在可以将`*`重写为实际的列列表，这简化了规划器的工作。

## Future Work

在新的 Vitess 集群中，默认情况下仍未启用架构跟踪，因为该功能仍处于实验阶段。
有关如何在 Vitess 集群上启用模式跟踪的更多信息，请参阅[文档](https://vitess.io/docs/reference/features/schema-tracking/)。

一旦我们对这个新功能建立了足够的信心并从用户那里得到了足够的反馈，我们将开始考虑它的第二个版本。
新版本可能包括当两个 VTablet 同时发送不同的更新列表时，冲突解决等功能。


译者注： issue#10455 已经默认启用模式跟踪选项。
