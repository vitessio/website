---
title: Advanced usage
weight: 20
aliases: ['/docs/user-guides/schema-changes/advanced-usage/']
---

Listed below are recipes for advanced online DDL usage:

- [Duplicate migration detection](#duplicate-migration-detection)
- [Duplicate migration indication](#duplicate-migration-indication)
- [Near instant REVERTs](#near-instant-reverts)

## Duplicate migration detection

Two migrations sharing the same context and DDL are considered duplicate, and only one will run to completion.

Consider this DDL:

```sql
alter table `customer` add column `status` int unsigned not null;
```

You can only run this change successfully once. Once it it applied, the column `status` exists; any attempt to run the migration again yields an error.

Sometimes it is desirable to be able to retry a migration. For example, if you apply a migration on a sharded keyspace, where one or more of the shards can be down. In such scenario some shards receive and apply the DDL, while other shards do not, and are not aware of its existence. Attempting to re-apply the same DDL will generate errors on the shards that have received and applied it on the first attempt.

`vtctldclient ApplySchema` accepts a `--migration-context` flag. By default, Vitess auto-generates a unique context per execution of `vtctldclient ApplySchema`. You may supply your own value, which can be an arbitrary text (limited to `1024` characters). You may search for migrations with a particular context via `SHOW VITESS_MIGRATIONS LIKE '<context-value>'`. Also, any `SHOW VITESS_MIGRATIONS ...` command outputs the context value in the `migration_context` column.

When Vitess meets a migration which has exact same DDL and exact same (non-empty) context as some older migration, it considers it as a _duplicate_. The new migration does get a `UUID` of its own, and is tracked as a new migration. But if the previous migration (or, if there are multiple past duplicate migrations with same DDL and context, _any one of those_) is `complete`, then the new migration is also implicitly assumed to be `complete`.

Thus, the new migration does not get to execute if an identical previous migration was successful.

Usage:

```sh
$ vtctldclient ApplySchema --migration-context="1111-2222" --ddl-strategy='vitess' --sql "alter table customer add column status int unsigned not null" commerce

$ vtctldclient ApplySchema --migration-context="1111-2222" --ddl-strategy='vitess' --sql "alter table customer add column status int unsigned not null" commerce
```

In the above, the two calls are identical. Specifically, they share the exact same `--migration-context` value of `1111-2222`, and the exact same `--sql`.

Notes:

- As mentioned, the new migration will have its own `UUID`.
- The new migration does get to be scheduled.
- It will only be marked as `complete` if one previous identical migration (same DDL, same non-empty context) is likewise `complete`.
- If, for example, there's a single previous identical migration which is `failed`, the new migration gets to be executed.
- Continuing the above example: if the new migration is successful, the previous migration remains in `failed` state.
- The decision whether to run the migration or to mark it as implicitly `complete` only takes place when the migration is scheduled to run.

The context may also be set via VTGate:

```sql
mysql> set @@ddl_strategy='vitess --allow-concurrent';
mysql> set @@migration_context='1111-2222';
mysql> alter table customer add column status int unsigned not null;
```

By default, the migration context for an Online DDL issued via VTGate is the value of `@@session_uuid`. If `@@migration_context` is non-empty, then its value is used.

## Duplicate migration indication

You may go one step beyond [duplicate migration detection](#duplicate-migration-detection) by explicitly supplying migration UUIDs such that duplicate migrations are never submitted in the first place.

Consider the following example, note `--uuid-list` flag:

```sh
$ vtctldclient ApplySchema --uuid-list "73380089_7764_11ec_a656_0a43f95f28a3" --ddl-strategy='vitess' --sql "alter table customer add column status int unsigned not null" commerce

$ vtctldclient ApplySchema --uuid-list "73380089_7764_11ec_a656_0a43f95f28a3" --ddl-strategy='vitess' --sql "alter table customer add column status int unsigned not null" commerce
```

Normally Vitess generates a `UUID` for each migration, thus having a new, unique ID per migration. With `-uuid_list`, you can force Vitess into using your own supplied UUID. There cannot be two migrations with the same `UUID`. Therefore, any subsequent submission of a migration with an already existing `UUID` is implicitly discarded. The 2nd call does return the migration `UUID`, but is internally discarded.

This feature is useful for external management systems (e.g. schema deployment tools) which may want to control the identity of migrations. The external systems are thus able to own the UUID and can re-submit at will.

Notes:

- `--uuid-list` accepts zero or more comma separated UUID values
- If empty, Vitess calculates UUID for the migrations
- Number of supplied UUIDs must match the number of DDL statements in `--sql`
- Each UUID must be in [RFC 4122](http://www.ietf.org/rfc/rfc4122.txt) format, with underscored instead of dashes. Examples of valid UUIDs: `73380089_7764_11ec_a656_0a43f95f28a3`  and `28dc5ebc_78e6_11ec_accf_ab29e6ca1002`.
- If multiple UUIDs are given, they must all be different from one another.
- It is the caller's responsibility to ensure the UUIDs are indeed unique. If the user submits an `ApplySchema` with an already existing `--uuid-list=<UUID>` value, Vitess takes no steps to validate whether the DDL is identical to the already existing submission.

## Gated cut-over

Some migrations only make sense to run together; or, rather, it's desirable that they complete at the same time. This can be true:

- For multiple table changes in a single shard, and/or:
- For a table change across multiple shards.

The user may submit multiple migrations such that non auto-completes. The user can gather information as to whether all migrations are in a good position to complete, termed "ready to complete". The user may then invoke a `COMPLETE` command such that all migrations complete closely (but not atomically) to one another.

Consider the following:

```sh
$ vtctldclient ApplySchema --ddl-strategy='vitess --postpone-completion --allow-concurrent' --sql "alter table customer add column country int not null default 0; alter table order add column shipping_country int not null default 0" commerce
29231906_776f_11ec_a656_0a43f95f28a3
3cc4ae0e_776f_11ec_a656_0a43f95f28a3
```

The combination of `--postpone-completion --allow-concurrent` means migration start sequentially, but at some point all (two in our example) end up running [concurrently](../concurrent-migrations/).

A `show vitess_migrations like '29231906_776f_11ec_a656_0a43f95f28a3'` presents the column `ready_to_complete`, with values `0` (not ready) or `1` (ready).

When all migrations for the relevant UUIDs show `1` for `ready_to_complete`, the user can then either:

```sh
$ vtctldclient ApplySchema --sql "alter vitess_migration complete all" commerce
```

Assuming these are the only migrations awaiting completion, or, explicitly issue a complete for each of the migrations:

```sh
$ vtctldclient ApplySchema --sql "alter vitess_migration '29231906_776f_11ec_a656_0a43f95f28a3' complete all" commerce
$ vtctldclient ApplySchema --sql "alter vitess_migration '3cc4ae0e_776f_11ec_a656_0a43f95f28a3' complete all" commerce
```

## Near instant REVERTs

A [REVERT](../revertible-migrations/) operation is available for `CREATE`, `DROP` and `ALTER` statements. Both `CREATE` and `DROP` reverts are near instantaneous by design. An `ALTER`'s revert is fast, but not instantaneous. While it does not need to copy any table data, hence not proportional to table size and migration runtime, it does need to apply any changes made to the table since migration completion. This means tracking and applying binary log events, and the operation runtime is generally proportional to the time elapsed since migration completion.

It is possible to preemptively initiate an "open-ended" revert, such that a new workflow prepares the grounds for a revert, but requires a user interaction to actually cut over.

The use case and workflow is as follows:

- A long migration runs. The user suspects there might be a risk to the schema change
- As soon as the migration completes, the user issues an open ended revert, preparing the ground to undoing the schema change
- The open ended revert keeps track of binary log changes via VReplication
- If the original migration turns out to be fine, the user cancels the revert
- If the original migration has negative impact, the user completes the revert (thus undoing the schema change)

Consider the following example. We run a 5 hour long migration to drop an index:

```sh
$ vtctldclient ApplySchema --ddl-strategy='vitess' --sql "alter table customer drop index joined_timestamp_idx" commerce
29231906_776f_11ec_a656_0a43f95f28a3
```

As soon as the migration completes, we run:

```sh
$ vtctldclient ApplySchema --ddl-strategy='vitess --postpone-completion --allow-concurrent' --sql "revert vitess_migration '29231906_776f_11ec_a656_0a43f95f28a3'" commerce
3cc4ae0e_776f_11ec_a656_0a43f95f28a3
```

The above begins a `REVERT` migration that is open-ended (does not complete), via `--postpone-completion`. We also request the migration to run concurrently via `--allow-concurrent` such that it does not block any further "normal" migrations on other tables. Note `3cc4ae0e_776f_11ec_a656_0a43f95f28a3` is the UUID for the reverted migration.

Finally, if we are satisfied that the `drop index` migration went well, we issue:

```sh
$ vtctldclient ApplySchema --sql "alter vitess_migration '3cc4ae0e_776f_11ec_a656_0a43f95f28a3' cancel" commerce
```

That is, we cancel the `REVERT` operation.

Or, should we have not dropped the index? If our migration seems to have been wrong, we run:

```sh
$ vtctldclient ApplySchema --sql "alter vitess_migration '3cc4ae0e_776f_11ec_a656_0a43f95f28a3' complete" commerce
```

Which means we want to apply the revert. Since the revert is already running in the background, it is likely that binary log processing is up to date, and cut-over is near instantaneous.

## Inter-dependent migrations

It is possible to submit inter-dependent migrations within the same `ApplySchema` command, and have them complete in the correct order, even if they run concurrently. Examples for inter-dependent migrations:

- Creating two new views, one of which reads from the other.
- Adding a column to a table, and creating a new view that reads from that column.
- Adding a column to a table, altering an existing view that reads from that table, to now read the new column.

In the above examples there has to be a strict ordering to the migrations. You cannot just create a view that reads from a yet non-existent column.

`vitess` offers the `--in-order-completion` DDL strategy flag. It is the responsibility of the user to supply the migrations in a valid ordering, and it is `vitess`'s responsibility to _complete_ the migrations in that same order.

Note that there can be scenarios with impossible ordering. Those hardly make sense in production, in the first place, and it is the user's responsibility to supply a sequence that works. When in doubt, it's advisable to submit migrations in stages: only apply one migration to completion, and then apply another.

An example for in-order submission:

```sh
$ vtctldclient ApplySchema --ddl-strategy='vitess --allow-concurrent --in-order-completion' --sql "create table t1 (id int primary key); create view v1 as select id from t1;" commerce
```

{{< info >}}
- `--allow-concurrent` is optional, but is likely to be the main use case for using in-order completion.
- in-order completion also works with `--postpone-launch` and `--postpone-completion`.
{{< /info >}}
