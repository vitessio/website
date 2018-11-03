---
author: "Anthony Yeh"
published: 2015-03-20T13:53:00-07:00
slug: "2015-03-20-scaling-mysql-in-the-cloud-with-vitess-and-kubernetes"
tags: [ "kubernetes", "cloud",]
title: "Scaling MySQL in the cloud with Vitess and Kubernetes"
---
*Cross-posted
on [Google Cloud Platform
Blog](http://googlecloudplatform.blogspot.com/2015/03/scaling-MySQL-in-the-cloud-with-Vitess-and-Kubernetes.html).*

Your new website is growing exponentially. After a few rounds of high fives, you start scaling to meet this unexpected demand. While you can always add more front-end servers, eventually your database becomes a bottleneck, which leads you to...

* Add more replicas for better read throughput and data durability
* Introduce sharding to scale your write throughput and let your data set grow beyond a single machine
* Create separate replica pools for batch jobs and backups, to isolate them from live traffic
* Clone the whole deployment into multiple datacenters worldwide for disaster recovery and lower latency

At YouTube, we went on that[journey](https://www.youtube.com/watch?v=5yDO-tmIoXY&feature=youtu.be) as
we scaled our MySQL deployment, which today handles the metadata for billions of daily video views and [300 hours of new video uploads per minute](http://www.youtube.com/yt/press/statistics.html). To do this, we developed the [Vitess](http://vitess.io/) platform, which addresses scaling challenges while hiding the associated complexity from the application layer.

Vitess is available as an [open-source project](https://github.com/youtube/vitess) and runs best in a containerized environment. With [Kubernetes](http://kubernetes.io/) and [Google Container Engine](https://cloud.google.com/container-engine/) as your [container cluster manager](http://googlecloudplatform.blogspot.com/2015/01/what-makes-a-container-cluster.html), it's now a lot easier to get started. We’ve created a single deployment configuration for Vitess that works on [any platform that Kubernetes supports](http://kubernetes.io/gettingstarted/).  

In addition to being easy to deploy in a container cluster, Vitess also takes full advantage of the benefits offered by a container cluster manager, in particular:  

* **Horizontal scaling** – add capacity by launching additional nodes
    rather than making one huge node
* **Dynamic placement** – let the cluster manager schedule Vitess
    containers wherever it wants
* **Declarative specification** – describe your desired end state, and
    let the cluster manager create it
* **Self-healing components** – recover automatically from machine
    failures

In this environment, Vitess provides a MySQL storage layer with improved durability, scalability, and manageability.  

We're just getting started with this integration, but you can already [run Vitess on
Kubernetes](http://vitess.io/getting-started/) yourself. For more on Vitess, check out
our [website](http://vitess.io/), ask questions on our [forum](https://groups.google.com/forum/#!forum/vitess), or join us on [GitHub](https://github.com/youtube/vitess). In particular, take a look at our overview to understand the trade-offs of Vitess versus NoSQL solutions and fully-managed MySQL solutions like [Google Cloud SQL](https://cloud.google.com/sql/).

-Posted by Anthony Yeh, Software Engineer, YouTube
