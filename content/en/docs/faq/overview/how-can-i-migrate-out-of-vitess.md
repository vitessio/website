---
title: "How can I migrate out of Vitess?"
shorten_nav_links: true
notoc: true
weight: 3
aliases:
  - /docs/faq/getting-started/overview/how-can-i-migrate-out-of-vitess/
---

In order to migrate out of Vitess you will need to take a backup of your data using one of the three possible methods: backup and restore, mysqldump, and go-mydumper.

We recommend following the [Backup and Restore](https://vitess.io/docs/user-guides/operating-vitess/backup-and-restore/) guide for regular backups in order to migrate out of Vitess. This method is performed directly on the tablet servers and is more efficient and safer for databases of any significant size. The downside is that this is a physical MySQL instance backup, and needs to be restored accordingly.

Both mysqldump and go-mydumper are not typically suitable for production backups. This is because Vitess does not implement all the locking constructs across a sharded database that are necessary to do a consistent logical backup while writing to the database.  However, it may be appropriate if you are able to stop all writes to Vitess for the period that the dump process is running;  or you are just backing up tables that are not receiving any writes. You can read more about exporting data from Vitess [here](https://vitess.io/docs/user-guides/configuration-basic/exporting-data/).
