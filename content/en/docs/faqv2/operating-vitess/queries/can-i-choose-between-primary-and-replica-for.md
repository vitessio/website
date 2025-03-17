---
title: "Can I choose between primary and replica for query routing?"
shorten_nav_links: true
notoc: true
weight: 2
---

You can qualify the keyspace name with the desired tablet type using the `@` suffix. This can be specified as part of the connection as the database name, or can be changed on the fly through the `USE` command.

For example, `ks@primary` will select `ks` as the default keyspace with all queries being sent to the primary. `ks@replica` will load balance requests across all `REPLICA` tablets, and `ks@rdonly` will choose `RDONLY`.

You can also specify the database name as `@primary`, `@replica` etc., which means that no default keyspace is specified, but that the requests are for the specified tablet type.

If no tablet type is specified, then VTGate chooses its default, which can be overridden with the `--default_tablet_type` command line argument.
