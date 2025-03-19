---
title: "What special functions can Vitess handle?"
shorten_nav_links: true
notoc: true
weight: 3
---

We list out the special functions that Vitess handles without delegating to MySQL [here](https://vitess.io/docs/concepts/query-rewriting/#special-functions).

There's a workaround if you want to use a JPA like Hibernate/Eclipselink to talk to Vitess.  

Rather than using `GenerationType.IDENTITY` you can use Eclipselink QuerySequence to define a query directly to Vitess Sequences tables. This not only prevents `SELECT LAST_INSERT_ID()` calls but also can reduce the number of database trips since the application could request a bunch of IDs from Vitess. Potentially around 1000, so this setup will make only one call per 1000 inserts.
