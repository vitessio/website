---
title: Schema Mirror Rules
weight: 15
---

Mirror rules are a feature for testing how queries will perform when executed against a different keyspace. It is intended to reduce the uncertainty involved when migrating application queries from one keyspace to another via `MoveTables`.

## Viewing Mirror Rules

The mirror rules are global and can be viewed using the [`GetMirrorRules` client command](../../programs/vtctldclient/vtctldclient_getmirrorrules/).

## Updating Mirror Rules

Mirror rules are managed by the [`MoveTables MirrorTraffic` client command](../../programs/vtctldclient/vtctldclient_movetables_mirrortraffic/).

## Syntax

Mirror rules are managed using the JSON format. Here's an example, showing the mirror rules that would be produced using `MoveTables MirrorTraffic` against the [local examples](../../../get-started/local/), where the queries to `customer` and `corder` tables are mirrored from the the `commerce` keyspace to the `customer` keyspace:

```bash
$ vtctldclient --server=localhost:15999 GetMirrorRules
{
  "rules": [
    {
      "from_table": "commerce.corder",
      "to_table": "customer.corder",
      "percent": 1.0
    },
    {
      "from_table": "commerce.corder@replica",
      "to_table": "customer.corder",
      "percent": 1.0
    },
    {
      "from_table": "commerce.corder@rdonly",
      "to_table": "customer.corder",
      "percent": 1.0
    },
    {
      "from_table": "commerce.customer",
      "to_table": "customer.customer",
      "percent": 1.0
    },
    {
      "from_table": "commerce.customer@replica",
      "to_table": "customer.customer",
      "percent": 1.0
    },
    {
      "from_table": "commerce.customer@rdonly",
      "to_table": "customer.customer",
      "percent": 1.0
    }
  ]
}
```

## When Mirror Rules Are Applied

Mirror rules are evaluated after routing rules. So, if there are routing rules in place redirecting traffic from `commerce` tables to `customer` tables, then the mirror rules in the example above would not be applied.

## Evaluating the Impact of Mirror Rules

At the VTGate-level, the impact of mirrored queries can be seen in the query log (`MirrorSourceExecuteTime`, `MirrorTargetExecuteTime`, and `MirrorTargetError`), and in metrics reporting the performance of mirrored queries. Check [VTTablet-level metrics](../../configuration-basic/monitoring/) to observe the performance of mirrored queries.
