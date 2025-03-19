---
title: "What is the default behavior of connection pooling after a failover on an external (unmanaged) MySQL?"
shorten_nav_links: true
notoc: true
weight: 6
---

The expected behavior is that the connection to the old primary will close and that Vitess will try to reconnect to the new primary.

To ensure that the expected behavior occurs when using AWS/Aurora you will need to set the vttablet flag `-pool_hostname_resolve_interval` to something other than the default. This is because the default is 0. When this flag is set to the default, Vitess will never re-resolve the AWS/Aurora DNS name.
