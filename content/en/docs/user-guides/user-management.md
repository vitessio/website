---
title: User and Permission Management
weight: 11
aliases: []
---

Vitess uses its own mechanism for managing users and their permissions through VTGate. As a result, the `CREATE USER....` and
`GRANT...` statements will not work if sent through VTGate.

## Authentication

The Vitess VTGate component takes care of authentication for requests so you will need to add any users that should have access
to the Keyspaces via the command-line options to VTGate.

The simplest way to configure users is using a `static` auth method and we can define the users in a JSON formatted file or string.

```sh
$ cat > users.json << EOF
{
  "vitess": [
    {
      "UserData": "vitess",
      "Password": "supersecretpassword"
    }
  ],
  "myuser1": [
    {
      "UserData": "myuser1",
      "Password": "password1"
    }
  ],
  "myuser2": [
    {
      "UserData": "myuser2",
      "Password": "password2"
    }
  ]
}
EOF
```

Then we can load this into VTGate with:
```sh
vtgate $(cat <<END_OF_COMMAND
    -mysql_auth_server_impl="static"
    -mysql_auth_server_static_file="users.json"
    ...
    ...
    ...
END_OF_COMMAND
)
```

Now we can test our new users:

```
$ mysql -h 127.0.0.1 -u myuser1 -ppassword1 -e "select 1"
+---+
| 1 |
+---+
| 1 |
+---+

$ mysql -h 127.0.0.1 -u myuser1 -pincorrect_password -e "select 1"
ERROR 1045 (28000): Access denied for user 'myuser1'
```

## Authorization

Authorization in Vitess is enforced on a table-level by the underlying
VTTablets, and not by VTGate, as with authentication.  As an example,
say we have two services that want to run in their own keyspace and do
not want any other service to have access to their keyspace.

Building on the authentication setup above and assuming your Vitess
cluster already has 2 keyspaces setup:
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

$ vttablet -init_keyspace "keyspace1" -table-acl-config=acls_for_keyspace1.json -enforce-tableacl-config -queryserver-config-strict-table-acl ........
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
      "table_names_or_prefixes": [""],
      "readers": ["myuser2", "vitess"],
      "writers": ["myuser2", "vitess"],
      "admins": ["myuser2", "vitess"]
    }
  ]
}
EOF

$ vttablet -init_keyspace "keyspace2" -table-acl-config=acls_for_keyspace2.json -enforce-tableacl-config -queryserver-config-strict-table-acl ........
```

With this setup, the `myuser1` and `myuser2` users can only access their respective keyspaces, but the `vitess`
user can access both.

```sh
# Attempt to access keyspace1 with myuser2 credentials through vtgate
$ mysql -h 127.0.0.1 -u myuser2 -ppassword2 -D keyspace1 -e "select * from t"
ERROR 1045 (HY000) at line 1: vtgate: http://vtgate-zone1-7fbfd8cc47-tchbz:15001/: target: keyspace1.-80.master, used tablet: zone1-476565201 (zone1-keyspace1-x-80-replica-1.vttablet): vttablet: rpc error: code = PermissionDenied desc = table acl error: "myuser2" [] cannot run PASS_SELECT on table "t" (CallerID: myuser2)
target: keyspace1.80-.master, used tablet: zone1-1289569200 (zone1-keyspace1-80-x-replica-0.vttablet): vttablet: rpc error: code = PermissionDenied desc = table acl error: "myuser2" [] cannot run PASS_SELECT on table "t" (CallerID: myuser2)
```

Whereas myuser1 is able to access its keyspace fine:
```sh
$ mysql -h 127.0.0.1 -u myuser1 -ppassword1 -D keyspace1 -e "select * from t"
$
```

Note the use above of the following parameters:
 * `-enforce-tableacl-config`:  Fail to start VTTablet if there are no ACLs successfully configured.  This ensures ACL misconfigurations are caught at startup.
 * `-queryserver-config-strict-table-acl`:  only allow queries that pass table acl checks to ensure we do not allow other users.  You will typically need to pass this parameter for the ACLs to be successfully enforced, unless you strictly limit the universe of potential users at the VTGate authentication level.

The following option may be useful:
  * `-queryserver-config-enable-table-acl-dry-run`:  Only emits to the [TableACLPseudoDenied](configuring-components.md#tableaclallowed-tableacldenied-tableaclpseudodenied) metric when an ACL denies a request, but let the actual request pass through successfully.  This allows you to test and verify ACL changes without running the risk of breakage.
