---
title: "How does Vitess work with Kubernetes?"
shorten_nav_links: true
notoc: true
weight: 1
---

Vitess can run as a Kubernetes-aware cloud native distributed database. This can be one of the easiest ways to run Vitess.

Kubernetes handles scheduling onto nodes in a compute cluster, actively manages workloads on those nodes, and groups containers comprising an application for easy management and discovery. Vitess does not do this auto-provisioning and thus integrates nicely with Kubernetes.

PlanetScale provides and supports an open-source [Kubernetes operator](https://github.com/planetscale/vitess-operator) for Vitess.
