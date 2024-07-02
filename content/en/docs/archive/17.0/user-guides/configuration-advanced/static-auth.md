---
title: File based authentication
weight: 2
---

The simplest way to configure users is using a `static` auth method, and we
can define the users in a JSON formatted file or string.

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

Then we can load this into VTGate with the additional commandline parameters:
```sh
vtgate $(cat <<END_OF_COMMAND
    --mysql_auth_server_impl=static
    --mysql_auth_server_static_file=users.json
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

## Generating passwords

You should always used generated random passwords in static configuration.
Also when using `caching_sha2_password` or `mysql_native_password` this
is a must as the formats don't provide any protection against password
retrieval attacks.

We recommend using at least as many bits of random entropy as the hashing
used, so for `caching_sha2_password` you should generate passwords with
256 bits (32 bytes) of randomness.

## Password format

In the above example we used plaintext passwords.  Vitess supports the
MySQL [caching_sha2_password](https://dev.mysql.com/doc/refman/8.0/en/caching-sha2-pluggable-authentication.html)
and [mysql_native_password](https://dev.mysql.com/doc/refman/8.0/en/native-pluggable-authentication.html)
hash formats. We recommend using the `caching_sha2_password` format unless
you must use `mysql_native_password` for legacy clients.

### Caching SHA2 Password

To use a `caching_sha2_password` hash, your user section in your static
JSON authentication file would look something like this instead:

```json
{
  "vitess": [
    {
      "UserData": "vitess",
      "CachingSha2Password": "*EDD6D7297051F55BF680A727FB9732672035A2AB65AB0426BA5ED76E1A0D9FCF"
    }
  ]
}
```

You can generate a hash for `caching_sha2_password with generating a SHA256
hash of the cleartext password string twice, e.g. doing it in
MySQL for the cleartext password `password`:

```mysql
mysql> SELECT UPPER(SHA2(UNHEX(SHA2("password", 256)), 256)) as hash;
+------------------------------------------------------------------+
| hash                                                             |
+------------------------------------------------------------------+
| 73641C99F7719F57D8F4BEB11A303AFCD190243A51CED8782CA6D3DBE014D146 |
+------------------------------------------------------------------+
1 row in set (0.00 sec)
```

So, you would use `*73641C99F7719F57D8F4BEB11A303AFCD190243A51CED8782CA6D3DBE014D146` as the
`CachingSha2Password` hash value for the cleartext password `password`.

### MySQL Native Password

To use a `mysql_native_password` hash, your user section in your static
JSON authentication file would look something like this instead:

```json
{
  "vitess": [
    {
      "UserData": "vitess",
      "MysqlNativePassword": "*9E128DA0C64A6FCCCDCFBDD0FC0A2C967C6DB36F"
    }
  ]
}
```

You can extract a `mysql_native_password` hash from an existing MySQL
install by looking at the `authentication_string` column of the relevant
user's row in the `mysql.user` table. An alternate way to generate this
hash is to SHA1 the cleartext password string twice, e.g. doing it in
MySQL for the cleartext password `password`:

```mysql
mysql> SELECT UPPER(SHA1(UNHEX(SHA1("password")))) as hash;
+------------------------------------------+
| hash                                     |
+------------------------------------------+
| 2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19 |
+------------------------------------------+
1 row in set (0.01 sec)
```

So, you would use `*2470C0C06DEE42FD1618BB99005ADCA2EC9D1E19` as the
`MysqlNativePassword` hash value for the cleartext password `password`.


## UserData

In the static authentication JSON file, the `UserData` string is **not**
the username;  the username is the string key for the list.  The `UserData`
string does **not** need to correspond to the username, and is used by the
[authorization mechanism](../authorization) when referring to a user.  It is
usually however simpler if you make the `UserData` string and the username
the same.

The `UserData` feature can be leveraged to create multiple users that are
equivalent to the authorization layer (i.e. multiple users having the same
`UserData` strings), but are different in the authentication layer (i.e.
have different usernames and passwords).

## Multiple passwords

A very convenient feature of the VTGate authorization is that, as can be
seen in the example JSON authentication files, you have a **list** of
`UserData` and `Password`/`MysqlNativePassword` pairs associated with
a user.  You can optionally leverage this to assign multiple different
passwords to a single user, and VTGate will allow a user to authenticate
with any of the defined passwords.  This makes password rotation
much easier;  and less likely to require or cause downtime.

An example could be:
```json
{
  "vitess": [
    {
      "UserData": "vitess_old",
      "CachingSha2Password": "*EDD6D7297051F55BF680A727FB9732672035A2AB65AB0426BA5ED76E1A0D9FCF"
    },
    {
      "UserData": "vitess_new",
      "CachingSha2Password": "*73641C99F7719F57D8F4BEB11A303AFCD190243A51CED8782CA6D3DBE014D146"
    }
  ]
}
```

This feature also allows different `UserData` strings
to be associated with a user depending on the password used.  This can
be used in concert with the [authorization mechanism](../authorization) to
migrate an application gracefully from one set of ACLs (or no ACLs)
to another set of ACLs, by just changing the password used by the
application.

In the example above, the username `vitess` has **two different** passwords
that would be allowed, each resulting in different `UserData` strings
(`vitess_old` or `vitess_new`) being passed to the VTTablet layer that can
be used for authorization/ACL enforcement.
