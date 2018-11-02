+++
author = "Anthony Yeh"
published = 2015-03-20T13:53:00-07:00
slug = "2015-03-20-scaling-mysql-in-the-cloud-with-vitess-and-kubernetes"
tags = [ "kubernetes", "cloud",]
title = "Scaling MySQL in the cloud with Vitess and Kubernetes"
+++
<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">*Cross-posted
on [Google Cloud Platform
Blog](http://googlecloudplatform.blogspot.com/2015/03/scaling-MySQL-in-the-cloud-with-Vitess-and-Kubernetes.html).*</span>  
<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">  
</span><span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">Your
new website is growing exponentially. After a few rounds of high fives,
you start scaling to meet this unexpected demand. While you can always
add more front-end servers, eventually your database becomes a
bottleneck, which leads you to . . .</span>  
  

-   Add more replicas for better read throughput and data durability
-   Introduce sharding to scale your write throughput and let your data
    set grow beyond a single machine
-   Create separate replica pools for batch jobs and backups, to isolate
    them from live traffic
-   Clone the whole deployment into multiple datacenters worldwide for
    disaster recovery and lower latency

  
<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">At
YouTube, we went on
that </span>[journey](https://www.youtube.com/watch?v=5yDO-tmIoXY&feature=youtu.be)<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;"> as
we scaled our MySQL deployment, which today handles the metadata for
billions of daily video views and </span>[300 hours of new video uploads
per minute](http://www.youtube.com/yt/press/statistics.html)<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">.
To do this, we developed the </span>[Vitess](http://vitess.io/) <span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">platform,
which addresses scaling challenges while hiding the associated
complexity from the application layer.</span>  
<span id="more"></span>  
  
<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">Vitess
is available as an </span>[open-source
project](https://github.com/youtube/vitess)<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;"> and
runs best in a containerized environment.
With </span>[Kubernetes](http://kubernetes.io/)<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;"> and </span>[Google
Container Engine](https://cloud.google.com/container-engine/)<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;"> as
your </span>[container cluster
manager](http://googlecloudplatform.blogspot.com/2015/01/what-makes-a-container-cluster.html)<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">,
it's now a lot easier to get started. We’ve created a single deployment
configuration for Vitess that works on </span>[any platform that
Kubernetes supports](http://kubernetes.io/gettingstarted/)<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">.</span>  
  
<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">In
addition to being easy to deploy in a container cluster, Vitess also
takes full advantage of the benefits offered by a container cluster
manager, in particular:</span>  
  

-   **Horizontal scaling** – add capacity by launching additional nodes
    rather than making one huge node
-   **Dynamic placement** – let the cluster manager schedule Vitess
    containers wherever it wants
-   **Declarative specification** – describe your desired end state, and
    let the cluster manager create it
-   **Self-healing components** – recover automatically from machine
    failures

  
<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">In
this environment, Vitess provides a MySQL storage layer with improved
durability, scalability, and manageability.</span>  
  
<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">We're
just getting started with this integration, but you can
already </span>[run Vitess on
Kubernetes](http://vitess.io/getting-started/)<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;"> yourself.
For more on Vitess, check out
our </span>[website](http://vitess.io/)<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">,
ask questions on
our </span>[forum](https://groups.google.com/forum/#!forum/vitess)<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">,
or join us on </span>[GitHub](https://github.com/youtube/vitess)<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">.
In particular, take a look at our overview to understand the trade-offs
of Vitess versus NoSQL solutions and fully-managed MySQL solutions
like </span>[Google Cloud SQL](https://cloud.google.com/sql/)<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">.</span>  
<span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">  
</span><span
style="color: #444444; font-family: &quot;arial&quot; , sans-serif; font-size: 13px; line-height: 18.2px;">-Posted
by Anthony Yeh, Software Engineer, YouTube</span>
