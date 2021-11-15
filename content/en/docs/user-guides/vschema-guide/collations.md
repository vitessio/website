---
title: Collations
description:
weight: 1
---

### Collations

Vitess uses collations to compare strings the same way that MySQL uses `@collation_connection`, see [here](https://dev.mysql.com/doc/refman/8.0/en/charset-connection.html) for more information.

### Set the collation

#### VTGate

At the VTGate level we use the `-collation` flag to specify which collation we want to use.
Leaving this flag empty will result in VTGate picking the default collation of the `utf8mb4` charset.

The default collation of charsets varies depending on the backend database and its version.
For instance, the default collation for `utf8mb4` is `utf8mb4_general_ci` on MySQL57 and `utf8mb4_0900_ai_ci` on MySQL80.
For this reason, VTTablet is responsible for notifying VTGate which backend version of MySQL/MariaDB we are using.
This is done through health-check at start time.

#### VTTablet

VTTablet's collation and charset can respectively be set with `-db_collation` and `-db_charset`.
In a similar fashion as what we do in VTGate, using the backend database version, the charset defaults to `utf8mb4`, while the collation can be left empty, in which case the default collation of the charset will be picked.

### Internals

When VTTablet establish a connection with a MySQL server, the initial handshake happens using `utf8mb4_general_ci`.
With the handshake response, VTTablet resolves the server version and decides which collation to use if it was not explicitly set through the `-db_collation` flag.
Once VTTablet picked the collation it will use, it sets the `collation_connection` of the connection with MySQL.
