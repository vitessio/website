---
title: User Management and Authentication
weight: 1
aliases: ['/docs/user-guides/user-management/'] 
---

Vitess uses its own mechanism for managing users and their permissions through
 VTGate. As a result, the `CREATE USER....` and
`GRANT...` statements will not work if sent through VTGate.

## Authentication

The Vitess VTGate component takes care of authentication for requests so we
will need to add any users that should have access to the Keyspaces via the
command-line options to VTGate.

VTGate supports multiple types of authentication:

* none - No authentication is performed. This is the default.
* static - [File-based authentication](../static-auth)
* ldap - [LDAP-based authentication](../ldap_auth)
* clientcert - TLS client certificate-based authentication
* vault - Vault-based authentication
