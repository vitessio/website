---
title: vtctl Query Command Reference
series: vtctl
---

The following `vtctl` commands are available for administering queries.

## Commands

### VtGateExecute
 `VtGateExecute  -server <vtgate> [-bind_variables <JSON map>] [-keyspace <default keyspace>] [-tablet_type <tablet type>] [-options <proto text options>] [-json] <sql>`

### VtTabletExecute
 `VtTabletExecute  [-username <TableACL user>] [-transaction_id <transaction_id>] [-options <proto text options>] [-json] <tablet alias> <sql>`

### VtTabletBegin
 `VtTabletBegin  [-username <TableACL user>] <tablet alias>`

### VtTabletCommit
 `VtTabletCommit  [-username <TableACL user>] <transaction_id>`

### VtTabletRollback
 `VtTabletRollback  [-username <TableACL user>] <tablet alias> <transaction_id>`

### VtTabletStreamHealth
 `VtTabletStreamHealth  [-count <count, default 1>] <tablet alias>`

## See Also

* [vtctl command index](../../vtctl)
