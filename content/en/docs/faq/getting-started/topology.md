---
title: Topology
description: Frequently Asked Questions about Vitess
weight: 4
---

## What is the topology service? How does it work?

The Topology Service is a set of backend processes. This service is exposed to all Vitess components. It delivers a key/value service that is highly available and consistent, while being offset by having higher latency cost and very low throughput. The Topology Service is used for several things by Vitess:

* It enables tablets to coordinate among themselves as a cluster.
* It enables Vitess to discover tablets, so it knows where to route queries.
* It stores Vitess configuration provided by the database administrator which is required by the different components in the Vitess cluster and that must persist between server restarts.

The main functions the Topology Service provides are:

* It is both a repository for topology metadata and a distributed lock manager. 
* It is used to store configuration data about the Vitess cluster. It stores small data structures (a few hundred bytes) per object.
	* E.g. information about the Keyspaces, the Shards, the Tablets, the Replication Graph, and the Serving Graph. 
* It supports a watch interface that signals a client when changes occur on an object. This is used, for instance, to know when the keyspace topology changes (e.g. for resharding).
* It supports primary election.
* It supports quorum reads and writes.

## What Topology servers can I use with Vitess?

Vitess uses a plugin implementation to support multiple backend technologies for the Topology Service. The servers currently supported are as follows:
* etcd
* ZooKeeper
* Consul

The Topology Service interfaces are defined in our code in go/vt/topo/, specific implementations are in go/vt/topo/<name>, and we also have a set of unit tests for it in go/vt/topo/test.

{{< info >}}
If starting from scratch, please use the zk2 (ZooKeeper) or etcd2 (etcd) implementations. The Consul implementation is deprecated, although still supported.
{{< /info >}}

## How do I choose which topology server to use?

The first question to consider is: Do you use one already or are you required to use a specific one? If the answer to that question is yes, then you should likely implement that rather than adding a new server to run Vitess.

If the answer to that question is no, then we’d recommend that you use etcd if you can, otherwise we’d recommend that you use ZooKeeper. 

We recommend that you try not to use Consul, if possible.

## How do I implement etcd (etcd2)?

If you want to implement etcd we recommend following the steps on Vitess’ documentation [here](https://vitess.io/docs/reference/features/topology-service/#etcd-etcd2-implementation-new-version-of-etcd).

## How do I implement Zookeeper zk2?

If you want to implement zk2 we recommend following the steps on Vitess’ documentation [here](https://vitess.io/docs/reference/features/topology-service/#zookeeper-zk2-implementation).

## How do I migrate between implementations?

We provide the topo2topo utility to migrate between one implementation and another of the topology service. 

This process is explained in Vitess’ documentation [here](https://vitess.io/docs/reference/features/topology-service/#migration-between-implementations).

If your migration is more complex, or has special requirements, we also support a ‘tee’ implementation of the topo service interface. It is defined in go/vt/topo/helpers/tee.go. It allows communicating to two topo services, and the migration uses multiple phases.

This process is explained in Vitess’ documentation [here](https://vitess.io/docs/reference/features/topology-service/#migration-using-the-tee-implementation).