---
title: ddl_strategy flags
weight: 4
aliases: ['/docs/user-guides/schema-changes/ddl-strategy-flags/']
---

[`ddl_strategy`](../ddl-strategies) accepts flags in command line format. The flags can be vitess-specific, or, if unrecognized by Vitess, are passed on the underlying online schema change tools.

## Vitess flags

Vitess respects the following flags. They can be combined unless specifically indicated otherwise:

- `--allow-concurrent`: allow a migration to run concurrently to other migrations, rather than queue sequentially. Some restrictions apply, see [concurrent migrations](../concurrent-migrations).
- `--allow-zero-in-date`: normally Vitess operates with a strict `sql_mode`. If you have columns such as `my_datetime DATETIME DEFAULT '0000-00-00 00:00:00'` and you wish to run DDL on these tables, Vitess will prevent the migration due to invalid values. Provide `--allow-zero-in-date` to allow either a fully zero-date or a zero-in-date inyour schema. See also [NO_ZERO_IN_DATE](https://dev.mysql.com/doc/refman/8.0/en/sql-mode.html#sqlmode_no_zero_in_date) and [NO_ZERO_DATE](https://dev.mysql.com/doc/refman/8.0/en/sql-mode.html#sqlmode_no_zero_date) documentation for [sql_mode](https://dev.mysql.com/doc/refman/8.0/en/sql-mode.html).

-- `cut-over-threshold=<duration>"`: set an explicit threshold and timeout for a `vitess` `ALTER TABLE` cut-over phase. The default cut-over threshold, if not specified, is `10s`. A `vitess` migration will not attempt to cut-over if the vstream, or replication lag, is more than the cut-over threshold. Also, during cut-over, table locks will timeout after the same cut-over threshold (aborting the operation).
  Normal values are in the range `5s`..`30s`. Too low and cut-over may never succeed because of the inherent async nature of `vitess` migrations. Too high and table locks will be placed for too long, effectively rendering the table inaccessible.

- `--declarative`: mark the migration as declarative. You will define a desired schema state by supplying `CREATE` and `DROP` statements, ad Vitess will infer how to achieve the desired schema. If need be, it will generate an `ALTER` migration to convert to the new schema. See [declarative migrations](../declarative-migrations).

- `--fast-range-rotation`: when the migration runs on a table partitioned by `RANGE`, and the migration either runs a single `DROP PARTITION` or a single `ADD PARTITION`, and nothing other than that, then this flags instructs Vitess to run the `ALTER TABLE` statement directly against MySQL, as opposed to running an Online DDL with a shadow table. For `DROP PARTITION`, this flag is actually always desired, and will possibly become default/redundant in the future. If all conditions are indeed met, then the migration is not revertible.

- `--in-order-completion`: a migration that runs with this DDL strategy flag may only complete if no prior migrations are still pending (pending means either `queued`, `ready` or `running` states). `--in-order-completion` considers the order by which migrations were submitted. Note that `--in-order-completion` still allows concurrency. In fact, it is designed to work with concurrent migrations. The idea is that while many migrations may run concurrently, they must _complete_ in-order.
  - This lets the user submit multiple migrations which may have some dependencies (for example, introduce two views, one of which reads from the other). As long as the migrations are submitted in a valid order, the user can then expect `vitess` to complete the migrations successfully (and in that order).
  - This strategy flag applies to any `CREATE|DROP TABLE|VIEW` statements, and to `ALTER TABLE` with `vitess|online` strategy.
  - It _does not_ apply to `ALTER TABLE` when using the `gh-ost`, `pt-osc`, `mysql`, or `direct` strategies.

- `--postpone-completion`: initiate a migration that will only cut-over per user command, i.e. will not auto-complete. This gives the user control over the time when the schema change takes effect. See [postponed migrations](../postponed-migrations).

  `--declarative` migrations are only evaluated when scheduled to run. If a migrations is both `--declarative` and `--postpone-completion` then it will remain in `queued` state until the user issues a `ALTER VITESS_MIGRATION ... COMPLETE`. If it turns out that Vitess should run the migration as an `ALTER` then it is only at that time that the migration starts.

- `--postpone-launch`: initiate a migration that remains `queued` and only launches per user command. See [postponed migrations](../postponed-migrations).

- `--singleton`: only allow a single pending migration to be submitted at a time. From the moment the migration is queued, and until either completion, failure or cancellation, no other new `--singleton` migration can be submitted. New requests will be rejected with error. `--singleton` works as a an exclusive lock for pending migrations. Note that this only affects migrations with `--singleton` flag. Migrations running without that flag are unaffected and unblocked.

- `--singleton-context`: only allow migrations submitted under same _context_ to be pending at any given time. Migrations submitted with a different _context_ are rejected for as long as at least one of the initially submitted migrations is pending.

  It does not make sense to combine `--singleton` and `--singleton-context`.

## Pass-through flags

Flags unrecognized by Vitess are passed on to the underlying schema change tools. For example, a `gh-ost` migration can run with:
```sql
set @@ddl_strategy='gh-ost --max-load Threads_running=200'
```
Since Vitess knows nothing about `--max-load` it will pass it on as a command line argument to `gh-ost`. Consult [gh-ost documentation](https://github.com/github/gh-ost) for supported command line flags.

Similarly, a `pt-online-schema-change` migration can run with:
```sql
set @@ddl_strategy='pt-osc --null-to-not-null'
```
Consult [pt-online-schema-change documentation](https://www.percona.com/doc/percona-toolkit/3.0/pt-online-schema-change.html) for supported command line flags.

The `vitess` strategy (formerly known as `online`) uses Vitess internal mechanisms and is not a standalone command line tool. therefore, it has no particular command line flags. For internal testing/CI purposes, the `vitess` strategy supports `--vreplication-test-suite`, and this flag must **not** be used in production as it can have destructive consequences.
