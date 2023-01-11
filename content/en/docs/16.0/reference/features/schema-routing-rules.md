---
title: Schema Routing Rules
weight: 15
aliases: ['/docs/schema-management/routing-rules/','/docs/reference/schema-routing-rules/']
---

The Vitess routing rules feature is a powerful mechanism for directing query traffic to the right keyspaces, shards, and tablet types.
Their primary usage today is for the following use case:

* **Routing traffic during data migrations**: during e.g. [`MoveTables`](../../vreplication/movetables/) and
  [`Reshard`](../../vreplication/reshard/) operations, routing rules dictate where to send reads and writes. These routing rules are managed
  automatically by VReplication. You can see an example of their usage in the [MoveTables](../../../user-guides/migration/move-tables/) user guide.

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