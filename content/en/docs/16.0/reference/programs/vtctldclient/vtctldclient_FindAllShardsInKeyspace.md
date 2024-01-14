---
title: FindAllShardsInKeyspace
series: vtctldclient
commit: 6c9f87de69a1fdbf6a68ff8375b32a1c2abba291
---
## vtctldclient FindAllShardsInKeyspace

Returns a map of shard names to shard references for a given keyspace.

```
vtctldclient FindAllShardsInKeyspace <keyspace>
```

### Options

```
  -h, --help   help for FindAllShardsInKeyspace
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

