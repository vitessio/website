---
title: Monitoring
weight: 8
---

# Current state of monitoring

There are currently three main ways that a Vitess cluster can be monitored. Depending on your needs, you can use any of the following methods:

## 1. Vitess status pages

The status HTML pages of various Vitess components can be accessed by pointing your browser to `http://<host>:<port>/debug/status`. The status pages will often display some basic, but useful, information for monitoring. For example, the status page of a vttablet will show the QPS graph for the past few minutes.

Viewing a status page can be useful since it needs little setup, but it only provides very basic monitoring capabilities.

### Access to status and debug pages

Status and debug pages can show SQL statements from your application, and some debug endpoints change a running process. Before a Vitess component serves one of these pages, it checks whether the caller has the role that the page requires. The `--security-policy` flag names the policy that makes this check. Set it on each component whose pages you use, such as vtgate, vttablet, vtctld, and VTOrc.

Each page requires one of three roles:

* `monitoring`: health endpoints such as `/debug/health`, and the VTOrc read-only `/api/` endpoints.
* `debugging`: status and debug pages such as `/debug/status`, `/debug/config`, `/debug/vschema`, `/debug/querylog`, `/debug/querylogz`, `/debug/queryz`, `/debug/query_plans`, and the vttablet `/querylogz`, `/queryz`, `/livequeryz`, `/schemaz`, `/txlogz`, and `/twopcz` pages.
* `admin`: endpoints that change a running process, such as `/debug/env`, killing a query from `/livequeryz`, and the VTOrc `/api/disable-global-recoveries` and `/api/enable-global-recoveries` endpoints.

Some endpoints, such as `/debug/vars` and `/debug/liveness`, don't check a role.

When `--security-policy` is empty, which is the default, every caller has the `monitoring` role and no other. A page that requires `debugging` or `admin` returns `403 Forbidden`. Vitess also includes these built-in policies:

| `--security-policy` | `monitoring` | `debugging` | `admin` |
|---------------------|--------------|-------------|---------|
| Empty (default)     | Allowed      | Denied      | Denied  |
| `read-only`         | Allowed      | Allowed     | Denied  |
| `allow-all`         | Allowed      | Allowed     | Allowed |
| `deny-all`          | Denied       | Denied      | Denied  |

The built-in policies don't authenticate callers. With `read-only` or `allow-all`, anyone who can reach a component's HTTP port has those roles. In Vitess v24 and earlier, an empty `--security-policy` allowed every role. Use `allow-all` to keep that behavior.

To grant roles to specific callers, write a policy that implements the `Policy` interface in the [`acl` package](https://github.com/vitessio/vitess/tree/main/go/acl). Register it with `acl.RegisterPolicy()`, compile it into your Vitess binaries, and set `--security-policy` to its name.

## 2. Pull-based metrics system

Vitess uses Go’s [expvar package](https://golang.org/pkg/expvar/) to expose various metrics, with the expectation that a user can configure a pull-based metrics system to ingest those metrics. Metrics are published to `http://<host>:<port>/debug/vars` as JSON key-value pairs, which should be easy for any metrics system to parse.

Scraping Vitess variables is a good way to integrate Vitess into an existing monitoring system, and is useful for building up detailed monitoring dashboards. It is also the officially supported way for monitoring Vitess.

## 3. Push-based metrics system

Vitess also includes support for push-based metrics systems via plug-ins. Each Vitess component would need to be run with the `--emit-stats` flag.

By default, the stats-emit-period is 60s, so each component will push stats to the selected backend every minute. This is configurable via the `--stats-emit-period` flag.

Vitess has preliminary plug-ins to support OpenTSDB as a push-based metrics backend.

It should be fairly straightforward to write your own plug-in, if you want to support a different backend. The plug-in package simply needs to implement the `PushBackend` interface of the `stats` package. For an example, you can see the [OpenTSDB plugin](https://github.com/vitessio/vitess/blob/main/go/stats/opentsdb/opentsdb.go).

Once you’ve written the backend plug-in, you also need to register the plug-in from within all the relevant Vitess binaries. An example of how to do this can be seen in [this pull request](https://github.com/vitessio/vitess/pull/469).

You can then specify that Vitess should publish stats to the backend that you're targeting by using the `--stats-backend` flag.

Connecting Vitess to a push-based metrics system can be useful if you’re already running a push-based system that you would like to integrate into.

# Monitoring with Kubernetes

The existing methods for integrating metrics are not supported in a Kubernetes environment by the Vitess team yet, but are on the roadmap for the future. However, it should be possible to get the Prometheus backend working with Kubernetes. 

In the meantime, if you run into issues or have questions, please post on our [Slack](https://vitess.io/slack).
