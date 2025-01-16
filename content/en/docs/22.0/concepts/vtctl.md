---
title: vtctl
---

**vtctl** is a command-line tool, `vtctldclient`, that is used as both a standalone tool (`vtctldclient --server=internal`) and client-server (`vtctldclient` in combination with `vtctld`) to administer a Vitess cluster. Using client-server is recommended, as it provides an additional layer of security when using the client remotely.

Using this you can identify primary and replica databases, create tables, initiate failovers, perform resharding operations, and so forth.

As it performs operations, the Topology Service is updated as needed. Other Vitess servers observe those changes and react accordingly. For example, if you use vtctl to fail over to a new primary database, vtgate sees the change and directs future write operations to the new primary.

Please see the [reference documentation](../../reference/programs/vtctldclient/) for additional details.
