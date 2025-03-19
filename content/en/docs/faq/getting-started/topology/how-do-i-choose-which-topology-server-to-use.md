---
title: "How do I choose which topology server to use?"
shorten_nav_links: true
notoc: true
weight: 3
---

The first question to consider is: do you use one already or are you required to use a specific one? If the answer to that question is yes, then you should likely implement that rather than adding a new server to run Vitess.
However, in large implementations, it makes sense to run a separate topology server dedicated to Vitess. This avoids "noisy neighbor" problems.

By default, we recommend that you use etcd if you can, otherwise you may use ZooKeeper.
