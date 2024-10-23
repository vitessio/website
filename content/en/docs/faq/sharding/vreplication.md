---
title: VReplication
description: Frequently Asked Questions about Vitess
weight: 2
---

## How can Movetables be used with duplicate table names?

If you have duplicate table names and want to use MoveTables you will need to take some action to prevent duplicate table routing issues. If you use move tables prior to following the steps below you will get an error similar to: `ERROR 1105 (HY000): vtgate: http://localhost:15001/: ambiguous table reference`.

To avoid this error you need to:
 
- Use vtctlclient GetRoutingRules and export that to a file. 
- Then edit that file to add specific routing to the source schema for the tables you are using.
- Then use `vtctlclient ApplyRoutingRules -rules="$(cat /tmp/whatever)" ` to apply those rules. 

After applying those rules, queries to the tables will be explicitly routed to the source/original schema and you can use MoveTables.