---
title: "Without a Vschema how can table and schema routing work?"
shorten_nav_links: true
notoc: true
weight: 3
---

There are a couple of special cases for when you don’t have a VSchema in place. 

For example, if you add a table called foo to an unsharded keyspace called ks1 the following routing will enable you to access the table:
1. `use ks1; select * from foo;`
2. From the unqualified schema using `select * from ks1.foo;`
3. As long as you have only one keyspace, you can use `select * from foo;` in anonymous mode.

However, if you have more than one keyspace you will not be able to access the table from the unqualified schema using `select * from foo` until you add the table to the VSchema.

For a sharded keyspace you will not be able to access the table until you have a VSchema for it. However, you will be able to see it in `show tables`.
