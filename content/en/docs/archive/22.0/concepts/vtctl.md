---
title: vtctl
---

**vtctl** is the Vitess control system used to administer a Vitess cluster. It consists of a command-line client, [`vtctldclient`](../../reference/command-line-reference/vtctldclient/), that is used as both a standalone tool (`vtctldclient --server=internal`)
and more commonly in client-server mode with [`vtctldclient`](../../reference/command-line-reference/vtctldclient/) interacting with a [`vtctld`](../../reference/command-line-reference/vtctld/) server. Using client-server mode is recommended, as it provides an additional
layer of security when using the client remotely.

Using this you can identify primary and replica databases, create tables, initiate failovers, perform resharding operations, and so forth.

As operations are performed the [Topology Service](../topology-service/) is updated as needed. Other Vitess processes observe those changes and react accordingly. For example, if you use `vtctldclient` to fail over to a new primary database
using [`PlannedReparentShard`](../../reference/command-line-reference/vtctldclient/vtctldclient_plannedreparentshard/), [`vtgate`](../../reference/command-line-reference/vtgate/) sees the changes in the [Topology Service](../topology-service/) and directs future write
operations to the new primary.

Please see the [reference documentation](../../reference/command-line-reference/vtctldclient/) for additional details.
