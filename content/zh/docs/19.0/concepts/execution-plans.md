---
title: Execution Plan
---

Vitess在VTGate和VTTablet层面对查询进行解析，目的是找到执行查询的最优方式。这一过程称为查询规划，其结果是生成一份"Execution Plan"。

这个"Execution Plan"既取决于查询本身，也依赖于相关的VSchema。Vitess规划策略目标之一是尽量将工作量下推至底层的MySQL实例。当无法实现下推时，Vitess会采取一种方案，通过汇总多个来源的输入，合并结果，以得出正确的查询输出。
