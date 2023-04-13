---
title: Authentication
description: Frequently Asked Questions about Vitess
weight: 5
---

## How do I set up MySQL authentication in Vitess?

Vitess uses its own mechanism for managing users and their permissions through VTGate. As a result, the CREATE USER.... and GRANT... statements will not work if sent through VTGate. Instead VTGate takes care of authentication for requests, so you will need to add any users that should have access to the Keyspaces via command-line options to VTGate.

The simplest way to configure users is via a static authentication method. You can define the users in a JSON formatted file or string. Then you can load this static method into VTGate with the additional command line parameters. 

You will be able to configure the UserData string and add multiple passwords. For password format, Vitess supports the MySQL mysql_native_password hash format and you should always specify your passwords using this in a non-test or external environment. 

To see an example of how to configure the static authentication file and more information on the various options please follow this [link](https://vitess.io/docs/13.0/user-guides/configuration-advanced/user-management/#authentication).

There are other authentication mechanisms that can be utilized including LDAP-based authentication and TLS client certificate-based authentication.

## How do I configure user-level permissions in Vitess?

If you need to enforce fine-grained access control in Vitess, you cannot use the normal MySQL GRANTs system to give certain application-level MySQL users more or less permissions than others. This is because Vitess uses connection pooling with fixed MySQL users at the VTTablet level, and implements its own authentication at the VTGate level. 

Not all of the MySQL GRANT system has been implemented in Vitess. Authorization can be done via table-level ACLs. Individual users can be assigned 3 levels of permissions and can be applied on a specified set of tables, which can be enumerated or specified by regex:
- Read (corresponding to read DML, e.g. SELECT)
- Write (corresponding to write DML, e.g. INSERT, UPDATE, DELETE)
- Admin (corresponding to DDL, e.g. ALTER TABLE)

Vitess authorization via ACLs are applied at the VTTablet level, as opposed to on VTGate, where authentication is enforced. There are a number of VTTablet command line parameters that control the behavior of ACLs. You can see examples and read more about the command line parameters and further configuration options [here](https://vitess.io/docs/user-guides/authorization/#vttablet-parameters-for-table-acls). 