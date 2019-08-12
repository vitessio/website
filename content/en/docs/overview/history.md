---
title: History
description: Born at YouTube, released as Open Source
weight: 5
---

Vitess has been a fundamental component of YouTube infrastructure since 2011. This section briefly summarizes the sequence of events that led to Vitess' creation:

1. YouTube's MySQL database reached a point when peak traffic would soon exceed the database's serving capacity. To temporarily alleviate the problem, YouTube created a master database for write traffic and a replica database for read traffic.
2. With demand for cat videos at an all-time high, read-only traffic was still high enough to overload the replica database. So YouTube added more replicas, again providing a temporary solution.
3. Eventually, write traffic became too high for the master database to handle, requiring YouTube to shard data to handle incoming traffic. (Sharding would have also become necessary if the overall size of the database became too large for a single MySQL instance.)
4. YouTube's application layer was modified so that before executing any database operation, the code could identify the right database shard to receive that particular query.

Vitess let YouTube remove that logic from the source code, introducing a proxy between the application and the database to route and manage database interactions. Since then, YouTube has scaled its user base by a factor of more than 50, greatly increasing its capacity to serve pages, process newly uploaded videos, and more. Even more importantly, Vitess is a platform that continues to scale.

YouTube chose to write Vitess in Go because Go offers a combination of expressiveness and performance. It is almost as expressive as Python and very maintainable. However, its performance is in the same range as Java and close to C++ in certain cases. In addition, the language is extremely well suited for concurrent programming and has a very high quality standard library.

## Open Source First

The open source version of Vitess is extremely similar to the version used at YouTube. While there are some changes that let YouTube take advantage of Google's infrastructure, the core functionality is the same. When developing new features, the Vitess team first makes them work in the Open Source tree. In some cases, the team then writes a plugin that makes use of Google-specific technology. This approach ensures that the Open Source version of Vitess maintains the same level of quality as the internal version.

The vast majority of Vitess development takes place in the open, on GitHub. As such, Vitess is built with extensibility in mind so that you can adjust it to the needs of your infrastructure.
