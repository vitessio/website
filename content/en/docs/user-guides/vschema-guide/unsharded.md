---
title: Unsharded Keyspace
weight: 2
---

We are going to start with configuring the `product` table in the unsharded keyspace `product`. The schema file should be as follows:

```sql
create table product(product_id bigint auto_increment, pname varchar(128), primary key(product_id));
```

`product_id` is the primary key for product, and it is also configured to use mysql’s `auto_increment` feature that allows you to automatically generate unique values for it.

We also need to create a VSchema for the `product` keyspace and specify that `product` is a table in the keyspace:

```json
{
  "sharded": false,
  "tables": {
    "product": {}
  }
}
```

The json states that the keyspace is not sharded. The product table is specified in the “tables” section of the json. This is because there are other sections that we will introduce later.

For unsharded keyspaces, no additional metadata is needed for regular tables. So, their entry is empty.

{{< info >}}
If `product` is the only keyspace in the cluster, a vschema is unnecessary. Vitess treats single keyspace clusters as a special case and optimistically forwards all queries to that keyspace even if there is no table metadata present in the vschema. But it is best practice to provide a full vschema to avoid future complications.
{{< /info >}}
