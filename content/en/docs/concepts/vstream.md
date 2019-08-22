---
title: VStream
---


VStream is a change notification system located on the VTGate. The VStream can be thought of as an UpdateStream customized for use within Vitess. As with the update stream, VTTablets can subscribe to a VStream to receive events. The VStream can pull events from a VStreamer which in turn pulls events from the binlog. This would allow for efficient execution of processes such as VReplication where a subscriber can indirectly receive and apply events from the binlog. A user can apply filtering rules to a VStream to obtain in depth information about what is going on under the hood at a given keyspace, shard, and position.




For reference, please refer to the diagram below:
![VStream](../../../../static/img/diagrams/VStream.png)

Note: Please note that a VStream is distinct from a VStreamer. The former is located on the VTGate and the latter is located on the VTTablet.
