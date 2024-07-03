---
title: Mount
description: Link an external cluster to the current one
weight: 90
---

### Description

Mount is used to link external Vitess clusters to the current cluster.

Mounting Vitess clusters requires the topology information of the external cluster to be specified. Used in conjunction with [the `Migrate` command](../migrate).

{{< info >}}
No validation is performed when using the [`Mount`](../../programs/vtctldclient/vtctldclient_mount/) command. You must ensure your values are correct, or you may get errors when initializing a migration.
{{< /info >}}

## Command

Please see the [`Mount` command reference](../../programs/vtctldclient/vtctldclient_mount/) for a full list of sub-commands and their flags.
