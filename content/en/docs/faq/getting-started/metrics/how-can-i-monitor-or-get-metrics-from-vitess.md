---
title: "How can I monitor or get metrics from Vitess?"
shorten_nav_links: true
notoc: true
weight: 1
---

All Vitess components have a web UI that you can access to see the state of each component.

The first place to look is the `/debug/status` page.

* This is the main landing page for a VTGate, which displays the status of a particular server. A list of tablets this VTGate process is connected to is also displayed, as this is the list of tablets that can potentially serve queries.

A second place to look is the `/debug/vars` page.  For example, for VTGate, this page contains the following items:

* VTGateApi - This is the main histogram variable to track for VTGates. It gives you a breakdown of all queries by command, keyspace, and type.
* HealthcheckConnections - It shows the number of tablet connections for query/healthcheck per keyspace, shard, and tablet type.

There are two other pages you can use to get monitoring information from Vitess in the VTGate web UI:

* `/debug/query_plans` - This URL gives you all the query plans for queries going through VTGate.
* `/debug/vschema` - This URL shows the VSchema as loaded by VTGate.

VTTablet has a similar web UI.

Vitess component metrics can also be scraped via /metrics. This will provide a Prometheus-format metric dump that is updated continuously. This is the recommended way to collect metrics from Vitess.
