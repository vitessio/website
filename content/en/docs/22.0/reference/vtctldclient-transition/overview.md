---
title: Overview
weight: 1
---

Vitess v14 introduced a new, strongly-typed gRPC interface for cluster management, called [`VtctldServer`][grpc_vtctld_server].
You can refer to the [original RFC][vtctld_server_rfc] for details, but the essential difference is the legacy `VtctlServer` implementation had a single, streaming RPC with the signature:

```protobuf
rpc ExecuteVtctlCommand(ExecuteVtctlCommandRequest) returns (stream ExecuteVtctlCommandResponse);
```

<br/>

The new interface has individual RPCs for each command, with command-specific request and response types.
Most RPCs are unary, while a few (`Backup`, for example) are streaming RPCs.

### Enabling the new service

In order to enable the new service interface, add `grpc-vtctld` to the list of services in the `--service_map` flag provided to `vtctld`.
Both the new and old interfaces may be run from the same `vtctld` instance, so during transition, most users will set `--service_map="grpc-vtctl,grpc-vtctld"`.

### Transitioning clients

The new service implementation comes with a corresponding client implementation, which is called [`vtctldclient`][vtctldclient_docs].
Most existing commands can be run directly from the new client, for example:

```
$ vtctldclient --server ":15999" GetCellInfoNames
zone1
```

<br/>

For the full list of commands, as well as the flags they support, you can refer to the [client documentation][vtctldclient_docs].

Not all commands are currently implemented, but both the old ([`vtctlclient`][vtctlclient_docs]) and new (`vtctldclient`) clients provide shim mechanisms to use the new and old interfaces, respectively.
That is to say: `vtctlclient VtctldCommand ...` allows you to run new `vtctldclient` CLI commands, and `vtctldclient LegacyVtctlCommand ...` allows you to run old `vtctlclient` CLI commands.
For more details, refer to [the documentation][legacy_shim_docs].

[grpc_vtctld_server]: ../../programs/vtctld/#grpc-vtctld-mdash-new-as-of-v14
[vtctld_server_rfc]: https://github.com/vitessio/vitess/issues/7058
[vtctldclient_docs]: ../../programs/vtctldclient/
[vtctlclient_docs]: ../../programs/vtctl/
[legacy_shim_docs]: ../legacy_shim/
