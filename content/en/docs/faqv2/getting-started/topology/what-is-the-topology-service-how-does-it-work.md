---
title: "What is the topology service? How does it work?"
shorten_nav_links: true
notoc: true
weight: 1
---

The Topology Service is a set of backend processes. This service is exposed to all Vitess components. It delivers a key/value service that is highly available and consistent, while being offset by having higher latency cost and very low throughput. The Topology Service is used for several things by Vitess:

* It enables tablets to coordinate among themselves as a cluster.
* It enables VTGate to discover tablets, so it knows where to route queries.
* It stores Vitess configuration provided by the administrator which is required by the different components in the Vitess cluster and that must persist between server restarts.

The main functions the Topology Service provides are:

* It is both a repository for topology metadata and a distributed lock manager. 
* It is used to store configuration data about the Vitess cluster. It stores small data structures (a few hundred bytes) per object.
	* E.g. information about the Keyspaces, the Shards, the Tablets, the Replication Graph, and the Serving Graph. 
* It supports a watch interface that signals a client when changes occur on an object. This is used, for instance, by VTGate to know when the VSchema changes.
* It supports primary election.
* It supports quorum reads and writes.
