---
title: Kubernetes
weight: 5
---

## How does Vitess work with Kubernetes?

Vitess can run as a Kubernetes-aware cloud native distributed database. This can be one of the easiest ways to run Vitess.

Kubernetes handles scheduling onto nodes in a compute cluster, actively manages workloads on those nodes, and groups containers comprising an application for easy management and discovery. Vitess does not do this auto-provisioning and thus integrates nicely with Kubernetes.

PlanetScale provides and supports an open-source [Kubernetes operator](https://github.com/planetscale/vitess-operator) for Vitess.

## How can I resize my Kubernetes storage when using Vitess?

If you use Vitess with Kubernetes and need to grow your disk space, Kubernetes has capabilities to resize persistent storage. 
These are specific to your Kubernetes provider, please refer to their documentation.
As an alternative, you can migrate to new storage by performing a series of planned vertical or horizontal sharding operations.

In general, persistent storage in Kubernetes can be resized up, but not down. Host local storage cannot be resized.
Shrinking storage will require spinning up new tablets with the desired (smaller) sized persistent storage, restoring them from backups and decommissioning the old tablets.


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
