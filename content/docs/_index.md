---
title: The Vitess docs
description: Everything you need to know about the world's most scalable open-source MySQL platform
---

Vitess is a database solution for deploying, scaling and managing large clusters of MySQL instances. It's built to run with equal effectiveness on public cloud architecture, private cloud architecture, and dedicated hardware.

## Vitess and MySQL

Vitess combines and extends the important features of MySQL with the scalability of a NoSQL database. Vitess can help you with a variety of problems, including:

* Scaling a MySQL database, using sharding, while keeping application changes to a minimum
* Migrating your MySQL installation from bare metal to a private or public cloud
* Deploying and managing a large number of MySQL instances

## Vitess database drivers

Vitess includes compliant [JDBC](https://github.com/vitessio/vitess/tree/master/java) and [Go](https://godoc.org/vitess.io/vitess/go) (Golang) database drivers using a native query protocol. Additionally, it implements the [MySQL server protocol](https://dev.mysql.com/doc/internals/en/client-server-protocol.html), which is compatible with virtually any other language.

## Vitess in action

Vitess has been serving all YouTube database traffic since 2011, and has now been adopted by many enterprises for their production needs.
