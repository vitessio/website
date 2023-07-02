---
title: Components
description: Frequently Asked Questions about Vitess
weight: 2
---

## How can I change MySQL server variables in Vitess?

In general, if you want to apply global variables at the MySQL level, you have to do it through VTTablet. There are a few ways to do that in the operator, but we recommend that you use vtctldclient ExecuteFetchAsDba.

For example if you want to temporarily switch `sync_binlog` off on the MySQL that is being managed by a tablet with alias `zone1-0000000100` you would perform the following:

```sh
$ vtctldclient -server localhost:15999 ExecuteFetchAsDba zone1-0000000100 "set global sync_binlog=0"
```

This would show the following result after checking the variable:

```sh
$ vtctldclient -server localhost:15999 ExecuteFetchAsDba zone1-0000000100 "show variables like 'sync_binlog'"+---------------+-------+| Variable_name | Value |+---------------+-------+| sync_binlog   |     0 |+---------------+-------+
```

## Examples of how to use Vitess components

We have a couple of step through examples in Github [here](https://github.com/aquarapid/vitess_examples). Currently, these cover Operator Backup and Restore, Create Lookup Vindex, and VStream.
