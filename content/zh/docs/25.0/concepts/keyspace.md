---
title: Keyspace
---

 *keyspace*是逻辑上的数据库，在单片场景下，一个keyspace对应一个MYSQL集群。从Keyspace中读取数据和从一个MYSQL DataBase中读取数据很像。但是根据读取数据时不同的一致性要求，可以从一个master或者从一个replica读取数据。当一个keySpace被sharding成[多分片]（http://en.wikipedia.org/wiki/Shard_(database_architecture))，一个keyspace会对应多个MYSQL database。在这种情况下一个查询会被路由到一个或者多个shard上，这取决于请求的数据所在的位置。

从应用程序的角度来看，不管一个keyspace是单分片（1个Mysql集群）还是多分片(多个Mysql集群)，在keyspace上的所有操作，和操作普通MYSQL库没有任何区别，应用感知不到分片的概念。


