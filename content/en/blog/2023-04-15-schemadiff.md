---
author: 'Shlomi Noach'
date: 2023-04-15
slug: '2023-04-15-schemadiff'
tags: ['Vitess','MySQL', 'DDL', 'schema']
title: 'schemadiff: in-memory schema diffing, normalization, validation and manipulation'
description: 'Introducing schemadiff, a best kept secret library available in Vitess'
---

`schemadiff` is an internal Vitess library that supports some full blown schema management capabilities, in-memory and without the use of MySQL. It can be used for multiple purposes, from diffing two tables or two schemas, down to programmatically applying in-memory schema changes. In this post we introduce some core components and use cases of this library.

One of the interesting developments found in Vitess releases starting with `v14`, is `schemadiff`, a best kept secret internal library. At its core, `schemadiff` is a declarative, programmatic library that can produce an SQL diff of entities: two tables, two views, or two full blown database schemas. But it then goes beyond that to normalize, validate, export, and even _apply_ schema changes, all declaratively and without having to use a MySQL server. Let's dive in to understand its functionality and capabilities.

## Some tech specs

`schemadiff` supports MySQL `8.0` dialect and functionality. It is completely in-memory and does not use any MySQL server or MySQL code. It applies MySQL-compatible logic and rulers to validate and apply schema changes. It uses a declarative approach but also works with imperative commands.

## Diff preamble

`schemadiff`, as its name suggests, began as a diffing library. The objectives were:

1. Given two table definitions, what schema changes (DDLs) would we need to apply on the 1st, so it looks like the 2nd?
2. Given two schemas (aka databases), that include tables and views, what schema changes (DDLs) would we need to apply on the 1st, so it looks like the 2nd?

As a use case for (1), consider [declarative Vitess migrations](https://vitess.io/docs/16.0/user-guides/schema-changes/declarative-migrations/). Consider that you might want to tell your database: "Here's a table, please make it look like so". It's the database's job to determine whether this table exists in the first place or not. If not, then it must be created. If it exists, and already looks exactly like you want it to, geat, that's a no-op. But what if the current table looks somewhat different? What changes need to be applied on the existing table so as to make it look like your desired table? Specifically, what `ALTER TABLE` statement(s) (there are some rare scenarios where we might need to invoke more than one) do we need to invoke?

The case (2) is best explained with [PlanetScale branching](https://planetscale.com/docs/concepts/branching). You have a production schema, and you have a local copy of that schema. On your local copy, you make changes over time, and finally wish to apply those changes in production. Did you track those changes? Some ORMs will do a good job at that. But you might not have used an ORM, or the ORM might not be feature complete. What tables do you need to `CREATE`? Which views should be `DROP`ped? And what needs to be `ALTER`ed? Is there a specific order of operations?

There are two approaches to analyzing the diff of tables or schemas. One approach is to use a running MySQL server. Deploy the two schemas on that server, then investigate the `INFORMATION_SCHEMA` metadata tables and construct a model for the schema. In `INFORMATION_SCHEMA` we may find a formal breakdown such as the columns found in each table, what data type a column has, what default does it have, if any; which indexes are unique, which columns do they cover; what foreign key constraints on a table point to which parent table, what columns are covered; etc.

This approach has two advantages:

1. If you're able to create a table in MySQL, that means it's valid. By the time you introspect `INFORMATION_SCHEMA` on that table, you may safely assume that, for example, keys only cover existing columns.
2. `INFORMATION_SCHEMA` formalizes the majority of information. The data type is well defined. A column precision is an integer value. The text collation is a well known value.

However, there are disadvantages, as well:

0. Complex expressions are left, well, complex. A `CREATE VIEW ...` statement is really just a long SQL text. Which tables or views are referenced in our `VIEW` definition? Which columns?
0. Not everything is normalized and formalized. We know `int(10)` and `int(11)` are really the same. But as MySQL goes, the column type is different. Contract this with `varchar(10)` and `varchar(11)`, where the type is truly different. It still takes some higher level logic to understand what is a real diff and what isn't.
0. MySQL allows schema inconsistencies. It is possible, in MySQL, to have an "orphaned" `VIEW`, where the tables/views on which it relies, do not exist. Reading something from MySQL doesn't fully mean it's valid.
0. Last, and most impactful of all, is the operational overhead. To diff two schemas, you need to deploy two schemas, then read back the metadata for all the tables, views, indexes, constraints, etc. You need to deploy a MySQL server, likely in a non-production environment. You will need to start the server, deploy the changes, read back, shutdown the server. This is a heavyweight operation.
  Even more, if you want to validate your _diff_, you probably want to deploy it on the running server, then re-read the result, compare it with what you were expecting to find. This is more so heavyweight.
	And, if you wanted to resolve the _order_ by which the changes must take place (some scenarios dictate a specific order, a topic for a future post), then you'd need to solicit confirmation from MySQL by applying changes on the server, regressively.

The second is the in-memory, programmatic approach. Instead of relying on `INFORMATION_SCHEMA`, we rely on the SQL of the schema, i.e. on the `CREATE TABLE` and `CREATE VIEW` statements themselves. This poses a few challenges of its own:

0. First and foremost, you must be able to parse and analyze all statements. This includes a `CREATE TABLE` that has a `CHECK CONSTRAINT` with a complex expression, or a sub-partitioning scheme using functions over columns. Or the ability to fully parse a `CREATE VIEW` statement. Or a complex `GENERATED` column expression, etc.
0. You must be able to accommodate different equivalent definitions. For example, `create table t (id int primary key)` is equivalent to `create table t(id int, primary key(id))`. Even MySQL's own `SHOW CREATE TABLE` output may present different results depending on when/where the table was created.
0. Not having a MySQL server to validate correctness of the initial schema and the generated diffs means the application must implement that logic.

`schemadiff` uses the programmatic approach. Let's see some sample code and continue to discuss its internals.



## Quick diff examples

By way of simple illustration, we create and diff two schemas, each with a single table. First schema:

```go
schema1, err := NewSchemaFromSQL("create table t (id int, name varchar(64), primary key(id))")
if err == nil {
	fmt.Println(schema1.ToSQL())
}
```

```sql
CREATE TABLE `t` (
	`id` int,
	`name` varchar(64),
	PRIMARY KEY (`id`)
);
```

In the second schema, our table is slightly modified:

```go
schema2, err := NewSchemaFromSQL("create table t (id bigint, name varchar(64), key name_idx(name(16)), primary key(id))")
if err == nil {
	fmt.Println(schema2.ToSQL())
}
```

```sql
CREATE TABLE `t` (
	`id` bigint,
	`name` varchar(64),
	KEY `name_idx` (`name`(16)),
	PRIMARY KEY (`id`)
);
```

We now programmatically diff the two schemas (this is actually the long path to doing so):

```go
hints := &DiffHints{}
diffs, err := schema1.Diff(schema2, hints)
if err == nil {
	for _, diff := range diffs {
		fmt.Println(diff.CanonicalStatementString())
	}
}
```

And this is the resulting diff:

```sql
ALTER TABLE `t` MODIFY COLUMN `id` bigint, ADD KEY `name_idx` (`name`(16))
```

There's different ways to generating the diffs. Here's a quick shortcut to achieving the same:

```go
diffs, err := DiffSchemasSQL("create ...", "create ...", hints)
...
```

The first thing to note in the above examples is that everything takes place purely within `go` space, and there is no MySQL server nor library involved. `schemadiff` is purely programmatic, and makes heavy use of Vitess' [`sqlparser`](https://github.com/vitessio/vitess/tree/main/go/vt/sqlparser) library.


## sqlparser

Vitess is a sharding and infrastructure framework running on top of MySQL, and masquerades as a MySQL server to route queries into relevant shards. It thus obviously must be able to parse MySQL's SQL dialect. [`sqlparser`](https://github.com/vitessio/vitess/tree/main/go/vt/sqlparser) is the Vitess library that does so.

`sqlparser` utilizes a [classic yacc file](https://github.com/vitessio/vitess/blob/main/go/vt/sqlparser/sql.y) to parse SQL into an Abstract Syntax Tree (AST), with `golang` structs generated and populated by the parser. For example, a SQL `CREATE TABLE` statement is parsed into a [`CreateTable`](https://github.com/vitessio/vitess/blob/157857a4c5ee6dcb44e7de08894db8334750746e/go/vt/sqlparser/ast.go#L509-L517) instance:

```go
CreateTable struct {
	Temp        bool
	Table       TableName
	IfNotExists bool
	TableSpec   *TableSpec
	OptLike     *OptLike
	Comments    *ParsedComments
	FullyParsed bool
}
```

And here is the breakdown of [`TableSpec`](https://github.com/vitessio/vitess/blob/157857a4c5ee6dcb44e7de08894db8334750746e/go/vt/sqlparser/ast.go#L1763-L1769):

```go
type TableSpec struct {
	Columns         []*ColumnDefinition
	Indexes         []*IndexDefinition
	Constraints     []*ConstraintDefinition
	Options         TableOptions
	PartitionOption *PartitionOption
}
```

You can already see how AST helps us in analyzing a table's definition. As a very simple illustration, imagine we have two tables we want to diff. Say we want to find whether the two have a different set (let's ignore ordering for now) of columns. How would we do that?

We can programmatically iterate over `range table1.TableSpec.Columns` in each of the tables. We can do a full drill down of all the details in a `ColumnDefinition`. Or, we can take a shortcut. `schemadiff` uses an optimistic approach: most of the schema is likely to be identical. It first attempts to compare components as a whole. If they components are identical as a whole, we can proceed to drill down.

How do you "compare a component as a whole"? `sqlparser` not only parses SQL, it also exports AST as SQL. We can, for example, run:

```go
  s1 := sqlparser.CanonicalString(table1.TableSpec.Columns[i])
  s2 := sqlparser.CanonicalString(table2.TableSpec.Columns[i])
```

We can thus compare any two _nodes_. If they export into identical strings, then they are equal and there is no need to drill down. `sqlparser`'s AST also comes with an auto-generated set of deep-equals comparison and deep-copy functionality.

Continuing our simple illustration, if `table2` has a column called `info`, which we cannot find in `table1`, then our table diff, our `ALTER TABLE` statement, should include an `ADD COLUMN <column definition>` statement. What's the content of the column definition? It is trivially the `CanonicalString()` of the extra column object.

`sqlparser` is devoid of semantic context. It merely deals with a programmatic reflection of SQL. It does not know if a certain table exists, nor does it care about type conversions in a `SELECT` query. As long as the syntax is valid, it is satisfied.

## Semantics

The AST's sole purpose is to faithfully represent a SQL query/command. But as a by-product, it can also serve as the base to a semantic analysis of the schema. Consider the following table definition:

```sql
CREATE TABLE `invalid` (
	`id` bigint,
	`title` varchar(64),
	`title` tinytext,
	PRIMARY KEY (`val`)
);
```

The above table is _syntactically_ valid, but _semantically_ invalid. There are two columns that go by the same name (`title`), and an index that covers a non-existent column (`val`). These are but two out of many possible errors. Obviously, such a statement cannot come from a `SHOW CREATE TABLE` output of a running MySQL server. But, we don't really expect a MySQL server here. We are just faced with some input, and if we don't validate it first, results could be unexpected.

## Validation

The basic validation premise is that everyone should want their schema to be valid. There's no point in using invalid schemas, because, at the end of they day, you want to be able to deploy those schemas on real MySQL servers.

To that effect, `schemadiff` enforce validation upon loading a new schema. As we see later on, it also enforces validation upon applying changes. If you try to load an invalid schema as in the above, `schemadiff` returns an informative error. You can't have two columns of same name. Your keys may only cover existing columns. The collation name must be recognized. A `GENERATED` column must refer to existing columns. A `FOREIGN KEY` constraint must reference existing columns in existing tables, respective to the local columns count and data types, etc. Circular `FOREIGN KEY` dependencies are not allowed.

Even more interesting is view validation. `schemadiff` offers a complete validation over view definitions: all referenced tables/views must exist. Circular dependency is not allowed. Referenced columns are validated to exist. Unqualified column names are ensured not to be ambiguous.

## Diff hints

There are nuances. What do you do about different `AUTO_INCREMENT` values? These are not strictly part of the schema, but may or may not cause impact to production if you apply or not apply them. How do you deal with renamed columns? What about constraint names, which, per ANSI SQL, must be unique across the schema? Do you mind if key definitions are in different order?

[`DiffHints`](https://github.com/vitessio/vitess/blob/157857a4c5ee6dcb44e7de08894db8334750746e/go/vt/schemadiff/types.go#L110-L121) includes many controls that affect the diffing logic and output.

## Normalization

Consider this table definition:

```sql
create table what_can_be_normalized (
	id int primary key,
	i int(11) default null,
	v varchar(32) collate utf8mb4_0900_ai_ci
) default charset=utf8mb4 collate=utf8mb4_0900_ai_ci
```

There's a few things to normalize here. Inputs can come in different shapes and sizes, and still mean the same thing. Even MySQL itself presents different output for textual columns based on which version the table was created in. In the above table definition, we can normalize the following:

- The canonical way to declare a `primary key` is as an index definition, not as part of the column definition.
- `int(11)` is just an `int`. `11` does not matter (it is in fact slated to be deprecated in MySQL).
- It looks like `i` is `NULL`able (because it does not say `not null`). Which means its default value is `null` even if we don't explicitly say that.
- `v`'s collation, and thereby character set, agree with the table's collation. It can be removed.

A normalized version of the above looks like:

```sql
create table what_can_be_normalized (
	id int,
	i int,
	v varchar(32),
	primary key(id)
) default charset=utf8mb4 collate=utf8mb4_0900_ai_ci
```

We simplify for clarity, but the normalized `schemadiff` form is really a full blown qualified statement of the form:

```sql
CREATE TABLE `what_can_be_normalized` (
	`id` int,
	...
)
```

Normalization both ensures we converge onto a single, canonical, representation of a table/view, as well as presents an "economical" form.

## Beyond diff

Up till now, we saw that we can load a schema into `schemadiff`. `schemadiff` would normalize the schema, validate it, and throw an error if it's invalid. We can load a 2nd schema, and if all goes well we can diff the two, and grab the _diffs_.

What then? Do we trust those diffs? Will they result in the correct schema? Will they result in a valid schema?

It looks like to validate those diffs we'd need to run a MySQL server, deploy the 1st schema, apply those diffs (`CREATE`, `ALTER`, `DROP` statements), then re-read the schema and compare it with the one we aimed for. But, this brings back the dependency on a MySQL server, something we wanted to avoid in the first place.

Unless, we can ask `schemadiff` to programmatically _apply_ those diffs and validate the result!

## Applying diffs

Consider this simplified code, or see snippet from [`diff_test.go`](https://github.com/vitessio/vitess/blob/27cd9c34bb747d504dfd6c3aa8dff08d7b11832f/go/vt/schemadiff/diff_test.go#L777-L793):

```go
schema1, err := NewSchemaFromSQL(sql1)
// handle error

schema2, err := NewSchemaFromSQL(sql2)
// handle error

diffs, err := schema1.Diff(schema2, hints)
// handle error

applied, err := schema1.Apply(diffs)
require.NoError(t, err)

appliedDiff, err := schema2.Diff(applied, hints)
require.NoError(t, err)
assert.Empty(t, appliedDiff)
assert.Equal(t, schema2.ToQueries(), applied.ToQueries())
```

`schemadiff` lets us take those _diffs_ and `Apply()` them onto a schema (`schema1`), resulting with a new schema. We expect that result to be equal in content to the expected (`schema2`) schema. We also expect `schemadiff` itself to agree the two are identical.

`Apply()` makes an in-memory schema change. You may `CREATE TABLE` or `ALTER TABLE` or `DROP VIEW`, all programmatically, and all using AST structures such as `CreateTable`, `AlterTable`, or `DropView`, etc.

`Apply()` validates the requested changes on the fly, as well as on the resulting schema. It adheres to MySQL rules. For example:

- If the diff has a `AddColumn` AST struct, verify upfront that no column exists by same name.
- If there's an `AddKey`, validate that the columns specified by the key, do in fact exist.
- If there's an `AddKey` and no index name specified, generate one, compatible with MySQL naming.
- Conversely, if there's a `DropColumn`, and some keys exist that actually cover that column, remove the column from those keys; any key that is left without any covered columns is dropped (this is the standard MySQL behavior).
- You shouldn't be able to `DropColumn` if there's a `FOREIGN KEY` referencing that column, though.
- The list goes on.

As we can see, there's a lot of validations involved. Some of them actually depend on each other! Say I'm dropping a column as well as a `FOREIGN KEY` that references that column. MySQL-wise this is a single `ALTER TABLE` operation. But, programmatically, `schemadiff` needs to first remove the `FOREIGN KEY`, and then remove the column. The reverse order is invalid. `schemadiff` resolves the correct order of operations inside a table.

But then, it also resolves the correct order of operations in the grand context of the schema. Consider this diff:

```sql
create view v1 as select * from v2;
create view v2 as select * from t;
```

Alphabetically, `v1` comes before `v2`. But, to apply these two diffs, we must first create `v2`, then `v1`. The reverse order is invalid. This time it's invalid not only programmatically in `schemadiff`, but also when applied to MySQL itself.

`schemadiff` maintains the hierarchical ordering of all tables and views, based on `FOREIGN KEY` and view definitions. There's a specific order for `CREATE` statements, and a specific (reverse) order for `DROP` statements. There may actually be conflicts between the diffs, but that's the topic of a different blog post.

Or, consider the flow in [this `e2e` test](https://github.com/vitessio/vitess/blob/27cd9c34bb747d504dfd6c3aa8dff08d7b11832f/go/test/endtoend/schemadiff/vrepl/schemadiff_vrepl_suite_test.go#L345-L428). We hook onto `vitess`'s pre-existing Online DDL tests, a suite that includes a multitude of scenarios. The suite already has a story: a table, a change, an expected result. In our `schemadiff` test we shuffle the logic: we have an original table and and expected table. We evaluate the diff. We apply the diff onto the original table. We expect the result to be identical to the expected table!

Because this runs in GitHub CI, we take advantage of a running MySQL server. We perform the test in-memory, and then also on MySQL itself, and so we have an authoritative validation for the `Apply()` functionality. For fun and glory, we also generate the reverse diff. This test cross validates the programmatic approach, the MySQL schema, and actual MySQL schema changes, and expects full compliance between all.
