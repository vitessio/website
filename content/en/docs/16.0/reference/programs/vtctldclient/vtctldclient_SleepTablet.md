---
title: SleepTablet
series: vtctldclient
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
      --action_timeout duration           timeout for the total command (default 1h0m0s)
      --emit_stats                        If set, emit stats to push-based monitoring and stats backends
      --server string                     server to use for connection (required)
      --stats_backend string              The name of the registered push-based monitoring/stats backend to use
      --stats_combine_dimensions string   List of dimensions to be combined into a single "all" value in exported stats vars
      --stats_common_tags strings         Comma-separated list of common tags for the stats backend. It provides both label and values. Example: label1:value1,label2:value2
      --stats_drop_variables string       Variables to be dropped from the list of exported variables.
      --stats_emit_period duration        Interval between emitting stats to all registered backends (default 1m0s)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

