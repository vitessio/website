---
title: "What are the steps to take after an unplanned failover?"
shorten_nav_links: true
notoc: true
weight: 3
---

In order to avoid creating orphaned VTTablets you will need to follow the steps below:

1. Stop the VTTablets
2. Delete the old VTTablet records
3. Create the new keyspace
4. Restart the VTTablets that are pointed at the new keyspace
5. Use TabletExternallyReparented to inform Vitess of the current primary
6. Recursively delete the old keyspace
