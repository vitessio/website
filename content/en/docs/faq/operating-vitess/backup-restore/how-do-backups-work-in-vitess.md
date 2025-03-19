---
title: "How do backups work in vitess?"
shorten_nav_links: true
notoc: true
weight: 1
---

Backup and Restore are integrated features provided by tablets managed by Vitess. Vitess uses backups for provisioning new tablets in an existing shard.

Vitess supports plugins for a number of Backup Storage Services and Backup Engines. The supported plugins are listed in the [documentation](https://vitess.io/docs/user-guides/operating-vitess/backup-and-restore/overview/#backup-storage-services).
