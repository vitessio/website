---
title: Metrics
description: Frequently Asked Questions about Vitess
weight: 7
---

## How can I monitor or get metrics from Vitess?

All Vitess components have a web UI that you can access to see the state of each component.

The first place to look is the /debug/status page. 

* This is the main landing page for a VTGate, which displays the status of a particular server. A list of tablets this VTGate process is connected to is also displayed, as this is the list of tablets that can potentially serve queries.

A second place to look is the /debug/vars page.  For example, for VTGate, this page contains the following items:

* VTGateApi - This is the main histogram variable to track for VTGates. It gives you a break down of all queries by command, keyspace, and type.
* HealthcheckConnections - It shows the number of tablet connections for query/healthcheck per keyspace, shard, and tablet type.

There are two other pages you can use to get monitoring information from Vitess in the VTGate web UI:

* /debug/query_plans - This URL gives you all the query plans for queries going through VTGate.
* /debug/vschema - This URL shows the vschema as loaded by VTGate.

VTTablet has a similar web UI.

Vitess component metrics can also be scraped via /metrics. This will provide a Prometheus-format metric dump that is updated continuously. This is the recommended way to collect metrics from Vitess.

## How do you integrate Prometheus and Vitess?

There is an Prometheus exporter that is on by default that enables you to configure a Prometheus compatible scraper to grab data from the various Vitess components. All Vitess components with web UI’s export their metrics on their web UI port on /metrics. 

If your Vitess configuration includes running the Vitess or PlanetScaleDB Operator on Kubernetes, then you can have Prometheus or a Prometheus compatible agent running in your Kubernetes cluster. This would then scrape the metrics from Vitess automatically, as it would be run on the ports advertised and on our standard /metrics page. With the PlanetScaleDB Operator for Kubernetes, this is done for you automatically.

You can read more about getting the metrics into Prometheus [here](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config).