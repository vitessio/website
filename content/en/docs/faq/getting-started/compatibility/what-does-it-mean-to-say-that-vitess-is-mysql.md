---
title: 'What does it mean to say that Vitess "is MySQL compatible"? Will my application "just work"?'
shorten_nav_links: true
notoc: true
weight: 2
---

Vitess supports much of MySQL, with some limitations. **Depending on your MySQL setup you will need to adjust queries that utilize any of the current unsupported cases.**

For SQL syntax there is a list of example [unsupported queries](https://github.com/vitessio/vitess/blob/main/go/vt/vtgate/planbuilder/testdata/unsupported_cases.json). 

There are some further [compatibility issues](https://vitess.io/docs/reference/mysql-compatibility/) beyond pure SQL syntax.
