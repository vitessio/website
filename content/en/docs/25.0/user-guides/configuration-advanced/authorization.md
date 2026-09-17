---
title: Configuring Authorization
weight: 10
aliases: ['/docs/user-guides/authorization/'] 
---

A common question is how to enforce fine-grained access control in Vitess.
This question comes up because Vitess uses connection pooling with fixed
MySQL users at the VTTablet level, and implements its own authentication
at the VTGate level. As a result, you cannot use the normal MySQL GRANTs
system to give certain application-level MySQL users more or less permissions
than others.

The MySQL GRANT system is very extensive, and we have not reimplemented
all of this functionality in Vitess.  What we have done is to enable you
to provide authorization via table-level ACLs, with a few basic
characteristics:

 * Individual users can be assigned 3 levels of permissions:
   * Read (corresponding to read DML, e.g. `SELECT`)
   * Write (corresponding to write DML, e.g. `INSERT`, `UPDATE`, `DELETE`)
   * Admin (corresponding to DDL, e.g. `ALTER TABLE`)
 * Permissions are applied on a specified set of tables, which can be
   enumerated or specified by regex.

## VTTablet parameters for table ACLs

Note that the Vitess authorization via ACLs are applied at the VTTablet
level, as opposed to on VTGate, where authentication is enforced.
There are a number of VTTablet command line parameters that control the
behavior of ACLs.  Let's review these:

 * `--enforce-tableacl-config`:  Set this to `true` to ensure VTTablet will not
   start unless there is a valid ACL configuration. This is used to
   catch misconfigurations resulting in blanket access to authenticated
   users.
 * `--queryserver-config-enable-table-acl-dry-run`:  Set to `true` to check the
   table ACL at runtime, and only emit the
   [TableACLPseudoDenied](../../configuration-basic/monitoring)
   metric if a request would have been blocked. The request is then
   allowed to pass, even if the ACL determined it should
   be blocked.  This can be used for testing new or updated ACL policies.
   Default is `false`.
 * `--queryserver-config-strict-table-acl`: Set to `true` to enforce table ACL
   checking.  **This needs to be enabled for your ACLs to have any effect.**
   Any users that are not specified in an ACL policy will be denied.
   Default is `false`. See [Table ACL and CTE names](#table-acl-and-cte-names)
   for how table ACL resolves CTE names under this setting.
 * `--queryserver-config-acl-exempt-acl`:  Allows you to specify the name
   of an ACL (see below for format) that is exempt from enforcement.
   Allows you to separate the rollout and the subsequent enforcement of
   a specific ACL.
 * `--table-acl-config`: Path to a file defining the table ACL config.
 * `--table-acl-config-reload-interval`:  How often the `table-acl-config`
   should be reloaded.  Set this to allow you to update the ACL file on
   disk, and then have VTTablet automatically reload the file within this
   period.  Default is not to reload the ACL file after VTTablet startup.
   Note that even if you do not set this parameter, you can always force
   VTTablet to reload the ACL config file from disk by sending a SIGHUP
   signal to your VTTablet process.

## Table ACL and CTE names

VTTablet decides which real tables a query touches. It does not require a
permission for a name that is only a Common Table Expression (CTE) — a temporary
named result set that a `WITH` clause declares. VTTablet now resolves those
names the way MySQL does. Under strict table ACL
(`--queryserver-config-strict-table-acl`), this resolution change affects
enforcement in two ways, both without any flag or configuration change.

**Tightened.** A query can no longer hide a real table behind a same-named,
non-recursive CTE. In `WITH t AS (SELECT * FROM t) SELECT * FROM t`, the inner
reference to `t` is the real table. Only a recursive CTE may refer to its own
name inside its body, and this CTE is not recursive, so its inner `t` can only
mean the underlying table. The caller now needs the table's normal read
permission, the same permission a plain read of `t` always required. Previously,
such a query read the table with no permission at all.

Two narrower cases tighten the same way:

 * A `NEXT VALUE` statement requires write permission on its sequence,
   regardless of any same-named CTE a `WITH` clause declares.
 * When a parenthesized arm of a `UNION` declares its own `WITH`, that arm and
   any arm after it no longer see the CTE names the union declared before its
   first `SELECT`; a reference to one of those names in such an arm is the real
   table and needs its permission. In
   `WITH t AS (SELECT * FROM real1) SELECT * FROM t UNION ALL (WITH t AS (SELECT * FROM t) SELECT * FROM t)`,
   the first arm's `t` is still the union's leading CTE and needs no permission.
   The read permission on `t` is required because the second arm declares its own
   `WITH t AS (SELECT * FROM t)`, whose inner `t` is a same-named non-recursive
   CTE that resolves to the real table `t`, the same tightening as the main
   **Tightened** paragraph above. The caller needs read permission on `real1` and
   on `t`, two permissions in total.

**Loosened.** VTTablet no longer requires a permission for a CTE's name when the
CTE is referenced from a subquery, a derived table, or a union arm of the query
that declares it, or when the CTE is joined into a multi-table `UPDATE` or
`DELETE`. Such queries were previously denied under strict table ACL when no ACL
rule matched that name. In
`WITH t AS (SELECT * FROM real1) UPDATE real2 JOIN t ON real2.id = t.id SET real2.x = 8`,
`t` is a read source joined into the update, never a write target, so it needs
no permission of its own; the caller still needs its normal permissions on
`real1` and `real2`.

**Case sensitivity.** VTTablet compares a CTE's name to table names
byte-for-byte, case-sensitively, whereas MySQL matches them according to the
server's `lower_case_table_names` setting. On a server configured to fold
table-name case, `WITH T AS (SELECT * FROM real1) SELECT * FROM t` declares the
CTE as `T` and references it as `t`: MySQL reads the lowercase `t` as the CTE,
but VTTablet treats it as a real table `t` and requires that table's read
permission. This divergence is intentional. VTTablet does not know the server's
`lower_case_table_names` setting, and folding case blindly would open a bypass
on a case-sensitive server. It can only ever require an extra permission, never
skip one, so it errs toward denying and cannot cause an ACL bypass.

When strict table ACL is off, which is the default, nothing changes.

To find queries this change would newly deny before enforcing it, set
`--queryserver-config-enable-table-acl-dry-run` to `true` and watch the
[TableACLPseudoDenied](../../configuration-basic/monitoring) metric; the requests
still run while dry-run is on.

## Warning regarding ACL reloading

If you choose to reload the ACL config manually or on an interval,
and you are using the `-enforce-tableacl-config` option, your VTTablet
processes **will exit** if your table ACL config file contains an invalid
configuration at reload time. While this might be unexpected, this ensures
the highest level of security. Accordingly, it is very important to test
your ACL config thoroughly before applying, pay attention to access
permissions on the ACL config file, etc.

## Format of the table ACL config file

The file specified in the `--table-acl-config` parameter above is a JSON
file with the following example to explain the format:

```json
{
    "table_groups": [
        {
            "name": "aclname",
            "table_names_or_prefixes": [
                "%"
            ],
            "readers": [
                "vtgate-user1"
            ],
            "writers": [
                "vtgate-user2"
            ],
            "admins": [
                "vtgate-user3"
            ]
        },
        { "... more ACLs here if necessary ..." }
    ]
}
```

Notes:

 * `name`: This is the name of the ACL (`aclname` in the example above) and is
   what needs to be specified in `--queryserver-config-acl-exempt-acl`,
   if you need to exempt a specific ACL from enforcement.
 * `table_names_or_prefixes`:  A list of strings and/or regexes that allow
   a rule to target a specific table or set of tables.  Use `%` as in the
   example to specify all tables.  Note that only the SQL `%` "regex"
   wildcard is supported here at the moment.
 * `readers`:  A list of VTGate users, specified by their [UserData](../../configuration-advanced/user-management/#userdata)
   field in the authentication specification, that are allowed to read the
   tables targeted by this ACL rule. Typically allows `SELECT`.
 * `writers`:  A list of VTGate users that are allowed to write to the tables
   targeted by this ACL rule. Typically allows `INSERT`, `UPDATE` and `DELETE`.
 * `admins`:  A list of VTGate users that are allowed admin privileges on
   the tables targeted by this ACL rule.  Typically allows DDL privileges,
   e.g. `ALTER TABLE`. Note that this also includes some commands that might
   be thought of as DML, which are really DDL, like `TRUNCATE`)
 * Note that `writers` privilege does not imply `readers` privilege, and `admins`
   privilege does not imply `readers` or `writers`.  You need to therefore
   add your users to each list explicitly if you want them to have that
   level of access.
 * You cannot use multiple ACL rules to target the same (sub)set of tables.
   Therefore the tablenames specified by `table_names_or_prefixes`
   (or expanded by regexes) need to be non-overlapping between ACL rules.
   Additionally, you cannot have duplicate tablenames or overlapping regexes
   in the `table_names_or_prefixes` list in a single ACL rule.

## Example

Let's assume your Vitess cluster already has two keyspaces setup:

 * `keyspace1` with a single table `t` that should only be accessed by `myuser1`
 * `keyspace2` with a single table `t` that should only be accessed by `myuser2`

For the VTTablet configuration for `keyspace1`:
```sh
$ cat > acls_for_keyspace1.json << EOF
{
  "table_groups": [
    {
      "name": "keyspace1acls",
      "table_names_or_prefixes": ["%"],
      "readers": ["myuser1", "vitess"],
      "writers": ["myuser1", "vitess"],
      "admins": ["myuser1", "vitess"]
    }
  ]
}
EOF

$ vttablet --init-keyspace "keyspace1" --table-acl-config=acls_for_keyspace1.json --enforce-tableacl-config --queryserver-config-strict-table-acl ........
```

Note that the `%` specifier for `table_names_or_prefixes` translates to
"all tables".

Do the same thing for `keyspace2`:
```sh
$ cat > acls_for_keyspace2.json << EOF
{
  "table_groups": [
    {
      "name": "keyspace2acls",
      "table_names_or_prefixes": ["%"],
      "readers": ["myuser2", "vitess"],
      "writers": ["myuser2", "vitess"],
      "admins": ["myuser2", "vitess"]
    }
  ]
}
EOF

$ vttablet --init-keyspace "keyspace2" --table-acl-config=acls_for_keyspace2.json --enforce-tableacl-config --queryserver-config-strict-table-acl ........
```

With this setup, the `myuser1` and `myuser2` users can only access their respective keyspaces, but the `vitess`
user can access both.

```sh
# Attempt to access keyspace1 with myuser2 credentials through vtgate
$ mysql -h 127.0.0.1 -u myuser2 -ppassword2 -D keyspace1 -e "select * from t"
ERROR 1045 (HY000) at line 1: vtgate: http://vtgate-zone1-7fbfd8cc47-tchbz:15001/: target: keyspace1.-80.primary, used tablet: zone1-476565201 (zone1-keyspace1-x-80-replica-1.vttablet): vttablet: rpc error: code = PermissionDenied desc = table acl error: "myuser2" [] cannot run PASS_SELECT on table "t" (CallerID: myuser2)
target: keyspace1.80-.primary, used tablet: zone1-1289569200 (zone1-keyspace1-80-x-replica-0.vttablet): vttablet: rpc error: code = PermissionDenied desc = table acl error: "myuser2" [] cannot run PASS_SELECT on table "t" (CallerID: myuser2)
$
```

Whereas myuser1 is able to access its keyspace without error:
```sh
$ mysql -h 127.0.0.1 -u myuser1 -ppassword1 -D keyspace1 -e "select * from t"
$
```
## Negative ACLs

If you want to set up an authorization structure like the following:

 * Assume a database with the tables `t1`, `t2` and `t3`, and the database
 (`vtgate`) users `regular` and `privileged`.
 * Give read and write access to only tables `t1` and `t2` to user `regular`.
 * **Only** give user `privileged` access to read or write table `t3`.

You will need to construct an ACL config with two ACLs, and enumerate all the necessary table names in each ACL
(`t1` and `t2` in the first ACL;  `t3` in the second ACL). This type of configuration could be called "completely specified".

However, every time a non-privileged table is added to the schema, the
ACL config needs to be updated to add the table name to the config, or
user `regular` will not have access to it. For schemas with large numbers
of tables, and that change frequently, this can be a burden.

In general, it is not possible to express a "negative" target ACL in Vitess'
ACL config syntax, e.g.:  `Give this user access to all tables except these
specific ones`. It is possible to express an ACL config that is
equivalent to the above "completely specified" ACL config, but somewhat
easier to manage, even for large numbers of tables.

Consider the following example:

  * Your schema has a 100+ tables.
  * You regularly add new tables.
  * You have a special set of tables called `secret` and `supersecret`
    that you only want a specific `vtgate` user called `super` to have
    access to.
  * You have 3 other users:
    * `readonly` for read access to all tables, except `secret` and
      `supersecret`
    * `readwrite` for read and write access to all tables, except `secret`
       and `supersecret`
    * `dba` for read, write and admin access to all tables, except
      `secret` and `supersecret`.
  * You only a few other tables that start with the letter `s`, called
    `s1`, `s2`, `s3`.
  * We assume you do not use table names with upper case or other
    characters.

The idea of this configuration is that you construct access to the
non-sensitive data using wildcards of table names for each letter
of the alphabet. You then only need to specify table names fully for
the letter of the alphabet that our "special" tables start
with. In other words this still requires us to specify a list of table names, but
only for the letters of the alphabet that the "special" tables start
with. 

Here is the ACL config that satisfies the requirements:

```json
{
  "table_groups": [
    {
      "name": "acl1",
      "table_names_or_prefixes": ["a%", "b%", "c%", "d%", "e%", "f%", "g%", "h%", "i%", "j%", "k%", "l%", "m%", "n%", "o%", "p%", "q%", "r%", "t%", "u%", "v%", "w%", "x%", "y%", "z%", "s1", "s2", "s3"],
      "readers": ["readonly", "readwrite", "dba"],
      "writers": ["readwrite", "dba"],
      "admins": ["dba"]
    },
    {
      "name": "acl2",
      "table_names_or_prefixes": ["secret", "supersecret"],
      "readers": ["super"],
      "writers": ["super"],
      "admins": ["super"]
    }
  ]
}
```

Now, with the above ACL config, you only need to update the ACL config
if you add a new table that starts with the letter `s`.
