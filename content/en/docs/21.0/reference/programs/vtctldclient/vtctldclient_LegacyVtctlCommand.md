---
title: LegacyVtctlCommand
series: vtctldclient
commit: 4bc3b998941037e0446f5c0899587e4093d79f57
---
## vtctldclient LegacyVtctlCommand

Invoke a legacy vtctlclient command. Flag parsing is best effort.

### Synopsis

LegacyVtctlCommand uses the legacy vtctl grpc client to make an ExecuteVtctlCommand
rpc to a vtctld.

This command exists to support a smooth transition of any scripts that relied on
vtctlclient during the migration to the new vtctldclient, and will be removed,
following the Vitess project's standard deprecation cycle, once all commands
have been migrated to the new VtctldServer api.

To see the list of available legacy commands, run "LegacyVtctlCommand -- help".
Note that, as with the old client, this requires a running server, as the flag
parsing and help/usage text generation, is done server-side.

Also note that, in order to defer that flag parsing to the server side, you must
use the double-dash ("--") after the LegacyVtctlCommand subcommand string, or
the client-side flag parsing library we are using will attempt to parse those
flags (and fail).

```
vtctldclient LegacyVtctlCommand -- <command> [flags ...] [args ...]
```

### Examples

```
LegacyVtctlCommand help # displays this help message
LegacyVtctlCommand -- help # displays help for supported legacy vtctl commands

# When using legacy command that take arguments, a double dash must be used
# before the first flag argument, like in the first example. The double dash may
# be used, however, at any point after the "LegacyVtctlCommand" string, as in
# the second example.
LegacyVtctlCommand AddCellInfo -- --server_address "localhost:1234" --root "/vitess/cell1"
LegacyVtctlCommand -- AddCellInfo --server_address "localhost:5678" --root "/vitess/cell1"
```

### Options

```
  -h, --help   help for LegacyVtctlCommand
```

### Options inherited from parent commands

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

