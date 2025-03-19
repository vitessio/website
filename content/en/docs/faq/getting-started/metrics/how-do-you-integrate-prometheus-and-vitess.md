---
title: "How do you integrate Prometheus and Vitess?"
shorten_nav_links: true
notoc: true
weight: 2
---

There is an Prometheus exporter that is on by default that enables you to configure a Prometheus compatible scraper to grab data from the various Vitess components. All Vitess components export their metrics on their http port at `/metrics`. 

If your Vitess configuration includes running the Vitess Operator on Kubernetes, then you can have Prometheus or a Prometheus compatible agent running in your Kubernetes cluster. This would then scrape the metrics from Vitess automatically, as it would be run on the ports advertised and on our standard `/metrics` page. 

You can read more about getting the metrics into Prometheus [here](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config).
