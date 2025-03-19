---
title: "How can I perform a full table scan without the row limit per query?"
shorten_nav_links: true
notoc: true
weight: 1
---

Vitess supports different modes. In OLTP mode, the result size is typically limited to a preset number (10,000 rows by default). This limit can be adjusted based on your needs.

However, OLAP mode has no limit to the number of rows returned. In order to change to this mode, you may issue the following command before executing your query:

```sql
set workload='olap'
```

You can also set the workload to `dba`, which allows you to override the implicit timeouts that exist in vttablet. However, this mode should be used judiciously as it can block shutdown and reparent commands.

The general convention is to send OLTP queries to `REPLICA` tablet types, and OLAP queries to `RDONLY`.
