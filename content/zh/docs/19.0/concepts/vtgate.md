---
title: VTGate
---

vtgate 是一个轻型代理服务器，它将流量路由到正确的vttablet，并将合并的结果返回给客户端。应用程序向vtgate发起查询。客户端使用起来非常简单，它只需要能够找到vtgate实例就能使vitess。

为了路由查询，vtgate综合考虑了分片方案、数据延迟以及vttablet及其对应底层MySQL实例的可用性。

相关Vitess文档

* [Execution Plans](../execution-plans)
