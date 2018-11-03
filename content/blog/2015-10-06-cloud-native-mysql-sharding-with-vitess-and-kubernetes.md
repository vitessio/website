---
author: "Anthony Yeh"
published: 2015-10-06T13:22:00-07:00
slug: "2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes"
tags: [ "kubernetes", "cloud", "sharding",]
title: "Cloud Native MySQL Sharding with Vitess and Kubernetes"
---
*Cross-posted on [Google Cloud Platform
Blog](http://googlecloudplatform.blogspot.com/2015/10/Cloud-Native-MySQL-Sharding-with-Vitess-and-Kubernetes.html).*  

[Cloud native](https://cncf.io/) technologies like [Kubernetes](http://kubernetes.io/) help you compose scalable services out of a sea of small logical units. In our [last
post](http://googlecloudplatform.blogspot.com/2015/03/scaling-MySQL-in-the-cloud-with-Vitess-and-Kubernetes.html), we introduced [Vitess](http://vitess.io/)(an open-source project that powers YouTube's main database) as a way of turning MySQL into a scalable Kubernetes application. Our goal was to make scaling your persistent datastore in Kubernetes as simple as scaling stateless app servers - just run a single command to launch more [pods](https://github.com/kubernetes/kubernetes/blob/release-1.0/docs/user-guide/pods.md). We've made a lot of progress since then (pushing over 2,500 new commits) and we're nearing the first stable version of the new, cloud native Vitess.

**Vitess 2.0**

In preparation for the stable release, we've begun to publish alpha builds
of [Vitess v2.0.0](https://github.com/youtube/vitess/releases). Some highlights of what's new since our earlier post include:

* Using the final Kubernetes 1.0 API.
* Official Vitess client [libraries](http://vitess.io/user-guide/client-libraries.html) in Java, Python, PHP, and Go.
  * Java and Go clients use the new HTTP/2-based [gRPC](http://www.grpc.io/) framework.
* Can now run on top of MySQL 5.6, in addition to MariaDB 10.0.
* New administrative dashboard built on AngularJS.
* Built-in backup/restore</span>](http://vitess.io/user-guide/backup-and-restore.html), designed to plug into blob stores like [Google Cloud Storage](https://cloud.google.com/storage/).
* GTID-based [reparenting](http://vitess.io/user-guide/reparenting.html) for reversible, routine failovers.
* Simpler [schema changes](http://vitess.io/user-guide/schema-management.html).

We've also been hard at work adding lots more [documentation](http://vitess.io/user-guide/introduction.html). In particular, the rest of this post will explore one of our new walkthroughs that demonstrates transparent [resharding](http://vitess.io/user-guide/sharding.html#resharding) of a live database - that is, changing the number of shards without any code changes or noticeable downtime for the application.

**Vitess Sharding**

[Sharding is bitter medicine](https://eng.asana.com/2015/04/sharding-is-bitter-medicine/), as S. Alex Smith wrote. It complicates your application logic and multiplies your database administration workload. But sharding is especially important when running MySQL in a cloud environment, since a single node can only become so big. Vitess takes care of shard routing logic, so the data-access layer in your application stays simple. It also automates per-shard administrative tasks, helping a small team manage a large fleet.

The preferred sharding strategy in Vitess is what we call [range-based shards>](http://vitess.io/user-guide/sharding.html#range-based-sharding). You can think of the shards as being like the buckets of a hash table. We decide which bucket to place a record in based solely on its key, so we don't need a separate table that keeps track of which bucket each key is in.

To make it easy to change the number of buckets, we use [consistent hashing](https://en.wikipedia.org/wiki/Consistent_hashing). That means instead of using a hash function that maps each key to a bucket number, we use a function that maps each key to a randomly distributed (but consistent) value in a very large set - such as the set of all 8-byte sequences. Then we assign each bucket a range of these
values, which we call [keyspace IDs](http://vitess.io/overview/concepts.html#keyspace-id).

**Transparent Resharding**

If you want to follow along with the new [resharding walkthrough](http://vitess.io/user-guide/sharding-kubernetes.html), you'll need to first bring up the cluster as described in the [unsharded guide](http://vitess.io/getting-started/). Both guides use the same [sample app](https://github.com/youtube/vitess/tree/master/examples/kubernetes/guestbook), which is a Guestbook that supports multiple, numbered pages.

![Guestbook page 72 screenshot](../images/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B5.png)

In the [sample app code](https://github.com/youtube/vitess/blob/master/examples/kubernetes/guestbook/main.py), you'll see a `get\_keyspace\_id()` function that transforms a given page number to the set of all 8-byte sequences, establishing the mapping we need for consistent hashing. In the unsharded case, these values are stored but not used. When we introduce sharding, page numbers will be evenly distributed (on average) across all the shards we create, allowing the app to scale to support arbitrary amounts of pages.

Before resharding, you'll see a single [custom shard](http://vitess.io/user-guide/sharding.html#custom-sharding) named "0" in the Vitess dashboard. This is what an unsharded [keyspace](http://vitess.io/overview/concepts.html#keyspace) looks like.

![Guestbook dashboard screenshot](../images/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B1.png)

As you begin the [resharding walkthrough](http://vitess.io/user-guide/sharding-kubernetes.html),you'll bring up two new shards for the same keyspace. During resharding, the new shards will run alongside the old one, but they'll remain idle (Vitess will not route any app traffic to them) until you're ready to migrate. In the dashboard, you'll see all three shards, but only shard "0" is currently active.

![Guestbook test_keyspace image](../images/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B2.png)

Next, you'll run a few Vitess commands to [copy the schema and data](http://vitess.io/user-guide/sharding-kubernetes.html#copy-data-from-original-shard) from the original shard. The key to live migration is that once the initial snapshot copy is done, Vitess will automatically begin replicating fresh updates on the original shard to the new shards. We call this [filtered replication](http://vitess.io/user-guide/sharding.html#filtered-replication), since it distributes DMLs only to the shards to which they apply. Vitess also includes tools that compare the original and copied data sets, row-by-row, to [verify data
integrity](http://vitess.io/user-guide/sharding-kubernetes.html#check-copied-data-integrity).

Once you've verified the copy, and filtered replication has caught up to real-time updates, you can run the [migrate command](http://vitess.io/user-guide/sharding-kubernetes.html#switch-over-to-the-new-shards) which tells Vitess to atomically shift app traffic from the old shards to the new ones. It does this by disabling writes on the old masters, waiting for the new masters to receive the last events over filtered replication, and then enabling writes on the new masters. Since the process is automated, this typically only causes about a second of write unavailability.

Now you can[tear down the old shard](http://vitess.io/user-guide/sharding-kubernetes.html#remove-the-original-shard),
and verify that only the new ones show up in the dashboard.

![Guestbook dashboard image verify new shards](../images/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B4.png)

Note that we never had to tell the app that we were changing from one shard to two. The resharding process was completely transparent to the app, since Vitess automatically reroutes queries on-the-fly as the migration progresses.

At YouTube, we've used Vitess to transparently reshard (both [horizontally and vertically](http://vitess.io/user-guide/sharding.html#supported-operations)) nearly all of our MySQL databases within the last year alone, and we have still more on the horizon as we continue to grow. See the full [walkthrough instructions](http://vitess.io/user-guide/sharding-kubernetes.html) if you want to try it out for yourself.

**Scaling Benchmarks**

The promise of sharding is that it allows you to scale write throughput linearly by adding more shards, since each shard is actually a separate database. The challenge in achieving that separation while still presenting a simple, unified view to the application is to avoid introducing bottlenecks. To demonstrate this scaling in the cloud, we've integrated the Vitess client with a driver for the [Yahoo! Cloud Serving Benchmark](https://github.com/youtube/YCSB)(YCSB).

Below you can see preliminary results for scaling write throughput by adding more shards in Vitess running on [Google Container Engine](https://cloud.google.com/container-engine/). For this benchmark, we pointed YCSB at the [load balancer](http://kubernetes.io/v1.0/docs/user-guide/services.html#type-loadbalancer) for our Vitess cluster and told it to send a lot of INSERT statements.
Vitess took care of routing statements to the various shards.

[![](../images/thumbnails/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B3.png)](../images/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B3.png)

The max throughput (QPS) for a given number of shards is the point at which round-trip write latency became degraded, which we define as &gt;15ms on average or &gt;50ms for the worst 1% of queries (99th percentile).

We also ran YCSB's "read mostly" workload (95% reads, 5% writes) to show how Vitess can scale read traffic by adding replicas. The max throughput here is the point at which round-trip read latency became degraded, which we define as &gt;5ms on average or &gt;20ms for the worst 1% of queries.

![Guestbook image](../images/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B6.png)

There's still a lot of room to improve the benchmarks (for example, by tuning the performance of MySQL itself). However, these preliminary results show that the returns don't diminish as you scale. And since you're scaling horizontally, you're not limited by the size of a single machine.

**Conclusion**

With the new cloud native version of Vitess moving towards a stable launch, we invite you to [give it a try](http://vitess.io/getting-started/) and let us know what else you'd like to see in the final release. You can reach us either on our [discussion forum](https://groups.google.com/forum/#!forum/vitess), or by filing an issue on [GitHub](https://github.com/youtube/vitess). If you'd like to be notified of any updates on Vitess, you can subscribe to our low-frequency [announcement list](https://groups.google.com/forum/#!forum/vitess-announce).  

*-Posted By Anthony Yeh, Software Engineer, YouTube*
