---
title: Tablet
---

A *tablet* is a combination of a `mysqld` process and a corresponding `vttablet` process, usually running on the same machine.

Each tablet is assigned a *tablet type*, which specifies what role it currently performs.

## Tablet Types

* **master** - A *replica* tablet that happens to currently be the MySQL master for its shard.
* **replica** - A MySQL slave that is eligible to be promoted to *master*. Conventionally, these are reserved for serving live, user-facing requests (like from the website's frontend).
* **rdonly** - A MySQL slave that cannot be promoted to *master*. Conventionally, these are used for background processing jobs, such as taking backups, dumping data to other systems, heavy analytical queries, MapReduce, and resharding.
* **backup** - A tablet that has stopped replication at a consistent snapshot, so it can upload a new backup for its shard. After it finishes, it will resume replication and return to its previous type.
* **restore** - A tablet that has started up with no data, and is in the process of restoring itself from the latest backup. After it finishes, it will begin replicating at the GTID position of the backup, and become either *replica* or *rdonly*.
* **drained** - A tablet that has been reserved by a Vitess background process (such as rdonly tablets for resharding).

