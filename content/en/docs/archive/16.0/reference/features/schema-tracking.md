---
title: Schema Tracking
weight: 16
aliases: ['/docs/reference/schema-tracking/']
---

VTGate natively tracks table schema using two different methods: schema tracking and VSchema. Using the VSchema, users are allowed to provide an authoritative list of columns which is then used to enhance query planning. If none is provided, VTGate uses its schema tracking feature.

When using schema tracking, VTGate keeps an authoritative list of columns on all tables. The following query set can be planned:

1. `SELECT *` cross-shard queries that need evaluation at the VTGate level.
2. Queries that are not able to resolve columns dependencies. For instance: queries with no table qualifier in the projection/filter list.
3. Evaluation improvement in Aggregations, Group By, Having, Limit, etc. clauses that require processing of records at VTGate level. VTGate will not require `weight_string()` value for the evaluation and can compare the values directly.

If schema tracking happened to be disabled and no authoritative list of columns is provided, a set of queries will not be supported by VTGate due to a lack of information on the underlying tables/columns.

More information on this feature can be found in [this blog post](https://vitess.io/blog/2022-01-11-schema-tracking/).

## VTGate

Schema tracking is enabled in VTGate with the flag `--schema_change_signal`, defaults to `true`. When enabled, VTGate listens for schema changes from VTTablet.
A change triggers a fetch query on VTTablet on the internal `_vt` schema.
If the table ACL is enabled, then an exempted/allowed username needs to be passed to VTGate with flag `--schema_change_signal_user`.

## VTTablet

Schema tracking is enabled in VTTablet with the flag `--queryserver-config-schema-change-signal`, defaults to `true`. When enabled, VTTablet sends schema changes to VTGate based on an interval that can be modified with the flag `--queryserver-config-schema-change-signal-interval` (defaults to 5 seconds).
