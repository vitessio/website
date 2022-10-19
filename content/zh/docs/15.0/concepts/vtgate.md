---
title: VTGate
---

VTGate是一个轻量级的代理服务器，它将流量导向正确的VTTablet服务器并将综合结果返回给客户。它同时使用MySQL协议和Vitess gRPC协议。因此，您的应用程序可以像连接MySQL服务器一样连接VTGate。

在将查询路由到适当的VTTablet服务器时，VTGate会考虑分片方案、所需的延迟、表的可用性以及其底层MySQL实例

相关的Vitess文档。

[Execution Plans](../execution-plans)
