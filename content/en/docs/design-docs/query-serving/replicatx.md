---
title: Replica Transactions
description:
weight: 1
---

### Feature Description
Vitess currently supports transactions through vtgate only on MASTER tablets. We would like to extend transaction support to REPLICA (or other tablet types).

### Use Case(s)
* Consistent reads
* Sqoop integration

### Proposed Solution
- When vtgate chooses a tablet to execute a query on, it should return the tablet alias.
- tablet alias and transactionID will be stored on the shard session struct.
- if the session object has a tablet alias set, then the query will target the specific tablet.
- if the transaction is committed or rolled back, the session should end.

In order to use this feature, a client will need to issue `use @replica` followed by `BEGIN`.

Prerequisite: #5750
