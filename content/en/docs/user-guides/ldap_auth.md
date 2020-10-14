---
title: LDAP authentication for vtgate
weight: 13
---

Vitess supports two ways to authenticate to `vtgate` via the
MySQL protocol today:
  * **Static** : provide a static configuration file to `vtgate` with
    user names and plaintext passwords or `mysql_native_password`
    password hashes.  This file can be reloaded without
    restarting `vtgate`. More details can be found [here](../user-management).
  * **LDAP** : provide the necessary details of an upstream LDAP
    server, along with credentials and configuration to query it.
    Using this information, the LDAP passwords for a user can then be used
    to authenticate the same user against `vtgate`.
    Integration with LDAP groups to allow ACLs to be managed
    using information from the LDAP server is also provided.

In this guide, we will examine the capabilities of the `vtgate` LDAP
integration, and how to configure them.

## Requirements

There are a few requirements, or the `vtgate` LDAP integration will not
work:
 * The communication between `vtgate` and the LDAP server has to be
   encrypted.
 * Encrypted communication to LDAP has to be via LDAP over TLS (STARTTLS)
   and not via LDAP over SSL (LDAPS). The latter is not a standardized
   protocol, and not supported by Vitess. Ensure that your LDAP server,
   and the LDAP URI (hostname/port) that you provide supports STARTTLS.
 * The application MySQL protocol connections to `vtgate` that use LDAP
   usernames/passwords need to use TLS. This is required because of the
   next point, but can be bypassed (strongly **NOT** recommended).
 * The application needs to be able to, and configured to, pass its password
   authentication using the cleartext MySQL authentication protocol.
   This is why it is required that the MySQL connection to `vtgate` be
   encrypted first.  This is required because LDAP servers do not
   standardize their password hashes, and as a result, a cleartext password
   is required by `vtgate` to bind (authenticate) against the LDAP server
   to verify the user's password.  Note that some applications might not
   support passing cleartext MySQL passwords without alteration or
   configuration.  And example is recent versions of the MySQL CLI client
   `mysql`, that needs the additional `--enable-cleartext-plugin` option
   to allow the passing of cleartext passwords.
  
## Configuration

To configure `vtgate` to integrate with LDAP, you will have to perform
various tasks:

  * Generate/obtain TLS certificate(s) for the `vtgate` server(s), and
    configure `vtgate` to use them.  More details can be found [here](https://github.com/aquarapid/vitess_examples/blob/master/tls/securing_vitess.md).
  * Obtain or add the necessary LDAP user/groups for integration with
    `vtgate`.  In general, you will need:
    * LDAP user entries for each of the MySQL users you want to use
      at the `vtgate` level. An example might be a readonly user, a
      readwrite user, and an admin/DBA user.
    * Ensure these users are part of one or more LDAP groups.  This
      is not strictly required by Vitess, but is leveraged to obtain
      group membership that can then be used in Vitess (`vttablet`)
      [ACLs](../authorization)).  At the moment if you use an LDAP user that
      is not a member of an LDAP group, the MySQL client authentication to
      `vtgate` will fail, even if the password is correct.
  * As mentioned above, you also need to have:
    * your LDAP server setup for STARTTLS
    * obtain the LDAP URI to connect to the LDAP server
    * have the CA certificate that your LDAP server TLS certificate
      is signed by in PEM format for configuring `vtgate`
    * Make sure that you are accessing the LDAP server via a hostname or
      IP SAN that is presented by your LDAP server TLS certficate. If
      not, you will not be able to use your LDAP server as-is.

Once you have your prerequisites above ready, you can now construct your
JSON configuration file for `vtgate` that you will pass to `vtgate` using
the commandline parameter `-mysql_ldap_auth_config_file`.  The content
of this file is a JSON format object with string key/value members
as follows:

```
{
    "LdapServer": "ldapserver.example.org:389",
    "LdapCert": "path/to/ldap-client-cert.pem",
    "LdapKey": "path/to/ldap-client-key.pem",
    "LdapCA": "path/to/ldap-server-ca.pem",
    "User": "cn=admin,dc=example,dc=org",
    "Password": "adminpassword!",
    "GroupQuery": "ou=groups,ou=people,dc=example,dc=org",
    "UserDnPattern": "uid=%s,ou=users,ou=people,dc=example,dc=org",
    "RefreshSeconds": 300
}
```

Not all these options are necessary in all configurations. Here are what
each key/value option represents:

  * `LdapServer` : hostname/IP and port to access the LDAP server via
    using [STARTTLS](https://www.digitalocean.com/community/tutorials/how-to-encrypt-openldap-connections-using-starttls).
    Note that as mentioned above, this needs to match the server
    TLS certificate presented by the LDAP server.  Required.
  * `LdapCert` : Path to the local file that contains the PEM format
    TLS client certificate that we want to present to the LDAP server.
    Optional unless we use client-certificates with the LDAP server.
    If we are using this option, `LdapKey` is also required.
  * `LdapKey` : Path to the local file that contains the PEM format
    TLS private key for the client certificate we want to present to
    the LDAP server. Optional unless we use client-certificates with
    the LDAP server. If we are using this option, `LdapCert` is also required.
  * `LdapCA` : Path to the local file that contains the PEM format TLS CA
    certificate to verify the TLS server certificate presented by the LDAP
    server against.  Required.
  * `User` : DN of the LDAP user we will be authenticating to the LDAP server
    to read information like group membership. Required, unless we are
    using LDAP client certificates to authenticate to the LDAP server.
    If we are using this option, `Password` option is also required.
  * `Password` : Cleartext password for the LDAP user specified above in
    `User`.  Required, unless we are using LDAP client certificates to 
    authenticate to the LDAP server.  If we are using this option, 
    `User` option is also required.
  * `GroupQuery` : LDAP base DN to start the group membership query
    from to establish the group the `User` specified (or implied
    via the client certificate) is a member of.  The group membership
    query itself is hardcoded to `(memberUid=%s)` where `%s` is the
    authenticating username.  Required.
  * `UserDnPattern` : LDAP DN pattern to autofill with MySQL username
    passed during MySQL client authentication to `vtgate`.  This DN
    is then used along with the password provided to `vtgate` to
    attempt to bind to the LDAP server with.  If the bind is sucessful,
    we know that the password provided to `vtgate` was valid.
    Required.
  * `RefreshSeconds` : Number of seconds that we should cache individual LDAP
    credentials for in-memory at the `vtgate`. This is used to reduce load on
    the LDAP for high traffic MySQL servers, and to also avoid short LDAP
    server outages causing Vitess/`vtgate` authentication outages. Default
    value is 0, which means **do not cache**. For production it is recommended
    to set this to something reasonably high, at least a few minutes. Optional.

Note that `vtgate` only does very basic validation of the values passed
here, and that incorrect configurations may just fail at runtime.  If you
are lucky, relevant errors may be logged by `vtgate`, but in many cases
incorrect configuration will just result in a `vtgate` instance that you
cannot log into via the MySQL protocol.  For debugging this, it is useful
to have access to the logs from your LDAP server that you are pointing to,
preferably at trace or debug level, so you can see each LDAP bind and search
operation against the LDAP server as you are testing.


Once you have constructured the above file, you will need to remove any
options that references static authentication from your `vtgate` commandline
like:
  * `-mysql_auth_server_static_file`
  * `-mysql_auth_server_static_string`
  * `-mysql_auth_static_reload_interval`
  * `-mysql_auth_server_impl static`

and add the following new options:

```
-mysql_auth_server_impl ldap -mysql_ldap_auth_config_file /path/to/ldapconfig.json
```

