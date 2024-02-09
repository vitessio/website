---
title: VStream
---

VStream是通过VTGate访问的变更通知服务。VStream的目的是提供等同于Vitess集群底层MySQL分片的MySQL二进制日志的信息。gRPC客户端，包括Vitess组件如VTTablets>，可以订阅VStream以接收来自其他分片的变更事件。VStream从一个或多个位于VTTablet实例上的VStreamer实例拉取事件，这些VStreamer实例反过来从底层MySQL实例的>    二进制日志中拉取事件。这允许高效执行如VReplication之类的功能，订阅者可以间接地从一个或多个MySQL实例分片的二进制日志接收事件，然后将其应用到目标实例。>    用户可以利用VStream获取关于给定Vitess键空间、分片和位置的数据变更事件的深入信息。单个VStream还可以整合来自键空间中多个分片的变更事件，使其成为一个方便
的工具，用于将变更数据捕获（CDC）过程从您的Vitess数据存储下游引导。

请参考下图：

![VStream diagram](/img/VStream.svg)

请注意：VStream与VStreamer是不同的。前者位于VTGate上，后者位于VTTablet上


