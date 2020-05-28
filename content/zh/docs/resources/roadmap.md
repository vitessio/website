---
title: Vitess 路线图
description: Upcoming features planned for development
weight: 2
---

Vitess以开源方式发布。Vitess是由贡献者开发。许多贡献者用Vitess在生产环境中。他们在Vitess上增添功能来解决自己的问题。 因次我们不能保证以下功能将按固定顺序实现。

{{< info >}}
如果您对路线图有特点的问题， 我们建议您在 [Slack channel](https://vitess.slack.com)发布您的问题。您可点击在右上角的图标加入Slack。 我们的Slack群非常活跃，群员非常热亲。
{{< /info >}}

## 短期

- VReplication
  - 改进重新分片的工作流程。提高它的灵活性，速度和可靠性。
  - 实体化视图
  - VStream
- 支持时间点与位置恢复
- 把Python测试源码改成Go
- 降低执行测试套件所需要的时间。（评估Travis CI的替代品）
- 采用一个[一致的发布周期](https://github.com/vitessio/enhancements/blob/master/veps/vep-1.md)
- 提高易用性

## 中期

- VReplication
  - 支持模式改变
  - 回填查找索引
  - 支持数据迁移
- 拓扑服务: 减少拓扑服务的依赖项。i.e. 即使拓扑服务中断几个小时，我们还得正常使用Vitess。 拓扑服务  只适用于 Passive Discovery.
- 支持PostgreSQL： Vitess 应该支持 PostgreSQL来存储数据以及在VTGate用Postgres Protocol。
