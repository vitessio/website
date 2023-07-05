---
title: Replica Transactions
description:
weight: 1
aliases: ['/docs/design-docs/query-serving/replicatx/'] 
---

### Feature Description

Vitess supports transactions through vtgate on PRIMARY and read REPLICA tablets.

### Use Case(s)

* Consistent reads
* Sqoop integration

### Implemented Solution

- When vtgate chooses a tablet to execute a query on, it will return the tablet alias.
- The tablet alias and transactionID is then stored on the shard session struct.
- If the session object has a tablet alias set, then the query will target the specific tablet.
- If the transaction is committed or rolled back, the session will end.

In order to use this feature, a client will need to issue `use @replica` followed by `BEGIN`.
