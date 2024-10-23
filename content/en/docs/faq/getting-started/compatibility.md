---
title: Compatibility
description: Frequently Asked Questions about Vitess
weight: 2
---

## How is Vitess different from AWS Aurora for MySQL?

Vitess can run on-premise or in the cloud. It can be run on bare metal, VMs, Kubernetes, or as managed service provided by PlanetScale. 

AWS Aurora has a heavily modified version of MySQL that is very tightly tied to AWS and is only available as a managed service.

MARKED UNHELPFUL

## What versions of MySQL or MariaDB work with Vitess?

Vitess deploys, scales and manages clusters of open-source SQL database instances. Currently, Vitess supports the MySQL, Percona and MariaDB databases.

* MySQL and Percona
	* Vitess supports the core features of MySQL versions 5.6 to 8.0, with some limitations. 
	* Vitess also supports Percona Server for MySQL versions 5.6 to 8.0.

{{< info >}}
Please do note that with MySQL 5.6 reaching end of life in February 2021, it is recommended to deploy MySQL 5.7 and later.
{{< /info >}}

* MariaDB
	* Vitess supports the core features of MariaDB versions 10.0 to 10.3. 
	* Vitess does not yet support version 10.4 of MariaDB.

## What does Vitess "is MySQL compatible" mean? Will my application "just work"?

Vitess supports much of MySQL, with some limitations. **Depending on your MySQL setup you will need to adjust queries that utilize any of the current unsupported cases.**

For SQL syntax there is a list of example unsupported queries [here](https://github.com/vitessio/vitess/blob/main/go/vt/vtgate/planbuilder/testdata/unsupported_cases.json). 

There are some further compatibility issues beyond pure SQL syntax that are listed out [here](https://vitess.io/docs/reference/mysql-compatibility/).

## How is Vitess different from RDS for MySQL?

Vitess can run on-premise or in the cloud. It can be run on bare metal, VMs, kubernetes, or as managed service provided by PlanetScale. 

RDS is only available as a managed service from AWS.

## How is Vitess different from MySQL?

MySQL can be described as a popular open source database solution. MySQL delivers a fast, multi-threaded, multi-user, and robust SQL (Structured Query Language) database server. 

On the other hand, Vitess is a database clustering system to be used for scaling MySQL. It is a database solution for deploying, scaling and managing large clusters of MySQL instances. 

In other words, Vitess runs on top of MySQL. 