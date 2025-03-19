---
title: "What is VTGate and how does it work?"
shorten_nav_links: true
notoc: true
weight: 1
---

VTGate is a lightweight proxy server that sits between your application and your shards, which contain your data. VTGates are essentially stateless and in many cases, you can scale with query load by adding more VTGate instances.
Some of the main functions performed by VTGate are as follows:
* Keeps track of the Vitess cluster state, and route traffic accordingly.
* Parses SQL queries fully, and combines that understanding with Vitess VSchema to direct queries to the appropriate VTTablet (or set of VTTablets) and returns consolidated results back to the client.
* Supports both the MySQL Protocol and the gRPC protocol. Thus, your applications can connect to VTGate as if it is a MySQL Server.
* Is aware of failovers in underlying shards, and performs buffering of queries to reduce application impact.
