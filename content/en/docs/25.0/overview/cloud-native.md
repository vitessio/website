---
title: Cloud Native
weight: 4
---

Vitess is well-suited for Cloud deployments because it enables databases to incrementally add capacity. The easiest way to run Vitess in the Cloud is via Kubernetes.

## Vitess on Kubernetes

Kubernetes is an open-source orchestration system for containerized applications, and Vitess can run as a Kubernetes-aware cloud native distributed database.

Kubernetes handles scheduling onto nodes in a compute cluster, actively manages workloads on those nodes, and groups containers comprising an application for easy management and discovery. This provides an analogous open-source environment to the way Vitess ran in YouTube on Borg, the predecessor to Kubernetes.

An open-source Kubernetes [operator](https://github.com/planetscale/vitess-operator) is available for Vitess, and is being used in production by several deployments.

**Related Vitess Documentation**

* [Kubernetes Quickstart](../../get-started/operator/)

