---
title: LegacyVtctlCommand
series: vtctldclient
commit: 0f751fbb7c64ca5280c5d4f58d038e1df5477c67
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
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

