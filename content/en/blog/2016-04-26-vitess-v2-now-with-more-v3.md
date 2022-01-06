---
author: "Anthony Yeh"
published: 2016-04-26T14:05:00-07:00
slug: "2016-04-26-vitess-v2-now-with-more-v3"
tags: [ "conference", "release", "sharding",]
title: "Vitess V2: Now with more V3"
---
Starting with [Vitess v2.0.0-beta.2](https://github.com/youtube/vitess/releases/tag/v2.0.0-beta.2), the VTGate V3 API can route complex single-shard queries (containing joins, subqueries, aggregation, sorting, and any combination thereof) as well as perform cross-shard joins. That means you no longer need to tell VTGate the [keyspace ID](https://vitess.io/docs/12.0/concepts/keyspace-id/) that a query targets, as you did with the VTGate V2 API.  

The fact that keyspace IDs are now hidden from the application has enabled drop-in Vitess libraries for standard database interfaces like [JDBC](https://github.com/youtube/vitess/blob/master/java/example/src/main/java/com/youtube/vitess/example/VitessJDBCExample.java) (written by [Flipkart](http://www.flipkart.com/)), [PDO](https://github.com/pixelfederation/vitess-php-pdo) (written by [Pixel Federation](http://pixelfederation.com/)), [PEP 249](https://github.com/youtube/vitess/blob/master/examples/kubernetes/guestbook/main.py), and [database/sql](https://godoc.org/github.com/youtube/vitess/go/vt/vitessdriver).
We've also made it possible to do resharding without having to add a keyspace ID column to your tables, which means no more schema changes and column back-fills when migrating existing databases to Vitess.  

To show off these new features, we recently gave a talk at [Percona Live 2016](https://www.percona.com/live/data-performance-conference-2016/sessions/vitess-complete-story) (no video unfortunately, but [the slides are posted](http://vitess.io/resources/presentations.html)) in which we did a live demo of resharding [an app that's completely unaware of sharding](https://github.com/youtube/vitess/blob/master/examples/kubernetes/guestbook/main.py). The [Sharding in Kubernetes](http://vitess.io/user-guide/sharding-kubernetes.html) guide has been updated for the new flow, so you can try it yourself.  

In the talk, we also described how VTGate V3 works under the hood, and how it evolved to encapsulate sharding - hiding more and more of the complexity of scaling from applications:  

**Evolution of VTGate**  

**Vitess 1.0**

* No VTGate: App determines which shard it needs, and talks directly to that shard.

**Vitess 2.0**

* VTGate V1: App determines which shard it needs, and asks VTGate to route to that shard.
* VTGate V2: App computes the [keyspace ID](https://vitess.io/docs/12.0/concepts/keyspace-id/). VTGate determines which shard that ID lives on (which can change during resharding) and routes there.
* VTGate V3: App sends queries as if the DB is unsharded. VTGate computes the keyspace ID, determines which shard(s) the requested data live on, and routes there.

One of the most common questions we get is, "When will Vitess 3.0 be out so we can use the V3 API?" Hopefully the summary above makes the answer more clear: *V3 is here now*. In fact, VTGate V1 and V2 are not going away; they're just different modes of talking to VTGate, and each still has valid use cases.  

The confusion was caused by our unfortunate naming choices for these features, and was made worse as we started abbreviating "VTGate V3" to just "V3" over time. In our defense, naming things is known to be one of the few [truly hard problems in computer science](http://martinfowler.com/bliki/TwoHardThings.html). Going forward, we hope to fix this by giving more descriptive names to the different VTGate modes, and revamping the documentation to reflect those new names. In the meantime, please let us know on [our mailing list](https://groups.google.com/forum/#!forum/vitess) if you have any
other questions or suggestions.
