---
title: Vitess 路线图
description: Upcoming features planned for development
weight: 2
---

Vitess以开源方式发布。Vitess is developed by a 贡献者开发.许多贡献者run Vitess in production, and add features to address their specific pain points. 因此，我们不能保证以下 guarantee features listed here will be implemented in any specific order.

{{< info >}}
如果您对路线图有特点的问题, 我们建议您在 [Slack channel](https://vitess.slack.com)发布您的问题。您可点击在右上角的图标加入Slack. 我们的Slack群非常活跃，群员非常热亲。
{{< /info >}}

## 短期

- VReplication
  - 改进重新分片的工作流程。提高它的灵活性，速度和可靠性.
  - Materialized Views
  - VStream
- 支持时间点与位置恢复
- 把python测试源码改成Go
- 降低执行测试套件所需要的时间。（评估Travis CI的替代品）
- Adopt a [consistent 发布周期](https://github.com/vitessio/enhancements/blob/master/veps/vep-1.md) for new GAs of Vitess
- 改进文档
- 提高易用性

## 中期

- VReplication
  - 支持Schema Changes
  - Backfill lookup indexes
  - 支持 Data Migration
- 拓扑服务: 减少拓扑服务的dependencies。 i.e. 即使拓扑服务中断几个小时，我们还得正常使用Vitess. 拓扑服务 should be used only for passive discovery.
- 支持PostgreSQL: Vitess should be able to support PostgreSQL for both storing data, and speaking the protocol in VTGate.
