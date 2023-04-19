---
title: Components
description: Frequently Asked Questions about Vitess
weight: 1
---

## How does Vitess modify parameters on tablets?

In general if you want to apply global variables to tablets, you are going to have to connect to the tablet directly. There are a few ways to do that in the operator, but we recommend that you use vtctlclient ExecuteFetchAsDba.

For example if you want to switch sync_binlog off on a tablet temporarily you would performing the following:

```sh
$ vtctlclient -server localhost:15999 ExecuteFetchAsDba zone1-0000000100 "set global sync_binlog=0"
```

This would show the following result after checking the variable:

```sh
$ vtctlclient -server localhost:15999 ExecuteFetchAsDba zone1-0000000100 "show variables like 'sync_binlog'"+---------------+-------+| Variable_name | Value |+---------------+-------+| sync_binlog   |     0 |+---------------+-------+
```

## Examples of how to use Vitess components

We have a couple of step through examples in Github [here](https://github.com/aquarapid/vitess_examples). Currently, these cover Operator Backup and Restore, Create Lookup Vindex, and VStream.