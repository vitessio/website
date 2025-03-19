---
title: "Can I set a session variable query timeout?"
shorten_nav_links: true
notoc: true
weight: 4
---

If you would like something similar to `[max_execution_time]`(https://dev.mysql.com/blog-archive/server-side-select-statement-timeouts/) you can set the vttablet command line flag as follows: `-queryserver-config-query-timeout=15`. This is set in seconds.

You can also specify a query comment like `select /*vt+ QUERY_TIMEOUT_MS=1000 */ `... 

If you choose to set the vttablet command line flag the time you choose will set the absolute max time. The query comment can only override the timeout to a lower value. 

This timeout via SQL query comments has the following limitations/caveats:

- You need to prevent your SQL client from stripping the comments before sending to the server (the MySQL CLI strips comments by default)
- You need to disable query normalization in vtgate (`--normalize_queries false`);  to allow the comment to reach vttablet.
- It only works for SELECT statements today, this might change in the future.

{{< info >}}
Note that streaming queries are not affected by either of these timeouts.
{{< /info >}}
