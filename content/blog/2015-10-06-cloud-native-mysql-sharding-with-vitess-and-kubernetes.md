+++
author = "Anthony Yeh"
published = 2015-10-06T13:22:00-07:00
slug = "2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes"
tags = [ "kubernetes", "cloud", "sharding",]
title = "Cloud Native MySQL Sharding with Vitess and Kubernetes"
+++
*Cross-posted on [Google Cloud Platform
Blog](http://googlecloudplatform.blogspot.com/2015/10/Cloud-Native-MySQL-Sharding-with-Vitess-and-Kubernetes.html).*  
  
<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">[Cloud
native](https://cncf.io/)</span><span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">
technologies like </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">Kubernetes</span>](http://kubernetes.io/)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">
help you compose scalable services out of a sea of small logical units.
In our </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">last
post</span>](http://googlecloudplatform.blogspot.com/2015/03/scaling-MySQL-in-the-cloud-with-Vitess-and-Kubernetes.html)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">,
we introduced </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">Vitess</span>](http://vitess.io/)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">
(an open-source project that powers YouTube's main database) as a way of
turning MySQL into a scalable Kubernetes application. Our goal was to
make scaling your persistent datastore in Kubernetes as simple as
scaling stateless app servers - just run a single command to launch more
</span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">pods</span>](https://github.com/kubernetes/kubernetes/blob/release-1.0/docs/user-guide/pods.md)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">.
We've made a lot of progress since then (pushing over 2,500 new commits)
and we're nearing the first stable version of the new, cloud native
Vitess.</span>

<span
style="color: #434343; font-family: &quot;arial&quot;; font-size: 14.6667px; line-height: 1.38; white-space: pre-wrap;">  
</span>

<span
style="color: #434343; font-family: &quot;arial&quot;; font-size: 14.6667px; line-height: 1.38; white-space: pre-wrap;">**Vitess
2.0**</span>

<span
style="font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">In
preparation for the stable release, we've begun to publish alpha builds
of </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">Vitess
v2.0.0</span>](https://github.com/youtube/vitess/releases)<span
style="font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">.
Some highlights of what's new since our earlier post include:</span>

<span
style="font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">  
</span>

<span
style="font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">Using
the final Kubernetes 1.0 API.</span>

<span
style="font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">Official
</span>[<span
style="color: #1155cc; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">Vitess
client
libraries</span>](http://vitess.io/user-guide/client-libraries.html)<span
style="font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">
in Java, Python, PHP, and Go.</span>

-   <span
    style="font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">Java
    and Go clients use the new HTTP/2-based </span>[<span
    style="color: #1155cc; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">gRPC</span>](http://www.grpc.io/)<span
    style="font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">
    framework.</span>

<span
style="font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">Can
now run on top of MySQL 5.6, in addition to MariaDB 10.0.</span>

<span
style="font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">New
administrative dashboard built on AngularJS.</span>

<span
style="font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">Built-in
</span>[<span
style="color: #1155cc; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">backup/restore</span>](http://vitess.io/user-guide/backup-and-restore.html)<span
style="font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">,
designed to plug into blob stores like </span>[<span
style="color: #1155cc; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">Google
Cloud Storage</span>](https://cloud.google.com/storage/)<span
style="font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">.</span>

<span
style="font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">GTID-based
</span>[<span
style="color: #1155cc; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">reparenting</span>](http://vitess.io/user-guide/reparenting.html)<span
style="font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">
for reversible, routine failovers.</span>

<span
style="font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">Simpler
</span>[<span
style="color: #1155cc; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">schema
changes</span>](http://vitess.io/user-guide/schema-management.html)<span
style="font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">.</span>

<span style="font-family: &quot;arial&quot;;"><span
style="font-size: 14.6667px; line-height: 20.24px; white-space: pre-wrap;">  
</span></span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">We've
also been hard at work adding lots more </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">documentation</span>](http://vitess.io/user-guide/introduction.html)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">.
In particular, the rest of this post will explore one of our new
walkthroughs that demonstrates transparent </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">resharding</span>](http://vitess.io/user-guide/sharding.html#resharding)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">
of a live database - that is, changing the number of shards without any
code changes or noticeable downtime for the application.</span>  
<span id="more"></span>

<span
style="color: #434343; font-family: &quot;arial&quot;; font-size: 14.6667px; line-height: 1.38; white-space: pre-wrap;">  
</span>

<span
style="color: #434343; font-family: &quot;arial&quot;; font-size: 14.6667px; line-height: 1.38; white-space: pre-wrap;">**Vitess
Sharding**</span>

[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">Sharding
is bitter
medicine</span>](https://eng.asana.com/2015/04/sharding-is-bitter-medicine/)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">,
as S. Alex Smith wrote. It complicates your application logic and
multiplies your database administration workload. But sharding is
especially important when running MySQL in a cloud environment, since a
single node can only become so big. Vitess takes care of shard routing
logic, so the data-access layer in your application stays simple. It
also automates per-shard administrative tasks, helping a small team
manage a large fleet.</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">  
</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">The
preferred sharding strategy in Vitess is what we call </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">range-based
shards</span>](http://vitess.io/user-guide/sharding.html#range-based-sharding)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">.
You can think of </span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">the
shards as being like the buckets of a hash table. We decide which bucket
to place a record in based solely on its key, so we don't need a
separate table that keeps track of which bucket each key is in.</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">  
</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">To
make it easy to change the number of buckets, we use </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">consistent
hashing</span>](https://en.wikipedia.org/wiki/Consistent_hashing)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">.
That means instead of using a hash function that maps each key to a
bucket number, we use a function that maps each key to a randomly
distributed (but consistent) value in a very large set - such as the set
of all 8-byte sequences. Then we assign each bucket a range of these
values, which we call </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">keyspace
IDs</span>](http://vitess.io/overview/concepts.html#keyspace-id)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">.</span>

<span
style="color: #434343; font-family: &quot;arial&quot;; font-size: 14.6667px; line-height: 1.38; white-space: pre-wrap;">  
</span>

<span
style="color: #434343; font-family: &quot;arial&quot;; font-size: 14.6667px; line-height: 1.38; white-space: pre-wrap;">**Transparent
Resharding**</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">If
you want to follow along with the new </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">resharding
walkthrough</span>](http://vitess.io/user-guide/sharding-kubernetes.html)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">,
you'll need to first bring up the cluster as described in the
</span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">unsharded
guide</span>](http://vitess.io/getting-started/)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">.
Both guides use the same </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">sample
app</span>](https://github.com/youtube/vitess/tree/master/examples/kubernetes/guestbook)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">,
which is a Guestbook that supports multiple, numbered pages.</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">[![](../images/thumbnails/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B5.png)](../images/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B5.png)</span>

<span
style="font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">In
the </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">sample
app
code</span>](https://github.com/youtube/vitess/blob/master/examples/kubernetes/guestbook/main.py)<span
style="font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">,
you'll see a get\_keyspace\_id() function that transforms a given page
number to the set of all 8-byte sequences, establishing the mapping we
need for consistent hashing. In the unsharded case, these values are
stored but not used. When we introduce sharding, page numbers will be
evenly distributed (on average) across all the shards we create,
allowing the app to scale to support arbitrary amounts of pages.</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">  
</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">Before
resharding, you'll see a single </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">custom
shard</span>](http://vitess.io/user-guide/sharding.html#custom-sharding)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">
named "0" in the Vitess dashboard. This is what an unsharded
</span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">keyspace</span>](http://vitess.io/overview/concepts.html#keyspace)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">
looks like.</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">[![](../images/thumbnails/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B1.png)](../images/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B1.png)</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">As
you begin the </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">resharding
walkthrough</span>](http://vitess.io/user-guide/sharding-kubernetes.html)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">,
you'll bring up two new shards for the same keyspace. During resharding,
the new shards will run alongside the old one, but they'll remain idle
(Vitess will not route any app traffic to them) until you're ready to
migrate. In the dashboard, you'll see all three shards, but only shard
"0" is currently active.</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">[![](../images/thumbnails/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B2.png)](../images/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B2.png)</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">Next,
you'll run a few Vitess commands to </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">copy
the schema and
data</span>](http://vitess.io/user-guide/sharding-kubernetes.html#copy-data-from-original-shard)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">
from the original shard. The key to live migration is that once the
initial snapshot copy is done, Vitess will automatically begin
replicating fresh updates on the original shard to the new shards. We
call this </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">filtered
replication</span>](http://vitess.io/user-guide/sharding.html#filtered-replication)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">,
since it distributes DMLs only to the shards to which they apply. Vitess
also includes tools that compare the original and copied data sets,
row-by-row, to </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">verify
data
integrity</span>](http://vitess.io/user-guide/sharding-kubernetes.html#check-copied-data-integrity)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">.</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">  
</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">Once
you've verified the copy, and filtered replication has caught up to
real-time updates, you can run the </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">migrate
command</span>](http://vitess.io/user-guide/sharding-kubernetes.html#switch-over-to-the-new-shards)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">,
which tells Vitess to atomically shift app traffic from the old shards
to the new ones. It does this by disabling writes on the old masters,
waiting for the new masters to receive the last events over filtered
replication, and then enabling writes on the new masters. Since the
process is automated, this typically only causes about a second of write
unavailability.</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">  
</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">Now
you can </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">tear
down the old
shard</span>](http://vitess.io/user-guide/sharding-kubernetes.html#remove-the-original-shard)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">,
and verify that only the new ones show up in the dashboard.</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">[![](../images/thumbnails/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B4.png)](../images/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B4.png)</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">Note
that we never had to tell the app that we were changing from one shard
to two. The resharding process was completely transparent to the app,
since Vitess automatically reroutes queries on-the-fly as the migration
progresses.</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">  
</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">At
YouTube, we've used Vitess to transparently reshard (both </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">horizontally
and
vertically</span>](http://vitess.io/user-guide/sharding.html#supported-operations)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">)
nearly all of our MySQL databases within the last year alone, and we
have still more on the horizon as we continue to grow. See the full
</span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">walkthrough
instructions</span>](http://vitess.io/user-guide/sharding-kubernetes.html)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">
if you want to try it out for yourself.</span>

<span
style="color: #434343; font-family: &quot;arial&quot;; font-size: 14.6667px; line-height: 1.38; white-space: pre-wrap;">  
</span>

<span
style="color: #434343; font-family: &quot;arial&quot;; font-size: 14.6667px; line-height: 1.38; white-space: pre-wrap;">**Scaling
Benchmarks**</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">The
promise of sharding is that it allows you to scale write throughput
linearly by adding more shards, since each shard is actually a separate
database. The challenge in achieving that separation while still
presenting a simple, unified view to the application is to avoid
introducing bottlenecks. To demonstrate this scaling in the cloud, we've
integrated the Vitess client with a driver for the </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">Yahoo!
Cloud Serving Benchmark</span>](https://github.com/youtube/YCSB)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">
(YCSB).</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">  
</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">Below
you can see preliminary results for scaling write throughput by adding
more shards in Vitess running on </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">Google
Container
Engine</span>](https://cloud.google.com/container-engine/)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">.
For this benchmark, we pointed YCSB at the </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">load
balancer</span>](http://kubernetes.io/v1.0/docs/user-guide/services.html#type-loadbalancer)<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">
for our Vitess cluster and told it to send a lot of INSERT statements.
Vitess took care of routing statements to the various shards.</span>

[![](../images/thumbnails/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B3.png)](../images/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B3.png)

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;"></span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">The
max throughput (QPS) for a given number of shards is the point at which
round-trip write latency became degraded, which we define as &gt;15ms on
average or &gt;50ms for the worst 1% of queries (99th
percentile).</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">  
</span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">We
also ran YCSB's "read mostly" workload (95% reads, 5% writes) to show
how Vitess can scale read traffic by adding replicas. The max throughput
here is the point at which round-trip read latency became degraded,
which we define as &gt;5ms on average or &gt;20ms for the worst 1% of
queries.</span>

[![](../images/thumbnails/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B6.png)](../images/2015-10-06-cloud-native-mysql-sharding-with-vitess-and-kubernetes-vitess%2B6.png)

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;"></span>

<span
style="color: black; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">There's
still a lot of room to improve the benchmarks (for example, by tuning
the performance of MySQL itself). However, these preliminary results
show that the returns don't diminish as you scale. And since you're
scaling horizontally, you're not limited by the size of a single
machine.</span>

<span
style="color: #434343; font-family: &quot;arial&quot;; font-size: 14.6667px; line-height: 1.38; white-space: pre-wrap;">  
</span>

<span
style="color: #434343; font-family: &quot;arial&quot;; font-size: 14.6667px; line-height: 1.38; white-space: pre-wrap;">**Conclusion**</span>

<span
style="color: #444444; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">With
the new cloud native version of Vitess moving towards a stable launch,
we invite you to </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">give
it a try</span>](http://vitess.io/getting-started/)<span
style="color: #444444; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">
and let us know what else you'd like to see in the final release. You
can reach us either on our </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">discussion
forum</span>](https://groups.google.com/forum/#!forum/vitess)<span
style="color: #444444; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">,
or by filing an issue on </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">GitHub</span>](https://github.com/youtube/vitess)<span
style="color: #444444; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">.
If you'd like to be notified of any updates on Vitess, you can subscribe
to our low-frequency </span>[<span
style="color: #1155cc; font-family: &quot;arial&quot;; font-size: 14.6667px; text-decoration: underline; vertical-align: baseline; white-space: pre-wrap;">announcement
list</span>](https://groups.google.com/forum/#!forum/vitess-announce)<span
style="color: #444444; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">.</span>  
<span
style="color: #444444; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">  
</span><span
style="color: #444444; font-family: &quot;arial&quot;; font-size: 14.6667px; vertical-align: baseline; white-space: pre-wrap;">*-
Posted By Anthony Yeh, Software Engineer, YouTube*</span>
