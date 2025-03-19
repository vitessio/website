---
title: "How do I migrate between implementations?"
shorten_nav_links: true
notoc: true
weight: 6
---

We provide the topo2topo utility to migrate between one implementation and another of the topology service. 

This process is explained in Vitess’ documentation [here](https://vitess.io/docs/reference/features/topology-service/#migration-between-implementations).

If your migration is more complex, or has special requirements, we also support a ‘tee’ implementation of the topo service interface. It is defined in go/vt/topo/helpers/tee.go. It allows communicating to two topo services, and the migration uses multiple phases.

This process is explained in Vitess’ documentation [here](https://vitess.io/docs/reference/features/topology-service/#migration-using-the-tee-implementation).
