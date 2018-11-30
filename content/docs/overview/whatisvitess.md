---
title: What Is Vitess
---

Vitess is a database solution for deploying, scaling and managing large clusters of MySQL instances. It's architected to run as effectively in a public or private cloud architecture as it does on dedicated hardware. It combines and extends many important MySQL features with the scalability of a NoSQL database. Vitess can help you with the following problems:

1. Scaling a MySQL database by allowing you to shard it, while keeping application changes to a minimum.
2. Migrating from baremetal to a private or public cloud.
3. Deploying and managing a large number of MySQL instances.

Vitess includes compliant JDBC and Go database drivers using a native query protocol. Additionally, it implements the MySQL server protocol which is compatible with virtually any other language.

Vitess has been serving all YouTube database traffic since 2011, and has now been adopted by many enterprises for their production needs.

## Features

* Performance
    - Connection pooling - Multiplex front-end application queries onto a pool of MySQL connections to optimize performance.
    - Query de-duping – Reuse results of an in-flight query for any identical requests received while the in-flight query was still executing.
    - Transaction manager – Limit number of concurrent transactions and manage deadlines to optimize overall throughput.

* Protection
    - Query rewriting and sanitization – Add limits and avoid non-deterministic updates.
    - Query blacklisting – Customize rules to prevent potentially problematic queries from hitting your database.
    - Query killer – Terminate queries that take too long to return data.
    - Table ACLs – Specify access control lists (ACLs) for tables based on the connected user.

* Monitoring
    - Performance analysis: Tools let you monitor, diagnose, and analyze your database performance.
    - Query streaming – Use a list of incoming queries to serve OLAP workloads.
    - Update stream – A server streams the list of rows changing in the database, which can be used as a mechanism to propagate changes to other data stores.

* Topology Management Tools
    - Master management tools (handles reparenting)
    - Web-based management GUI
    - Designed to work in multiple data centers / regions

* Sharding
    - Virtually seamless dynamic re-sharding
    - Vertical and Horizontal sharding support
    - Multiple sharding schemes, with the ability to plug-in custom ones
