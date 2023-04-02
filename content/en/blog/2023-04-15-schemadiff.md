---
author: 'Shlomi Noach'
date: 2023-04-15
slug: '2023-04-15-schemadiff'
tags: ['Vitess','MySQL', 'DDL', 'schema']
title: 'schemadiff: in-memory schema diffing, normalization, validation and manipulation'
description: 'Introducing schemadiff, a best kept secret library available in Vitess'
---

`schemadiff` is a powerful internal library

# began as diff
# schema validation ->
  in table: colunms, keys, ...
# normalization
t(id int primary key) -> t(id in , primary key (id))
t(i int default null) -> (t i int)
t(i int(11) not null default 0) -> t(i int not null default 0)
t(name varchar COLLATE=utf8mb4_0900_ai_ci) CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci -> t(name varchar) CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
# apply() adhering to mysql rules
# dependencies, in-order

One of the interesting developments found in Vitess release v14 is an internal library called `schemadiff`, a best kept secret. At its core, `schemadiff` is a declarative library that can produce an SQL diff of entities: two tables, two views, or two full blown database schemas. But it then goes beyond that to normalize, validate, export, and even _apply_ schema changes, all declaratively and without having to use a MySQL server. Let's dive in to understand its functionality and capabilities.

## Quick initial examples

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
```sql
ALTER TABLE `t` MODIFY COLUMN `id` bigint, ADD KEY `name_idx` (`name`(16))
```

Or, we could have taken the shorter path:

```go
diffs, err := DiffSchemasSQL("create ...", "create ...", hints)
...
```

The first thing to note in the above examples is that everything takes place purely within `go` space, and there is no MySQL server nor library involved. `schemadiff` is purely declarative, and makes heavy use of Vitess' [`sqlparser`](https://github.com/vitessio/vitess/tree/main/go/vt/sqlparser) library.

## sqlparser

Vitess is a sharding and infrastructure framework running on top of MySQL, and masquerades as a MySQL server to route queries into relevant shards. It thus obviously must be able to parse MySQL's SQL dialect. `sqlparser` is the Vitess library that does so.

`sqlparser` utilizes a [classic yacc file](https://github.com/vitessio/vitess/blob/main/go/vt/sqlparser/sql.y) to parse SQL into an Abstract Syntax Tree (AST), with `golang` structs generated and populated by the parser. For example, a SQL `CREATE TABLE` statement is parsed into a [`CreateTable`](https://github.com/vitessio/vitess/blob/c85c24a65b1d3aa1cc4008714af10d1dccb28f98/go/vt/sqlparser/ast.go#L521-L529) instance:

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

`sqlparser` is devoid of semantic context. It merely deals with a programmatic reflection of SQL. It does not know if a certain table exists, nor does it care about type conversions in a `SELECT` query. As long as the syntax is valid, it is satisfied.

## Semantics

The AST's sole purpose is to faithfully represent a SQL query/command. But as a by-product, it can also serve as the base to a semantic analysis of the schema. Conside the following table definition:

```sql
CREATE TABLE `invalid` (
	`id` bigint,
	`title` varchar(64),
	`title` tinytext,
	PRIMARY KEY (`val`)
);
```

The above table is _syntactically_ valid, but _semantically_ invalid. There are two columns that go by the same name (`title`), and an index that covers a non-existent column (`val`). These are but two out of many possible errors.

A statement being parsable is a required, but insufficient condition for it to be valid. Fortunately, the generated AST is a well formed model of the query, which makes it possible to 

## The model: schemas, entities and diffs

## Declarative diffs


## A simple diff

## Validation

## Normalization

default null
character sets
index names

## Applying diffs

