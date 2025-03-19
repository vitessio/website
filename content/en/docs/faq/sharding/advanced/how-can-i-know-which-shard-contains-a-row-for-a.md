---
title: "How can I know which shard contains a row for a table?"
shorten_nav_links: true
notoc: true
weight: 1
---

You can use the primary Vindex column to query the Vindex and discover the shard ID. Once you have determined the shard ID you can use [manual shard targeting](http://vitess.io/docs/faq/operating-vitess/queries/?#can-i-address-a-specific-shard-if-i-want-to) to send that specific shard a query.  Note that if the query contains the primary Vindex column, or an appropriate secondary Vindex column, you do not need to do this, and vtgate can route the query automatically.
