---
title: "Are microservices recommended for scaling?"
shorten_nav_links: true
notoc: true
weight: 6
aliases:
  - /docs/faq/getting-started/overview/are-microservices-recommended-for-scaling/
---

It’s better to think of microservices as a design principle rather than as a scaling trick. This architecture is more tailored to improving resilience and flexibility for deployment, by breaking up monolithic deployments into more loosely coupled, isolated elements. The complexity of managing resources for horizontal sharding aligns closely with the challenges of managing resources in a microservices architecture.

Because of this added management complexity, Vitess is a good fit for a container orchestration environment to offset some of this additional complexity. Vitess is commonly deployed/managed in containers using the Vitess Operator for Kubernetes.

In short, horizontally scaling MySQL is made possible by Vitess, both in microservices architectures, as well as more traditional environments.

It is not unusual for a well-configured single-server MySQL installation to serve hundreds of thousands of queries per second, so keep in mind that any scaling challenges you might face could also be resolved by optimizing your code, queries, schema and/or MySQL configuration.

One common challenge faced by users implementing a large-scale microservices architecture, while still keeping a unified database architecture, is that the number of MySQL protocol client connections to the central database can become overwhelming, even with client-side connection pooling.  Vitess handles this by effectively introducing additional layers of connection pooling, ensuring that the backend MySQL instances are not overwhelmed.
