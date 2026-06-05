---
title: "What is VTTablet? How does it work with MySQL?"
shorten_nav_links: true
notoc: true
weight: 2
---

A VTTablet is the Vitess component that both front-ends and, optionally, controls a running MySQL server. It accepts queries over gRPC and translates the queries back to MySQL, as well as speaking to MySQL to issue commands to control replication, take backups, etc.

Things to note about VTTablet are:
* Each mysqld needs a VTTablet that manages it.
* VTTablet tracks long running queries and kills them when they exceed a defined threshold.
* The combination of a VTTablet process and a MySQL process is called a Tablet.

Please note that in some cases VTTablets may be deployed as [unmanaged/remote or partially managed](https://vitess.io/docs/reference/command-line-reference/vttablet/#managed-mysql).
The recommendation is to start with unmanaged mode but eventually migrate to managed mode. Operations like resharding are possible only with vitess-managed MySQL servers.
