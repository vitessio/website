---
title: Legacy Shim
weight: 2
---

To make transitioning from `vtctlclient` to `vtctldclient` easier, both binaries provide shim mechanisms to run commands with each other's CLI syntaxes (and backing RPC interfaces).
Let's take each in turn.

### `vtctldclient LegacyVtctlCommand`

The new client provides a top-level command to run commands over the legacy `vtctlclient` interface.
This is useful to be able to use the new client "everywhere" but still be able to use functionality from the old client that has not been migrated yet (e.g. `Reshard`).

For example:

```
$ vtctldclient --server ":15999" LegacyVtctlCommand -- Reshard show <keyspace.workflow_name>
```

You can also use this to transition a command in two phases, for example:

1. Start with the existing invocation:

```shell
vtctlclient --server ":15999" -- AddCellInfo --root /mycell --server_address "${some_topo_server}:1234"
```

2. Then "switch" to the new client but use the old code and syntax:

```shell
vtctldclient --server ":15999" LegacyVtctlCommand -- AddCellInfo --root /mycell --server_address "${some_topo_server}:1234"
```

3. Finally, update the command to use the new code and CLI (notice the flag change from `--server_address` to `--server-address` and the removal of the `--`):

```shell
vtctldclient --server ":15999" AddCellInfo --root /mycell --server-address "${some_topo_server}:1234"
```

### `vtctlclient VtctldCommand`

Conversely, the _old_ client also provides a top-level command to run commands over the new `vtctldclient` interface.
This is useful to migrate your scripts over before necessarily deploying the new, separate binary everywhere.

Taking the same example as above, in reverse:


1. Start with the existing invocation:

```shell
vtctlclient --server ":15999" -- AddCellInfo --root /mycell --server_address "${some_topo_server}:1234"
```

2. Then switch to the new code and syntax (note the flag change from `--server_address` to `--server-address`) _without_ switching the invoked client binary:

```shell
vtctlclient --server ":15999" -- VtctldCommand AddCellInfo --root /mycell --server-address "${some_topo_server}:1234"
```

3. Finally, update the command to use the new binary, cleaning up the extra flag separators (`--`) as well.

```shell
vtctldclient --server ":15999" AddCellInfo --root /mycell --server-address "${some_topo_server}:1234"
```
