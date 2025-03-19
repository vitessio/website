---
title: "What can I do if I see a CPU increase after upgrading Vitess?"
shorten_nav_links: true
notoc: true
weight: 2
---

If you are running Vitess 7.0 or above, we introduced the schema tracker, which could be running on the VTTablets now. You can disable it in order to prevent that reporting. 

You will need to add `track_schema_versions` as false in the VTTablet.
