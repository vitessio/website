---
author: 'Niv Amitai'
date: 2021-12-06
slug: '2021-12-06-connecteam-story'
tags: ['Vitess','MySQL', 'usecase', 'casestudy', 'story', 'journey', 'production', 'sharding']
title: 'Connecteam - our Vitess story'
description: "A Vitess journey from PoC to Production"
---
[Connecteam](https://connecteam.com/) is a SaaS company that provides an employee management solution for deskless teams. Over the last couple of years, we’ve been growing tremendously and we recently started to face one of the hardest technical challenges: horizontal scaling.

In the era of cloud computing, provisioning new resources is a breeze, but handling those resources in an efficient manner and providing a five nines uptime while allowing a fast-paced development environment is not an easy undertaking.

Our scaling journey started with migrating all of our stateless workload to Kubernetes, and since Kubernetes and stateless workload are meant for each other, this part went down the pipe almost effortlessly. The next step was to migrate our data warehouses and messaging systems, most of them were NoSQL databases and Kubernetes ready, so this part also went quite well.

Now comes the hardest component to migrate: MySQL! We had our eyes on Vitess for quite a while but we were a bit reluctant to introduce some kind of middleware between our applications and the database, here we were touching the core of our system and our most valuable data, no mistakes were allowed, and having no prior experience using Vitess didn’t help.

There were two facts that couldn’t be negated, we needed an SQL database and we needed sharding, if not with Vitess, we would have to implement sharding at the application level or use another SQL database, two options that made everybody cringe!

So then began our Vitess POC, with the help of the Kubernetes operator, Vitess was up and running in minutes and we could connect to the VTGate and start playing with it. The first command we tried was a naive CREATE DATABASE which made us realize that skimming the doc will not do.

After a few days of reading and trial and errors, we began to copy the data from our running MySQL servers using VReplication and we were very pleased with it. We soon began to gain confidence and build trust on Vitess. We rapidly had a setup where Vitess acted as a replica to our actual MySQL servers and we started redirecting some of the read traffic to it. We had some edge cases that were quickly solved either by minor changes to the code or some tweaks in Vitess configuration. The outcome of the POC was very positive and we decided to move our QA environment to fully use Vitess, which gave us the opportunity to test in depth our applications with Vitess with no risk taking.

After a month or so of testing, we became more and more confident that Vitess is the way to go and we were very excited to have our production systems running on Vitess. Everything was ready, the data had been moved, all that was left to do was a simple configuration change. We hit the switch on the same day PlanetScale went GA, that was a coincidence that put a smile on some faces.
Once in production, we didn’t wait very long to have an issue, we had miscalculated the memory needed by MySQL instance in relation to the InnoDB buffer pool size and after just a few minutes of full production traffic, one of the primary MySQL instance got OOM killed! And it was time for an emergency reparent! We can’t say that we enjoyed it but at the same time we were relieved to see that in times of trouble, Vitess has our back and we can recover pretty fast. We corrected the memory allocation and we spent the whole week glued to monitoring screens to ensure everything is running smoothly, and indeed it was.

We took the decision to first use Vitess with unsharded keyspaces only, even if Vitess is built for sharding, it has many features that are of great value, like connection pooling, caching and query sanitization. We immediately saw an improvement in our overall performances, our average response time went down, and MySQL latency dropped significantly. Today we are 100% confident that we choose the right solution, we are working on a sharding action plan and we are looking forward to explore more of Vitess features.

