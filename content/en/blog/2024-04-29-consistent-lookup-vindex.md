---
author: 'Harshit Gangal, Deepthi Sigireddi'
date: 2024-04-29
slug: '2024-04-29-consistent-lookup-vindex'
tags: ['Vitess', 'PlanetScale', 'MySQL', 'Query Serving', 'Vindex']
title: 'Consistent Lookup Vindex: Achieving Data Consistency without 2PC'
description: "How we implemented a consistent lookup Vindex in Vitess to ensure data consistency without using 2PC"
---

## Vindex
Vitess uses Vindexes (short for Vitess Index) to associate rows in a table with a designated address known as `Keyspace ID`. This allows Vitess to direct a row to its intended destination, typically a shard within the cluster.

Vindexes play a dual role: enabling data sharding through Primary Vindexes and facilitating global indexing via Secondary Vindexes. Through this mechanism, Vindexes serve as an indispensable tool for routing queries in a sharded database, ensuring optimal performance and scalability.

## Lookup Vindex
Lookup Vindex as a Secondary Vindex is used to direct Select/Update/Delete queries to the appropriate shard without incurring the performance penalty associated with scatter-gather operations—wherein the query is sent to all shards for processing.

When data is inserted into a table a separate global index table maintains the mapping of a secondary index column to the corresponding `Keyspace ID`. This mapping information is later used to efficiently route queries to the destination shard.

Secondary Vindexes can be unique or non-unique, and we’ll illustrate both types. Let us look at an example to see how this works.

#### Data Table definition:
**USER Table**
```shell
+-------+--------------+------+-----+
| Field | Type         | Null | Key |
+-------+--------------+------+-----+
| id    | bigint       | NO   | PRI |
| name  | varchar(255) | YES  |     |
| phone | bigint       | YES  | UNI |
| email | varchar(255) | YES  |     |
+-------+--------------+------+-----+
```


#### Non Unique Vindex Table Defination:
**NAME_USER_VDX Table**
```shell
+-------------+--------------+------+-----+
| Field       | Type         | Null | Key |
+-------------+--------------+------+-----+
| name        | varchar(255) | NO   | PRI |
| id          | bigint       | NO   | PRI |
| keyspace_id | binary(8)    | YES  |     |
+-------------+--------------+------+-----+
```


#### Unique Vindex Table Defination:
**PHONE_USER_VDX Table**
```shell
+-------------+-----------+------+-----+
| Field       | Type      | Null | Key |
+-------------+-----------+------+-----+
| phone       | bigint    | NO   | PRI |
| keyspace_id | binary(8) | YES  |     |
+-------------+-----------+------+-----+
```


When executing a query like `select id, phone, email from user where name = 'Alex'`, the query planner uses the lookup vindex table `name_user_vdx`, to map the value `Alex` to its corresponding `Keyspace ID`. This lets the planner direct the query to a single destination shard rather than to all shards, thus avoiding a costly `scatter-gather` operation.

Of particular interest is the `Consistent Lookup Vindex`, a type of Secondary Vindex, which further enhances the efficiency and reliability of this routing mechanism.

## Consistent Lookup Vindex
The `user` data table and lookup vindex tables are both sharded in most cases to enable optimal performance and storage. The sharding column for the `user` table and the Vindex tables are likely to be different. In the scenario above, let's consider the sharding columns to be:

| Table          | Primary Vindex Column |
|----------------|-----------------------|
| User           | id                    |
| Name_User_Vdx  | name                  |
| Phone_User_Vdx | phone                 |

Changing data in the `user` table through DML statements (Insert/Update/Delete) leads to changes to rows in the Vindex tables as well. To maintain consistency between the `user` data table and the vindex tables, all these operations will need to occur in a transaction that spans multiple shards. This means we need to implement a costly protocol like 2PC (Two Phase Commit) to guarantee Atomicity and Isolation (A and I from ACID). Not using a proper multi-shard transaction for these operations can lead to partial commit and inconsistent data.

Consistent Lookup Vindex uses an alternate approach that makes use of careful locking and transaction sequences to guarantee consistency without using 2PC for all DML operations. This allows Vitess to provide a consistent view of the `user` data table even when record in the vindex tables may be inconsistent.

When data is being modified, Vitess uses 3 connections to perform DML operations. Let’s call them Pre, Main and Post. Any transaction open on these connections will follow a well-defined sequence of operations. Committing a transaction will result in the following:
- Commit on Pre
- Commit on Main
- Commit on Post

A failure in any of these steps rolls back the remaining open transactions in the same order.

Let’s look at an example to see how this works.
#### Sample Rows:
```shell
USER:
+-----+------+------------+-----------------+
| id  | name | phone      | email           |
+-----+------+------------+-----------------+
| 100 | Alex | 8877991122 | alex@mail.com   |
| 200 | Emma | 8811229988 | emma@mail.com   |
+-----+------+------------+-----------------+

NAME_USER_VDX:
+------+-----+--------------------------+
| name | id  | keyspace_id              |
+------+-----+--------------------------+
| Alex | 100 | 0x313030                 |
| Emma | 200 | 0x323030                 |
+------+-----+--------------------------+

PHONE_USER_VDX:
+------------+--------------------------+
| phone      | keyspace_id              |
+------------+--------------------------+
| 8811229988 | 0x323030                 |
| 8877991122 | 0x313030                 |
+------------+--------------------------+
```

### Delete Operation:
Deletion of Lookup Vindex table data happens through the **Post** connection.

**Example:** `delete from user where id = 100`

1. First select all the lookup columns from the `User` Table <br>
   **Main:** `select id, name, phone from user where id = 100 for update`
2. Delete the Lookup Vindex Rows <br>
   **Post-Transaction:**
   1.  `delete from name_user_vdx where name = 'Alex' and id = 100`
   2.  `delete from phone_user_vdx where phone = 8877991122`
3. Delete the User Table Row <br>
   **Main:** `delete from user where id = 100`

On Commit, suppose the Main transaction succeeds but the Post transaction fails. Let’s see how we are still able to maintain consistency.

#### Updated Rows:
```shell
USER:
+-----+------+------------+-----------------+
| id  | name | phone      | email           |
+-----+------+------------+-----------------+
| 200 | Emma | 8811229988 | emma@mail.com   |
+-----+------+------------+-----------------+

NAME_USER_VDX:
+------+-----+--------------------------+
| name | id  | keyspace_id              |
+------+-----+--------------------------+
| Alex | 100 | 0x313030                 |
| Emma | 200 | 0x323030                 |
+------+-----+--------------------------+

PHONE_USER_VDX:
+------------+--------------------------+
| phone      | keyspace_id              |
+------------+--------------------------+
| 8811229988 | 0x323030                 |
| 8877991122 | 0x313030                 |
+------------+--------------------------+
```

If a select query is received
`select count(*) from user where name = 'Alex'`

A lookup call will happen with `name = 'Alex'` to the `name_user_vdx` vindex which will return the shard destination with keyspace_id of `0x313030`. When the query is sent down to the specific shard a matching row does not exist in the `User` table any longer and hence will return no results.

```shell
+----------+
| count(*) |
+----------+
|        0 |
+----------+
```

The lookup vindex table may be inconsistent with the `User` table but the results returned for the query remained consistent with the `User` table.

### Insert Operation:
Insertion of Lookup Vindex table data happens through the **Pre** connection.

**Example:** `insert into user(id, name, phone, email) values (300, 'Emma', 8877991122, 'xyz@mail.com')`

1. Insert into Lookup Vindex table <br>
   **Pre-Transaction:**
   1. `insert into name_user_vdx(name, id, keyspace_id) values ('Emma', 300, '0x333030')` <br>
      No error as `name` is a non-unique column.
   2. `insert into phone_user_vdx(phone, keyspace_id) values (8877991122, '0x333030')` <br>
      This results in a duplicate key error as it is a unique column. Note that this row is left over from the error we got during the previous delete operation. We’ll get into the details of how this is handled in a minute.
2. Insert the User table Row <br>
   **Main:** `insert into user(id, name, phone, email) values (300, 'Emma', 8877991122, 'xyz@mail.com')`

**Handling of Duplicate Key Error in Lookup Vindex:**
1. Lock the lookup row so that no other transaction can race with the current operation. <br>
   **Pre-Transaction:** `select phone, keyspace_id from phone_user_vdx where phone = 8877991122 for update`
2. Lock the main table row to ensure that the row we want to insert does not exist yet and no other transaction can race with the current operation.
   1. **Main:** `select phone from user where phone = 8877991122 for update` <br>
   Because we previously deleted the corresponding row for this select, it will return no results. This tells us that the lookup vindex table has an orphan row which can be updated with the new value from the insert statement.
   2. **Pre-Transaction:** `update phone_user_vdx set keyspace_id = ‘0x333030’ where phone = 8877991122`

#### Updated Rows:
```shell
USER:
+-----+------+------------+-----------------+
| id  | name | phone      | email           |
+-----+------+------------+-----------------+
| 200 | Emma | 8811229988 | emma@mail.com   |
| 300 | Emma | 8877991122 | xyz@mail.com    |
+-----+------+------------+-----------------+

NAME_USER_VDX:
+------+-----+--------------------------+
| name | id  | keyspace_id              |
+------+-----+--------------------------+
| Alex | 100 | 0x313030                 |
| Emma | 200 | 0x323030                 |
| Emma | 300 | 0x333030                 |
+------+-----+--------------------------+

PHONE_USER_VDX:
+------------+--------------------------+
| phone      | keyspace_id              |
+------------+--------------------------+
| 8811229988 | 0x323030                 |
| 8877991122 | 0x333030                 |
+------------+--------------------------+
```

### Update Operation:
Update of Lookup Vindex table data happens through a Delete operation followed by an Insert operation. We already know that Delete operation is handled through **Post** connection and Insert operation through **Pre** connection.

In the special case of an update where the vindex column value is unchanged, it will cause `lock wait timeout` on the Insert operation (on the **Pre** connection) as the row lock will be held by the Delete operation (on the **Post** connection). To mitigate this, updating vindex column data with the same value as before is turned into a no-op for lookup vindex tables.

However, it is still possible to run into this limitation if the same lookup vindex value is deleted and inserted as two different statements inside the same transaction.


Want to learn more about this feature in Vitess? We have docs on [Vindexes](https://vitess.io/docs/19.0/reference/features/vindexes/), [Unique](https://vitess.io/docs/19.0/user-guides/vschema-guide/unique-lookup/) and [Non-Unique](https://vitess.io/docs/19.0/user-guides/vschema-guide/non-unique-lookup/) lookup vindexes. You are also welcome to join our [community](https://vitess.io/slack).
