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

## Additional Details

There are some key details to keep in mind if you will be creating and managing your own custom routing rules.
- The `to_tables` field must contain only one entry and the table name must be fully qualified.

- If the `from_table` is qualified by a keyspace, then a query that references that table will get redirected to the corresponding target table. The reference need not be explicit. For example, if you are connected to the `customer` keyspace, then an unqualified reference to the `customer` table is interpreted as a qualified reference to `customer.customer`.

- You may further add a tablet type to the `from_table` field using the `@<type>` syntax seen in the example above. If so, only queries that target that tablet type will get redirected. Although you can qualify a table by its keyspace in a query, there is no equivalent syntax for specifying the tablet type. The only way to choose a tablet type is through the `use` statement, like `use customer@replica`, or by specifying it in the connection string.

- The more specific rules supercede the less specific one. For example, `customer.customer@replica` is chosen over `customer.customer` if the current tablet type is a `replica`.

- If the `to_tables` have special characters that need escaping, you can use the mysql backtick syntax to do so. As for the `from_tables`, the table name should *not* be escaped. Instead, you should just concatenate the table with the keyspace without the backticks. In the following example, we are redirecting the `b.c` table to the `c.b` table in keyspace `a`:
    ``` json
    {
      "rules": [
        {
          "from_table": "a.b.c",
          "to_tables": [
            "a.`c.b`"
          ]
        }
      ]
    }
    ```
