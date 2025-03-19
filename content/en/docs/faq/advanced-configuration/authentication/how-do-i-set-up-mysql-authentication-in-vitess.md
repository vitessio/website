---
title: "How do I set up MySQL authentication in Vitess?"
shorten_nav_links: true
notoc: true
weight: 1
---

Vitess uses its own mechanism for managing users and their permissions through VTGate. As a result, the CREATE USER.... and GRANT... statements will not work if sent through VTGate. Instead VTGate takes care of authentication for requests, so you will need to add any users that should have access to the Keyspaces via command-line options to VTGate.

The simplest way to configure users is via a static authentication method. You can define the users in a JSON formatted file or string. Then you can load this file into VTGate with the additional command line parameters. 

You will be able to configure the UserData string and add multiple passwords. For password format, Vitess supports the mysql_native_password hash format and you should always specify your passwords using this in a non-test or external environment. 

To see an example of how to configure the static authentication file and more information on the various options please read this [guide](https://vitess.io/docs/user-guides/configuration-advanced/user-management/#authentication).

There are other authentication mechanisms that can be utilized including LDAP-based authentication and TLS client certificate-based authentication.
