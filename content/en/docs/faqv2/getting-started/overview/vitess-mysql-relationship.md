---
title: What is Vitess and MySQL's relationship?
description: Vitess is not a database itself, instead it is a distributed database system built around MySQL.
shorten_nav_links: true
notoc: true
weight: 2
---

Vitess provides a sharding system for MySQL, as well as some operational management for its instances. Vitess will assist with actions like sharding, managing backup and restore, and adding replicas. 

However, it is important to note that implementers of Vitess will need to provide their own MySQL and perform their own MySQL management.  The amount of MySQL management required depends on if Vitess is configured to run with "managed" MySQL or "external" MySQL.

Vitess can run against various flavors/implementations of MySQL, e.g. MySQL Community Edition, MySQL Enterprise Edition and Percona Server.  Vitess can also be used with many Cloud deployments of MySQL, e.g. AWS RDS, AWS Aurora, GCP Cloud SQL, etc.
