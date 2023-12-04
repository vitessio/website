---
title: SleepTablet
series: vtctldclient
commit: a7f80a82e5d99cf00c253c3902367bec5fa40e5d
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
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

