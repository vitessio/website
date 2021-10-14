---
title: Vitess 路线图
description: Upcoming features planned for development
weight: 2
---

Vitess 以开源方式发布。Vitess 是由贡献者开发。许多贡献者在生产环境中使用 Vitess，并且在 Vitess 上增添功能来解决自己的问题。 因次我们不能保证以下功能将按固定顺序实现。

{{< info >}}
如果您对路线图有特定的问题， 我们建议您在 [Slack channel](https://vitess.slack.com)发布您的问题。您可点击在右上角的图标加入 Slack。 我们的 Slack 群非常活跃，群员非常热情。
{{< /info >}}

## 短期

- VReplication
  - 改进拆分的工作流。提高工作流的速度、灵活性和可靠性。
  - 实体化视图
  - VStream
- 支持时间点与位置恢复
- 把 Python 测试源码改成 Go
- 降低执行测试套件所需要的时间。（评估 Travis CI 的替代品）
- 采用一个[一致的发布周期](https://github.com/vitessio/enhancements/blob/master/veps/vep-1.md)
- 提高易用性

## 中期

- VReplication
  - 支持模式改变
  - 回填查找索引
  - 支持数据迁移
- 拓扑服务:减少对拓扑服务的依赖。例如 :即使拓扑服务中断几个小时，Vitess 需要正常运行。 拓扑服务只用于被动发现。
- Vitess 支持 后端使用 PostgreSQL 存储数据， vtgate 支持 PG 协议。
