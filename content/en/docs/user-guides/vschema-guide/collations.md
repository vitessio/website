---
title: Collations
description:
weight: 1
---

### Collations

Vitess uses collations to compare strings the same way that MySQL uses `@collation_connection`, see [here](https://dev.mysql.com/doc/refman/8.0/en/charset-connection.html) for more information.

### Set the collation

#### VTGate

The default collation of VTGate depends on VTTablet.
Through health-checks, VTGate receives the collation it needs to use.

#### VTTablet

VTTablet's collation and charset can respectively be set with `-db_collation` and `-db_charset`.
If the `-db_collation` flag is empty, we choose the collation using the charset based on the backend database version (MySQL80, MySQL57, ...), the charset defaults to `utf8mb4`.

> The default collation of charsets varies depending on the backend database and its version.
> 
> For instance, the default collation for `utf8mb4` is `utf8mb4_general_ci` on MySQL57 and `utf8mb4_0900_ai_ci` on MySQL80.

### Internals

When VTTablet establish a connection with a MySQL server, the initial handshake happens using `utf8mb4_general_ci`.
With the handshake response, VTTablet resolves the server version and decides which collation to use if it was not explicitly set through the `-db_collation` flag.
Once VTTablet picked the collation it will use, it sets the `collation_connection` of the connection with MySQL.
