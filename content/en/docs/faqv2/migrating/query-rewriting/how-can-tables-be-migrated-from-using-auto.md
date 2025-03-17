---
title: "How can tables be migrated from using auto-increment to sequences?"
shorten_nav_links: true
notoc: true
weight: 1
---

Auto-increment columns do not ensure uniqueness for sharded tables. Instead you will need to use Vitess sequences to achieve the same functionality. 

Sequences are based on a MySQL table and use a single value in that table to describe which values the sequence should have next. Thus, the sequence table is an unsharded single row table that Vitess can use to generate monotonically increasing ids. 

Sequence tables must be specified in the VSchema, and then tied to table columns. Once they are associated, an insert on that table will transparently fetch an id from the sequence table, fill in the value, and route the row to the appropriate shard. At the time of insert, if no value is specified for such a column, VTGate will generate a number for it using the sequence table.

To create a sequence you will need to follow the steps [here](https://vitess.io/docs/reference/features/vitess-sequences/#creating-a-sequence).
