---
title: Tablet
---

*tablet*是`mysqld`进程和相应的`vttablet`进程的组合，通常在同一台机器上运行。

每个tablet都分配了*tablet type*，用于指定当前table的角色。

## Tablet Types

* **master** - *master* tablet是其所在分片的MySQL主.
* **replica** - 一个有资格被提升为*master*的MySQL slave。通常，replica角色用于提供面向用户的实时请求服务（例如来自网站的前端请求）。
* **rdonly** - 一个无法升级为*master*的MySQL slave。通常，这些用于后台处理作业，例如进行备份，将数据转储到其他系统，重度分析查询，MapReduce和重新分片。
* **backup** - 已经停止复制的tablet，因此可以用作为此分片上传备份数据。当数据备份完成后，它将恢复binlog复制并恢复到其先前的tablet类型。
* **restore** - tablet启动时没有数据，正在从最新备份恢复时的状态。这是一个过渡的状态，当tablet拉取备份并恢复完成后，它会从备份数据中的GTID位置开始追平数据延迟，并成为*replica*或*rdonly*（与Tablet做备份恢复之前的状态保持一致）。
* **drained** - 由Vitess后台程序用到的tablet状态，例如用于重新分片时候，rdonly tablet会变成drained状态，在重新分片过程结束之后，tablet会重新被置回rdonly状态。