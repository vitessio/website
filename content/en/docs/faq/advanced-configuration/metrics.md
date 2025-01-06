---
title: Metrics
weight: 8
---

## What Grafana dashboards are available?

There are a set of [Grafana dashboards and Prometheus alerts](https://github.com/vitessio/vitess/tree/main/vitess-mixin) available on the Vitess tree in GitHub. For more context on these dashboards please refer to the [original pull request](https://github.com/vitessio/vitess/pull/5609).

## How can I implement user-level query logging?

If you would like to differentiate metrics for a 'bad_user@their_machine' from a 'good_user@their_machine', rather than having both users appear to be the same user from the same server to MySQL you will need to use table ACLs.

Vitess exports per-user stats on table ACLs. There are example usages of table ACLs demonstrated in the end-to-end tests.
- How to [configure table ACLs](https://github.com/vitessio/vitess/blob/master/go/vt/vttablet/endtoend/main_test.go#L174)
- [Tests](https://github.com/vitessio/vitess/blob/master/go/vt/vttablet/endtoend/acl_test.go) that demonstrate how table ACLs work

To locate the variables that enable the export of per-user stats you will need to look in `/debug/vars` for variables that start with `User`, like `UserTableQueryCount`. The export itself is a multi-dimensional export categorized by Table, User and Query Type. You can also find similar names exported as prometheus metrics.

Analyzing these variables can enable you to quickly narrow down the root cause of an incident, as these stats are fine-grained. Once you've identified the table and query type, you can then drill into `/queryz` or `/debug/query_stats` to determine if the issue is a particular query.
