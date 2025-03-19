---
title: "What Topology servers can I use with Vitess?"
shorten_nav_links: true
notoc: true
weight: 2
---

Vitess uses a plugin implementation to support multiple backend technologies for the Topology Service. The servers currently supported are as follows:
* etcd
* ZooKeeper

The Topology Service interfaces are defined in our code in go/vt/topo/, specific implementations are in go/vt/topo/<name>, and we also have a set of unit tests for it in go/vt/topo/test.

{{< info >}}
If starting from scratch, please use the `etcd` implementation.
{{< /info >}}
