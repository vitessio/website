---
author: "Abhi Vaidyanatha"
date: 2019-05-29T09:07:21-08:00
slug: "2019-05-29-unsharded-vitess-benefits"
tags: ['Guides', 'Unsharded', 'Benefits']
title: "The Benefits of Unsharded Vitess"
---

For many large companies seeking help with horizontal scaling, Vitess' value proposition is easily understood; running stateful workloads at astronomical scale is a hard problem that Vitess has boldly solved in the past. However, for businesses that aren't hitting the performance limitations of standard MySQL, it may seem difficult to justify placing seemingly complex middleware in your data path with no immediate reward. I'm here to show you why unsharded Vitess is not just a pre-optimization - it provides many upgrades to the MySQL experience.

### Query Optimization

No matter how advanced our new generation of SQL databases is, we still need to protect them against rogue engineers and unexpected harmful queries. Thankfully, Vitess kills and rewrites dangerous queries to make sure that your database performance isn't due to application or user error. For example, we will add configurable limits to your OLTP queries, reducing the number of full table scans. Additionally, Vitess kills non-deterministic updates that MySQL would normally run silently. If you have special toxic queries that are unique to your data path, you can make your own custom rules that fail them before they touch your database. If that weren't enough, our query optimizer reads your SQL and knows what parts it can reuse to prevent identical requests from hitting your database at the same time.

### Monitoring

Vitess includes a fairly extensive debug suite with variables that are set up to directly export for time-series monitoring. Vitess has [direct support](https://github.com/vitessio/vitess/pull/3784) for Prometheus metrics and can [be configured](https://github.com/vitessio/vitess/blob/master/doc/Monitoring.md) to use most types of pull or push based monitoring tools. In addition to the vast selection of exported variables, Vitess ships with built-in status dashboards that can allow you to oversee database performance without needing to add extra software to your stack. 

### Consistent Topology

Unlike stock SQL offerings, Vitess' topology is always backed by a consesus-based metadata store, so you will always have a consistent view of your database, its replicas, and any read-only analytics replicas that you have created. Along with this comes a built-in control plane that can handle high-level operations such as reparenting, all displayed in a clean web GUI. Finally, Vitess was created to be highly-available; its control plane and topology store work together nicely to deploy your databases across multiple regions.

### Networking Optimization

Most individuals who have tried to run stock MySQL likely understand that its memory usage is farily unpredictable; you are often at the mercy of uncontrolled memory allocations and have to spend large amounts of time configuring connection buffers or overprovisioning memory to avoid performance failures. Instead of opening a new thread for every connection to the database, Vitess maps its lightweight connections to a small set of MySQL connections to shrink configuration time and vastly increase the amount of open connections.

### Kubernetes Migration

Interested in migrating your MySQL databases into Kubernetes? Vitess was built for this. Don't take my word for it, check out [this talk](https://www.youtube.com/watch?v=ZjTraLkMjYM) by notable Vitess user HubSpot on their migration story to Kubernetes.