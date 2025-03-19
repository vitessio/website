---
title: "Am I really limited to 250 GB as my tablet size? Why?"
shorten_nav_links: true
notoc: true
weight: 1
---

Vitess recommends provisioning shard sizes to approximately 250GB. This is not a hard-limit, and is driven primarily by the recovery time should an instance fail. With 250GB a full-recovery from backup is expected within less than 15 minutes. 

For most workloads this results in shards instances with relatively few CPU cores and lighter memory requirements, which tend to be more economical than running large instance sizes.

For more information there is an in depth blog article [here](https://vitess.io/blog/2019-09-03-why-250gb-shards/).
