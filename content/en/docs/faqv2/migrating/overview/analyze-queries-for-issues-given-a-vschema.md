---
title: "Analyze queries for issues given a Vschema"
shorten_nav_links: true
notoc: true
weight: 3
---

To check your queries for issues you will need to follow these general steps. For a more detailed process that includes examples please refer to the documentation [here](https://vitess.io/docs/user-guides/sql/vtexplain/).

First you will need to gather most, if not all, of the queries that are sent to your current production database tracked over an extended period of time. You may need to track your sent queries for days or weeks depending on your set up. You will also need to normalize the queries you will be analyzing. To do this you can use any MySQL monitoring tool like VividCortex, Monyog or PMM. 

Once you have the full list of normalized queries you will need to filter out any that are not supported or are coming from other sources. Example unsupported queries are listed in the documentation [here](https://vitess.io/docs/reference/compatibility/mysql-compatibility/).

After filtering the list of queries you will need to generate and populate some fake values. To do this we have an example pipeline in the documentation [here](https://vitess.io/docs/user-guides/sql/vtexplain-in-bulk/#3-populate-fake-values-for-your-queries).

Once you have the fake values in place you can then run the [vtexplain](https://vitess.io/docs/faq/migrating/overview/#what-is-vtexplain) command against every query and then inspect the output for errors. You will likely want to use a script to do this. We have an example script as well as some setup steps in the documentation [here](https://vitess.io/docs/reference/programs/vtexplain/#example-usage).

Further case by case examples are available in the documentation starting [here](https://vitess.io/docs/user-guides/sql/vtexplain-in-bulk/).

vtexplain can also be used to try different sharding scenarios before deciding on one.
