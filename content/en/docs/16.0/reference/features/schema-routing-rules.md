---
title: Schema Routing Rules
weight: 15
aliases: ['/docs/schema-management/routing-rules/','/docs/reference/schema-routing-rules/']
---

The Vitess routing rules feature is a powerful mechanism for directing query traffic to the right keyspaces, shards, and tablet types in
[Vitess Gateways](../../../concepts/vtgate/) (`vtgate`). Their primary usage today is for the following use case:

* **Routing traffic during data migrations**: during e.g. [`MoveTables`](../../vreplication/movetables/) and
  [`Reshard`](../../vreplication/reshard/) operations, routing rules dictate where to send reads and writes. These routing rules are managed
  automatically by [VReplication](../../vreplication/vreplication/). You can see an example of their usage in the
  [MoveTables](../../../user-guides/migration/move-tables/) user guide.

Understanding the routing rules can help you debug migration related issues as well as provide you with another powerful tool as
you operate Vitess.

## Viewing Routing Rules

The routing rules are global and can be viewed using the [`GetRoutingRules` client command](../../programs/vtctldclient/vtctldclient_getroutingrules/).

## Updating Routing Rules

You can update the routing rules using the [`ApplyRoutingRules` client command](../../programs/vtctldclient/vtctldclient_applyroutingrules/).

## Syntax

Routing rules are managed using the JSON format. Here's an example, using the routing rules that are put in place by `MoveTables`
in the [local examples](../../../get-started/local/) where the `customer` and `corder` tables are being moved from the `commerce`
keyspace to the `customer` keyspace and we have not yet switched traffic from the `commerce` keyspace to the `customer` keyspace — so all
traffic, regardless of which keyspace a client uses, are sent to the `commerce` keyspace:
```json
$ vtctldclient --server=localhost:15999 GetRoutingRules
{
  "rules": [
    {
      "from_table": "customer.customer",
      "to_tables": [
        "commerce.customer"
      ]
    },
    {
      "from_table": "commerce.corder@replica",
      "to_tables": [
        "commerce.corder"
      ]
    },
    {
      "from_table": "customer.customer@rdonly",
      "to_tables": [
        "commerce.customer"
      ]
    },
    {
      "from_table": "commerce.corder@rdonly",
      "to_tables": [
        "commerce.corder"
      ]
    },
    {
      "from_table": "corder@replica",
      "to_tables": [
        "commerce.corder"
      ]
    },
    {
      "from_table": "commerce.customer@replica",
      "to_tables": [
        "commerce.customer"
      ]
    },
    {
      "from_table": "commerce.customer@rdonly",
      "to_tables": [
        "commerce.customer"
      ]
    },
    {
      "from_table": "customer.corder@replica",
      "to_tables": [
        "commerce.corder"
      ]
    },
    {
      "from_table": "customer.corder@rdonly",
      "to_tables": [
        "commerce.corder"
      ]
    },
    {
      "from_table": "customer.customer@replica",
      "to_tables": [
        "commerce.customer"
      ]
    },
    {
      "from_table": "customer.corder",
      "to_tables": [
        "commerce.corder"
      ]
    },
    {
      "from_table": "corder@rdonly",
      "to_tables": [
        "commerce.corder"
      ]
    },
    {
      "from_table": "customer@replica",
      "to_tables": [
        "commerce.customer"
      ]
    },
    {
      "from_table": "customer@rdonly",
      "to_tables": [
        "commerce.customer"
      ]
    },
    {
      "from_table": "corder",
      "to_tables": [
        "commerce.corder"
      ]
    },
    {
      "from_table": "customer",
      "to_tables": [
        "commerce.customer"
      ]
    }
  ]
}
```

## When Routing Rules Are Applied

In the above example, we send all query traffic for the `customer` and `corder` tables to the `commerce` keyspace regardless of how
the client specifies the database/schema and table qualifiers. There is, however, one important exception and that is when the client
explicitly requests the usage of a specific shard, also known as "shard targeting". For example, if the client specifies the database
as `customer:0` or `customer:0@replica` then the query will get run against that shard in the customer keyspace.

{{< warning >}}
You should exercise _extreme_ caution when executing ad-hoc *write* queries during this time as you may think that you're deleting data
from the target keyspace, that is as of yet unused, when in reality you're deleting it from the source keyspace that is currently
serving production traffic.
{{</ warning >}}

{{< info >}}
You can leverage shard targeting to perform ad-hoc *read-only* queries against the target and source keyspace/shards to perform any
additional data validation or checks that you want (beyond [`VDiff`](../../vreplication/vdiff/)). You can also use this shard targeting
to see how your data is distributed across the keyspace's shards.
{{</ info >}}