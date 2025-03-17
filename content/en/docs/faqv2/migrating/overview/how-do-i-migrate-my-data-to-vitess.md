---
title: "How do I migrate my data to Vitess?"
shorten_nav_links: true
notoc: true
weight: 1
---

There are two main parts to migrating your data to Vitess: migrating the actual data and repointing the application. The answer here will focus primarily on the methods that can be used to migrate your data into Vitess.

There are three different methods to migrate your data into Vitess. Choosing the appropriate option depends on several factors like:

- The nature of the application accessing the MySQL database
- The size of the MySQL database to be migrated
- The load, especially the write load, on the MySQL database
- Your tolerance for downtime during the migration of data
- Whether you require the ability to reverse the migration if need be
- The network level configuration of your components

The three different methods are:

- ‘Stop-the-world’
- VReplication from Vitess setup in front of the existing external MySQL database
- Application-level migration

Choosing the Right Method

The first and most important point to consider when choosing the right method is whether you can or cannot interconnect between components on your network. If you cannot, or do not wish to, perform extra steps to ensure interconnectivity then you will need to use the ‘Stop-the-world’ method. 

If you can ensure interconnectivity and that the VTTablets are in the same Vitess cluster, then for cases when larger amounts of downtime are not an option you will want to use VReplication with either Movetables or Materialize. 

You can read more about each method [here](https://vitess.io/docs/user-guides/migration/migrate-data/).
