---
title: "What is a tablet? What are the types?"
shorten_nav_links: true
notoc: true
weight: 7
---

A tablet is a combination of a mysqld process and a corresponding VTTablet process, usually running on the same machine. Each tablet is assigned a tablet type, which specifies what role it currently performs. The main tablet types are listed below:

* PRIMARY - A tablet that contains a MySQL instance that is currently the MySQL primary for its shard.
* REPLICA - A tablet that contains a MySQL replica that is eligible to be promoted to primary. Conventionally, these are reserved for serving live, user-facing read-only requests (like from the website’s frontend).
* RDONLY - A tablet that contains a MySQL replica that cannot be promoted to primary. Conventionally, these are used for background processing jobs, such as taking backups, dumping data to other systems, heavy analytical queries, and resharding.

There are some other tablet types like `BACKUP` and `RESTORE`. For information on how to use tablets please review this [user guide](https://vitess.io/docs/user-guides/configuration-basic/vttablet-mysql/).
