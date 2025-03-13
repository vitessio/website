---
title: What are the main components of Vitess?
shorten_nav_links: true
notoc: true
weight: 5
---

Vitess consists of a number of server processes and command-line utilities and is backed by a consistent metadata store. The main server components consist of: 

* VTGate
* Topology server (etcd)
* VTCtld
* Tablets which are made up of VTTablets and mysqld

The diagram below illustrates Vitess’ components and their location within Vitess’ architecture:

<img alt="Vitess Components" src="/img/vitess-components.png"  width=100%>
