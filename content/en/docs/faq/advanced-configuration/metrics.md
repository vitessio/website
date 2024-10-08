---
title: Metrics
description: Frequently Asked Questions about Vitess
weight: 8
---

## What Grafana dashboards are available?

There are a set of Grafana dashboards and Prometheus alerts available on the Vitess tree in GitHub [here](https://github.com/vitessio/vitess/tree/master/vitess-mixin). You can get some additional context on these dashboards [here](https://github.com/vitessio/vitess/pull/5609).

## How can I implement user-level query logging?

If you would like to differentiate metrics for a 'bad_user@their_machine' from a 'good_user@their_machine', rather than having both users appear to be the same user from the same server to MySQL you will need to use table ACLs.

Vitess exports per-user stats on table ACLs. There are example usages of table ACLs demonstrated in the end-to-end tests.
- The configuration of table ACLs can be found [here](https://github.com/vitessio/vitess/blob/master/go/vt/vttablet/endtoend/main_test.go#L174).
- The tests that demonstrate how table ACLs work can be found [here](https://github.com/vitessio/vitess/blob/master/go/vt/vttablet/endtoend/acl_test.go).

To locate the variables that enable the export of per-users stats you will need to look in `/debug/vars` for variables that start with `User`, like `UserTableQueryCount`. The export itself is a multi-dimensional export categorized by Table, User and Query Type. You can also find similar names exported as prometheus metrics.

Analyzing these variables can enable you to quickly narrow down the root cause of an incident, as these stats are fine-grained. Once you've identified the table and query type, you can then drill into `/queryz` or `/debug/query_stats` to determine if the issue is a particular query.
