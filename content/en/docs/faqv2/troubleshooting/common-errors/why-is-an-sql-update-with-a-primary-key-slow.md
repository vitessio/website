---
title: "Why is an SQL update with a primary key slow?"
shorten_nav_links: true
notoc: true
weight: 1
---

Using tuples in a WHERE clause can cause a MySQL slowdown. Consider:

```sql
UPDATE tbl SET col=1 WHERE (pk1, pk2, pk3) IN (1,2,3), (4,5,6)
```

After a few tuples, MySQL may switch to a full table scan and lock the entire table for the duration. It should perform as expected once `FORCE INDEX (PRIMARY)` is added.  

You can read further information on 'FORCE INDEX' in the MySQL documentation [here](https://dev.mysql.com/doc/refman/8.0/en/index-hints.html).
