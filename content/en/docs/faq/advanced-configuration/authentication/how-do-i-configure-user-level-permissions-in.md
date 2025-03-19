---
title: "How do I configure user-level permissions in Vitess?"
shorten_nav_links: true
notoc: true
weight: 2
---

If you need to enforce fine-grained access control in Vitess, you cannot use the normal MySQL GRANT system to give certain application-level MySQL users more or fewer permissions than others. This is because Vitess uses connection pooling with fixed MySQL users at the VTTablet level, and implements its own authentication at the VTGate level. 

Not all of the MySQL GRANT system has been implemented in Vitess. Authorization can be done via table-level ACLs. Individual users at the VTGate level can be assigned 3 levels of permissions.
- Read (corresponding to SELECT)
- Write (corresponding to DML, e.g. INSERT, UPDATE, DELETE)
- Admin (corresponding to DDL, e.g. ALTER TABLE)

The tables to which the permissions apply can be enumerated or specified using a regular expression.

Vitess authorization via ACLs is applied at the VTTablet level, as opposed to on VTGate, where authentication is enforced. There are a number of [VTTablet command line parameters]((https://vitess.io/docs/user-guides/configuration-advanced/authorization/#vttablet-parameters-for-table-acls) that control the behavior of ACLs.
