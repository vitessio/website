---
title: "Are there recommended thresholds for health statuses?"
shorten_nav_links: true
notoc: true
weight: 3
---

We don’t have recommended thresholds as Vitess doesn’t make any functional decisions based on the statuses, beyond representing the current status in the UI. You do need to be sure to set your alerting to something lower than the threshold you choose.

Another option is if you have the replication heartbeat enabled, you can monitor that statistic.  

Or if you’re exporting the mysqld stats using something like [mysqld-exporter](https://github.com/prometheus/mysqld_exporter) you can monitor the replication lag via those statistics directly. 

If you are using this option you will need to set the alert at something like: "Fire when lag is > X seconds for Y minutes". Otherwise you'll get false alerts, since the `Seconds_Behind_Source` reporting from MySQL often jumps around when either the replication is stopped/started or when traffic is low. 

After either of those occur the `Seconds_Behind_Source` reporting can take some time to settle.
