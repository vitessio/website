---
title: "What are my options to restore in vitess?"
shorten_nav_links: true
notoc: true
weight: 3
---

When a tablet starts, Vitess checks the value of the `--restore_from_backup` command-line flag to determine whether to restore a backup to that tablet.

- If the flag is present, Vitess tries to restore the most recent backup from the Backup Storage system when starting the tablet.
- If the flag is absent, Vitess does not try to restore a backup to the tablet. The MYSQL database associated with the tablet will be empty.

For more information on restoring and managing backups please follow the link [here](https://vitess.io/docs/user-guides/operating-vitess/backup-and-restore/bootstrap-and-restore/#restoring-a-backup).
