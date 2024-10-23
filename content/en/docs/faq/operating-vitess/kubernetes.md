---
title: Kubernetes
description: Frequently Asked Questions about Vitess
weight: 5
---

## How can I resize my Kubernetes storage when using Vitess?

If you use Vitess with Kubernetes and need to grow your disk space, Kubernetes has certain capabilities to resize persistent storage. 

However most techniques involve deleting and/or restarting the associated pods. This would mean stopping vttablets, which we recommend avoiding if possible.  

As an alternative, you can migrate to new storage by performing a series of planned vertical shard migrations and shard reparents to new pods.  

In future the PlanetScale Kubernetes operator may enable more dynamic persistent volume resizing, taking advantage of emerging Kubernetes flexibility in this area.

## How does Vitess work with Kubernetes?

Vitess can run as a Kubernetes-aware cloud native distributed database. This can be one of the easiest ways to run Vitess.

Kubernetes handles scheduling onto nodes in a compute cluster, actively manages workloads on those nodes, and groups containers comprising an application for easy management and discovery. Vitess does not do this auto-provisioning and thus integrates nicely with Kubernetes.

## How do I switch database technologies in Kubernetes?

In your tablet definitions of your cluster .yaml file(s), you can specify a different container for the database. You will need to do this for each replica in a shard.  

You will add a `datastore` field and populate it with a `type` and a `container`. 

The only requirement for this is that the container needs to have a standard MySQL deployment. For example, the following block should work to set up Percona for your datastore:

```sh
  - type: "replica"
          datastore:
            type: mysql
            container: "percona/percona-server:5.7"
```