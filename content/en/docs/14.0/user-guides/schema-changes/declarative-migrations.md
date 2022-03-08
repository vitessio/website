---
title: Declarative migrations
weight: 11
aliases: ['/docs/user-guides/schema-changes/declarative-migrations/']
---

Vitess's [managed schema changes](../managed-online-schema-changes/) offer _declarative_ online schema migrations:

- The user may indicate a desired table schema and Vitess will make it so, whether the table exists or not, or
- The user may indicate a table should not exist, and Vitess will make it so.

Declarative DDLs are expressed via:

- Complete `CREATE TABLE` statement (make the table in desired state)
- `DROP TABLE` statement (make the table go)

Altering tables in declarative DDL is done by issuing `CREATE TABLE` statements with the desired state. `ALTER` statements are not allowed.

Declarative DDLs have the property of being idempotent. For example, a user may submit the same `CREATE TABLE` statement _twice_, one after another. If the 1st is successful, then the 2nd is a noop, and considered as implicitly successful. Likewise, two `DROP TABLE` DDLs for same statement will each ensure the table does not exist. If the 1st is successful, then the 2nd has nothing to do and is implicitly successful.

## Usage

Add `-declarative` to any of the online DDL strategies. Example:

```sql

mysql> set @@ddl_strategy='vitess -declarative';

-- The following migration creates a new table:
mysql> create table decl_table(id int primary key);
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| b06475e5_8a74_11eb_badd_f875a4d24e90 |
+--------------------------------------+

-- The next migration will implicitly ALTER the table decl_table into desired state:
mysql> create table decl_table(id int primary key, ts timestamp not null);
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| b7d6e6fb_8a74_11eb_badd_f875a4d24e90 |
+--------------------------------------+

-- Next migration does not change table structure, hence is a noop and implicitly successful:
mysql> create table decl_table(id int primary key, ts timestamp not null);
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| 110574b1_8a75_11eb_badd_f875a4d24e90 |
+--------------------------------------+
```

Consider migration `b7d6e6fb_8a74_11eb_badd_f875a4d24e90` above, which results in an `ALTER`. A look into the migration shows:

```sql
mysql> show vitess_migrations like 'b7d6e6fb_8a74_11eb_badd_f875a4d24e90'\G
*************************** 1. row ***************************
                 id: 19
     migration_uuid: b7d6e6fb_8a74_11eb_badd_f875a4d24e90
           keyspace: commerce
              shard: 0
       mysql_schema: vt_commerce
        mysql_table: decl_table
migration_statement: create table decl_table (
	id int primary key,
	ts timestamp not null
)
           strategy: vitess
            options: -declarative
    added_timestamp: 2021-03-21 20:39:08
requested_timestamp: 2021-03-21 20:39:07
    ready_timestamp: 2021-03-21 20:39:10
  started_timestamp: 2021-03-21 20:39:10
 liveness_timestamp: 2021-03-21 20:39:13
completed_timestamp: 2021-03-21 20:39:13
  cleanup_timestamp: NULL
   migration_status: complete
           log_path: 
          artifacts: _b7d6e6fb_8a74_11eb_badd_f875a4d24e90_20210321203910_vrepl,
            retries: 0
             tablet: zone1-0000000100
     tablet_failure: 0
           progress: 100
  migration_context: vtgate:38368dbe-8a60-11eb-badd-f875a4d24e90
         ddl_action: alter
            message: ADD COLUMN `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        eta_seconds: 0
```
Note how while the migration statement is `create`, the migration's `ddl_action` ends up being `alter`, and `message` indicates the alter options.

You may add `-declarative` even if you otherwise supply flags to your favorite strategy. For example, the following is valid:
```sql
set @@ddl_strategy='gh-ost -declarative -max-load=Threads_running=100';
```

Vitess notes down the `-declarative` flag and does not pass it to `gh-ost`, `pt-osc` or `VReplication`.

## Implementation details

The user submits a declarative DDL. Tables schedule the migration to execute, but at time of execution, may modify the migration on the fly and end up running a different migration.

Consider the following types of migrations:

- A `REVERT` has no special behavior, it acts as a normal revert.
- `ALTER` is rejected (migration will fail)
- `DROP`: silently mark as successful if the table does not exist. Otherwise treat the DDL as a normal `DROP`.
- `CREATE`: either,
  - The table does not exist: proceed as normal `CREATE`
  - The table exists: evaluate the SQL diff between the existing table schema and the proposed schema. Either:
    - There is no diff (exact same schema): silently mark as successful
    - There is a diff: rewrite the DDL as an actual `ALTER`, run using relevant strategy.

Declarative DDLs are [revertible](../revertible-migrations/). Note:

- A declarative migration which ends up being an `ALTER` is only revertible if executed with `vitess` strategy.
- A declarative migration which ends up being a noop (and implicitly successful), implies a noop revert.
