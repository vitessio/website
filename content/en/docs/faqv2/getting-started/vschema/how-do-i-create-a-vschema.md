---
title: "How do I create a VSchema?"
shorten_nav_links: true
notoc: true
weight: 4
---

The ease of creation of a VSchema depends heavily on now your data model is constructed. 

For some data models, especially smaller and less complex ones, it can be less challenging to determine how to split the data between shards. A clear sharding key would be a column that is on most of the tables in your data model. If there is a clear sharding key then creating VSchema is as straightforward as specifying that column as the primary Vindex for each table. Common primary Vindexes tend to be user ID or customer ID.

For more complex data models most will have to investigate the patterns of common queries in order to determine what sharding keys to use. When investigating the most common queries you must identify what you want to optimize, as this influences heavily the determination of the sharding keys.

For example if you have a query accessing a table with two or more distinct query keys then it may be necessary to create a lookupvindex for the table to accommodate that query pattern.

Please do keep in mind that you don’t have to have Vindex to cover every query pattern;  just the most common. If you adhere to an 80:20 rule, where you scatter 20% of your queries across shards you shouldn’t see any major impacts depending on how you optimized your sharding keys.
