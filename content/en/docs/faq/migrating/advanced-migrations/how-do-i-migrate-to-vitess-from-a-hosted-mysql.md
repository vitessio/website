---
title: "How do I migrate to Vitess from a hosted MySQL?"
shorten_nav_links: true
notoc: true
weight: 1
---

If you are running a hosted MySQL like RDS on AWS, CloudSQL on GCP, or Azure managed MySQL, because you are not coming from MySQL you have to use either the ‘Stop-the-world’ method or the method using VReplication setup in front of the existing external database.  You can read more about those two methods [here](https://vitess.io/docs/user-guides/migration/migrate-data/).

There is no option to do an application level migration. 

The biggest challenge with this sort of migration is you must be able to access the source database from the location where you want to put the target database. You will need to ensure this configuration constraint is resolved and set up prior to any sort of migration.
