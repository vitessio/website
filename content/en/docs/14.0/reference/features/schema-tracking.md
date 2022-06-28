---
title: Schema Tracking
weight: 16
aliases: ['/docs/reference/schema-tracking/']
---

VTGate does not natively track table schema. Users are allowed to provide an authoritative list of columns through a VSchema which is then used to enhance query planning. If no such list is provided, a set of queries will not be supported by VTGate due to a lack of information on the underlying tables/columns.

The schema tracking functionality alleviates this issue and enable VTGate to plan more queries. When using schema tracking, VTGate keeps an authoritative list of columns on all tables. The following query set can be planned:

* `SELECT *` cross-shard queries that need evaluation at the VTGate level.
* Queries that are not able to resolve columns dependencies. For instance: queries with no table qualifier in the projection/filter list.

## VTGate

Schema tracking is enabled in VTGate with the flag `--schema_change_signal`. When enabled, VTGate listens for schema changes from VTTablet.
A change triggers a fetch query on vttablet on internal _vt schema.
If the Table ACL is enabled, then an exempted/allowed username needs to be passed to VTGate with flag `--schema_change_signal_user`.

## VTTablet

Schema tracking is enabled in VTTablet with the flag `--queryserver-config-schema-change-signal`. When enabled, VTTablet sends schema changes to VTGate based on an interval that can be modified with the flag `--queryserver-config-schema-change-signal-interval` (defaults to 5 seconds).
