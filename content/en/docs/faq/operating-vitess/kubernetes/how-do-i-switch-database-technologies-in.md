---
title: "How do I switch database technologies in Kubernetes?"
shorten_nav_links: true
notoc: true
weight: 3
---

In your tablet definitions of your cluster .yaml file(s), you can specify a different container for the database. You will need to do this for each replica in a shard.  

You will add a `datastore` field and populate it with a `type` and a `container`. 

The only requirement for this is that the container needs to have a standard MySQL deployment. For example, the following block should work to set up Percona for your datastore:

```sh
  - type: "replica"
          datastore:
            type: mysql
            container: "percona/percona-server:5.7"
```
