---
title: Monitoring
weight: 16
aliases: ['/docs/launching/server-configuration/', '/docs/user-guides/server-configuration/', '/docs/user-guides/configuring-components/']
---

This section describes how to monitor Vitess components. Additionally, we recommend that you also add the necessary monitoring and alerting for the TopoServers as well as the MySQL instances running with each vttablet.

## Tools

Vitess provides integrations with a variety of popular monitoring tools: Prometheus, InfluxDB and Datadog. The core infrastructure uses go's `expvar` package to export real-time variables visible as a JSON object served by the `/debug/vars` URL. The exported variables are CamelCase names. These names are algorithmically converted to the appropriate naming standards for each monitoring tool. For example, Prometheus uses a [snake case conversion algorithm](https://github.com/vitessio/vitess/blob/e259a08f017d9f1b5984fcaac5c54e26d1c7c31d/go/stats/prometheusbackend/prometheusbackend.go#L95-L116). In this case, the Prometheus exporter would convert the `Queries.Histograms.Select.500000` variable to `vttablet_queries_bucket{plan_type="Select",le="0.0005"}`.

In the sections below, we will be describing the variables as seen in the `/debug/vars` page.

The two critical Vitess processes to monitor are vttablet and vtgate. Additionally, we recommend that you setup monitoring for the underlying MySQL instances as commonly recommended in the MySQL community.

Beyond what the tools export, it is important to also monitor system resource usage: CPU, memory, network and disk usage.

There is a [popular mixin](https://github.com/vitessio/vitess/tree/main/vitess-mixin) contributed by [Slack](https://slack.com) that is based on how they monitor Vitess internally. It can be used as a starting point if you intend to use Prometheus and Grafana.

Beyond the monitoring variables, the Vitess processes export additional information about their status on other URL paths. Some of those pages are for human consumption, and others are machine-readable meant for building automation.

## VTTablet

### /debug/status

This page has a variety of human-readable information about the current vttablet and contains links to all the other URLs. You can look at this page to get a general overview of what is going on.

### /debug/vars

The following sections describe the various sub-objects of the JSON object exported by `/debug/vars`. These variables can be found at the top level of the JSON object:

#### Queries

Vitess has a structured way of exporting certain performance stats. The most common one is the Histogram structure, which is used by Queries:

``` json
  "Queries": {
    "Histograms": {
      "Select": {
        "1000000": 1138196,
        "10000000": 1138313,
        "100000000": 1138342,
        "1000000000": 1138342,
        "10000000000": 1138342,
        "500000": 1133195,
        "5000000": 1138277,
        "50000000": 1138342,
        "500000000": 1138342,
        "5000000000": 1138342,
        "Count": 1138342,
        "Time": 387710449887,
        "inf": 1138342
      }
    },
    "TotalCount": 1138342,
    "TotalTime": 387710449887
  },
```

The histograms are broken out into query categories. In the above case, `Select` is the only category, which measures all SELECT statements. An entry like `"500000": 1133195` means that `1133195` queries took under `500000` nanoseconds to execute.

Here is the full list of categories [expanded from the source](https://github.com/vitessio/vitess/blob/e259a08f017d9f1b5984fcaac5c54e26d1c7c31d/go/vt/vttablet/tabletserver/planbuilder/plan.go#L79-L102):

```
Select
SelectLock
Nextval
SelectImpossible
Insert
InsertMessage
Update
UpdateLimit
Delete
DeleteLimit
DDL
Set
OtherRead
OtherAdmin
SelectStream
MessageStream
Savepoint
Release
RollbackSavepoint
ShowTables
Load
Flush
LockTables
UnlockTables
```

The numbers are cumulative. For example, if you wish to count how many queries took between `500000ns` and `1000000ns`, the answer would be `1138196-1133195`, which is `1`.

Later below, we will be covering variables that break out these queries into further sub-categories like per-table, etc. However, we do not generate histograms for them because the number of values generated would be too big.

The thresholds are hard-coded. However, if you are integrating with an extermal tool like Prometheus, it will have its own thresholds.

The counters increment for the lifetime of the vttablet, and all values are updated in real-time.

`Queries.Histograms.Select.Count` is the total count in the `Select` category.

`Queries.Histograms.Select.Time` is the total time in the `Select` category.

`Queries.TotalCount` is the total count across all categories.

`Queries.TotalTime` is the total time across all categories.

There are other Histogram variables described below, and they will always have the same structure.

Use this variable to track:

* QPS
* Latency
* Per-category QPS. For replicas, the only category will be `Select`, but there will be more for primary tablets.
* Per-category latency
* Per-category tail latency
* Per-category cost: This value is calculated as QPS\*Latency. If the latency of a high QPS query goes up, it is likely causing more harm than the latency increase of an occasional query.

#### Results

```json
  "Results": {
    "0": 0,
    "1": 0,
    "10": 1138326,
    "100": 1138326,
    "1000": 1138342,
    "10000": 1138342,
    "5": 1138326,
    "50": 1138326,
    "500": 1138342,
    "5000": 1138342,
    "Count": 1138342,
    "Total": 1140438,
    "inf": 1138342
  }
```  

Results is a simple histogram with no timing info. It gives you a histogram view of the number of rows returned per query. This does not include rows affected from write queries.

`Count` is expected to be the same as the `TotalCount` of the `Queries` histogram.

`Total` is the total number of rows returned so far.

#### Mysql

Mysql is a histogram variable like Queries, except that it reports MySQL execution times. The categories are "Exec" and “ExecStream”.

The vttablet queries exec time is roughly equal to the sum of the MySQL exec time, `ConnPoolWaitTime` and `Waits.Consolidations`.

#### Transactions

`Transactions` is a histogram variable that tracks transactions. The categories are "Completed" and “Aborted”. Since these are histograms, they include count as well as timings.

#### Waits

Waits is a histogram variable that tracks various waits in the system. Right now, the only category is "Consolidations". A consolidation happens when one query waits for the results of an identical query already executing, thereby saving the database from performing duplicate work.

This variable used to report connection pool waits, but a refactor moved those variables out into the pool related vars.

#### Errors

``` json
  "Errors": {
    "Deadlock": 0,
    "Fail": 1,
    "NotInTx": 0,
    "TxPoolFull": 0
  },
```

Errors are reported under different categories. It’s beneficial to track each category separately as it will be more helpful for troubleshooting. Right now, there are four categories. The category list may vary as Vitess evolves.

Errors/Query is a useful stat to track.

VTTablet also exports an InfoErrors variable that tracks inconsequential errors that don’t signify any kind of problem with the system. For example, a dup key on insert is considered normal because apps tend to use that error to instead update an existing row. So, no monitoring is needed for that variable.

#### InternalErrors

``` json
  "InternalErrors": {
    "HungQuery": 0,
    "Invalidation": 0,
    "MemcacheStats": 0,
    "Mismatch": 0,
    "Panic": 0,
    "Schema": 0,
    "StrayTransactions": 0,
    "Task": 0
  },
```

An internal error is an unexpected situation in code that may possibly point to a bug. Such errors may not cause outages, but even a single error needs to be escalated for root cause analysis.

#### Kills

``` json
  "Kills": {
    "Queries": 2,
    "Transactions": 0,
    "ReservedConnection": 0
  },
```

Kills reports the queries, transactions and reserved connections killed by vttablet due to timeout. It is a very important variable to look at during incidents.

#### TransactionPool\* and FoundRowsPool\*

There are a few variables with the above prefixes that report the status of the two transaction pools:

``` json
  "TransactionPoolAvailable": 300,
  "TransactionPoolCapacity": 300,
  "TransactionPoolIdleTimeout": 600000000000,
  "TransactionPoolMaxCap": 300,
  "TransactionPoolTimeout": 30000000000,
  "TransactionPoolWaitCount": 0,
  "TransactionPoolWaitTime": 0,
  "FoundRowsPoolAvailable": 300,
  "FoundRowsPoolCapacity": 300,
  "FoundRowsPoolIdleTimeout": 600000000000,
  "FoundRowsPoolMaxCap": 300,
  "FoundRowsPoolTimeout": 30000000000,
  "FoundRowsPoolWaitCount": 0,
  "FoundRowsPoolWaitTime": 0,
```

The choice of which pool gets used depends on whether the application connected with the `CLIENT_FOUND_ROWS` flag or not.

* `WaitCount` will give you how often the transaction pool gets full, which causes new transactions to wait.
* `WaitTime`/`WaitCount` will tell you the average wait time.
* `Available` is a gauge that tells you the number of available connections in the pool in real-time. `Capacity-Available` is the number of connections in use. Note that this number could be misleading if the traffic is spiky.

#### Other Pool variables

Just like `TransactionPool`, there are variables for other pools:

* `ConnPool`: This is the pool used for read traffic.
* `StreamConnPool`: This is the pool used for streaming queries.

There are other internal pools used by vttablet that are not very consequential.

#### `TableACLAllowed`, `TableACLDenied`, `TableACLPseudoDenied`

The above three variables are table acl stats. They are broken out by table, plan and user.

#### `QueryPlanCacheSize`

If the application does not make good use of bind variables, this value would reach the QueryCacheCapacity. If so, inspecting the current query cache will give you a clue about where the misuse is happening.

#### `QueryCounts`, `QueryErrorCounts`, `QueryRowCounts`, `QueryTimesNs`

These variables are another multi-dimensional view of Queries. They have a lot more data than Queries because they’re broken out into tables as well as plan. This is a priceless source of information when it comes to troubleshooting. If an outage is related to rogue queries, the graphs plotted from these vars will immediately show the table on which such queries are run. After that, a quick look at the detailed query stats will most likely identify the culprit.

#### `UserTableQueryCount`, `UserTableQueryTimesNs`, `UserTransactionCount`, `UserTransactionTimesNs`

These variables are yet another view of Queries, but broken out by user, table and plan. If you have well-compartmentalized app users, this is another priceless way of identifying a rogue "user app" that could be misbehaving.

#### /debug/health

This URL prints out a simple "ok" or “not ok” string that can be used to check if the server is healthy. The health check makes sure mysqld connections work, and replication is configured (though not necessarily running) if not on primary.

#### /debug/status\_details

This URL prints out a JSON object that lists the state of all the variables that contribute to the current healthy or unhealthy state of a vttablet. If healthy, you should see something like this:

```json
[
  {
    "Key": "Current State",
    "Class": "healthy",
    "Value": "PRIMARY: Serving, Jan 13, 2021 at 20:52:13 (PST)"
  }
]
```

#### /queryz, /debug/query\_stats, /debug/tablet\_plans, /livequeryz

* /queryz is a human-readable version of /debug/query\_stats. If a graph shows a table as a possible source of problems, this is the next place to look to see if a specific query is the root cause. This is list is sorted in descending order of query latency. If the value is greater than 100 milliseconds, it's color-coded red. If it is greater than 10 milliseconds, it is color coded yellow. Otherwise, it is color coded gray.
* /debug/query\_stats is a JSON view of the per-query stats. This information is pulled in real-time from the query cache. The per-table stats in /debug/vars are a roll-up of this information.
* /debug/table\_plans is a more static view of the query cache. It just shows how vttablet will process or rewrite the input query.
* /livequeryz lists the currently running queries. You have the option to kill any of them from this page.

#### /querylogz, /debug/querylog, /txlogz, /debug/txlog

* /debug/querylog is a continuous stream of verbose execution info as each query is executed. This URL can generate a lot of data because it streams every query processed by vttablet. The details are as per this function: https://github.com/vitessio/vitess/blob/main/go/vt/vttablet/tabletserver/tabletenv/logstats.go#L202
* /querylogz is a limited human readable version of /debug/querylog. It prints the next 300 queries by default. The limit can be specified with a limit=N parameter on the URL.
* /txlogz is like /querylogz, but for transactions.
* /debug/txlog is the JSON counterpart to /txlogz.

#### /debug/consolidations

This URL has an MRU list of consolidations. This is a way of identifying if multiple clients are spamming the same query to a server.

#### /schemaz, /debug/schema

* /schemaz shows the schema info loaded by vttablet.
* /debug/schema is the JSON version of /schemaz.

#### /debug/query\_rules

This URL displays the currently active query block rules.

### Alerting

Alerting is built on top of the variables you monitor. Before setting up alerts, you should get some baseline stats and variance, and then you can build meaningful alerting rules. You can use the following list as a guideline to build your own:

* Query latency among all vttablets
* Per keyspace latency
* Errors/query
* Memory usage
* Unhealthy for too long
* Too many vttablets down
* Health has been flapping
* Transaction pool full error rate
* Any internal error
* Traffic out of balance among replicas
* Qps/core too high
* High replication lag
* Errant transactions
* Primary is in read-only mode

## VTGate

### /debug/status

This is the landing page for a vtgate, which gives you the status of how a particular server is doing. Of particular interest there is the list of tablets this vtgate process is connected to, as this is the list of tablets that can potentially serve queries.

### /debug/vars

#### VTGateApi

This is the main histogram variable to track for vtgates. It gives you a break up of all queries by command, keyspace, and type.

#### HealthcheckConnections

It shows the number of tablet connections for query/healthcheck per keyspace, shard, and tablet type.

### TopologyWatcherErrors and TopologyWatcherOperations

These two variables track events related to how vtgate watches the topology. It is particularly important to monitor the error count. This can act as an early warning sign if a vtgate is not able to refresh the list of tablets from the topo.

### /debug/health

This URL prints out a simple "ok" or “not ok” string that can be used to check if the server is healthy.

### /debug/querylogz, /debug/querylog, /debug/queryz, /debug/query\_plans

These URLs are similar to the ones exported by vttablet, but apply to the current vtgate instance.

### /debug/vschema

This URL shows the vschema as loaded by vtgate.

### Alerting

For vtgate, here’s a list of possible variables to alert on:

* Error rate
* Error/query rate
* Error/query/tablet-type rate
* vtgate serving graph is stale by x minutes (topology service is down)
* Qps/core
* Latency

