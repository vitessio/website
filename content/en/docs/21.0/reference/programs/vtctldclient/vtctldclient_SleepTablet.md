---
title: SleepTablet
series: vtctldclient
commit: 14b6873142558358a99a68d2b5ef0ec204f3776a
---
## vtctldclient SleepTablet

Blocks the action queue on the specified tablet for the specified amount of time. This is typically used for testing.

### Synopsis

SleepTablet <alias> <duration>

Blocks the action queue on the specified tablet for the specified duration.
This command is typically only used for testing.
		
The duration is the amount of time that the action queue should be blocked.
The value is a string that contains a possibly signed sequence of decimal numbers,
each with optional fraction and a unit suffix, such as “300ms” or “1h45m”.
See the definition of the Go language’s ParseDuration[1] function for more details.
Note that, in the SleepTablet implementation, the value should be positively-signed.

[1]: https://pkg.go.dev/time#ParseDuration


```
vtctldclient SleepTablet <alias> <duration>
```

### Options

```
  -h, --help   help for SleepTablet
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

