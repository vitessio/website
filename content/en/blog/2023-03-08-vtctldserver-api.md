---
title: "Vtctld Server API"
date: 2023-03-08T06:30:10-05:00
slug: '2023-03-08-vtctldserver-api'
tags:
- Vitess
- vtctld
- Cluster Management
description: A structured gRPC API for Vitess cluster management.
draft: true
---

We are more than thrilled to announce the general availability of `VtctldServer`, a new gRPC API to perform cluster management operations with `vtctld` components in your Vitess clusters.
This is the (near-) culmination of long, steady migration that began back in [Vitess v9][initial_pr] (!!!), so we'd like to talk a bit about the motivation behind the move, the design of the new API, and where we go from here.

## Why?

Vitess users may have found themselves invoking various cluster management operations (think `CreateKeyspace`, `EmergencyReparentShard`, `Backup`, and so on) via the `vtctlclient` program.
These commands communicate with a remote `vtctld` in the cluster via a gRPC interface defined as follows:

```proto
// proto/vtctlservice.proto

service VtctlServer {
    rpc ExecuteVtctlCommand(ExecuteVtctlCommandRequest) returns (stream ExecuteVtctlCommandResponse) {};
}

message message ExecuteVtctlCommandRequest {
    repeated string args = 1;
    int64 action_timeout = 2;
}

message ExecuteVtctlCommandResponse {
    Event event = 1;
}

// ===============

// proto/logutil.proto
message Event {
    // other fields omitted
    string value = 5;
}
```
<br/>

As the [RFC] points out, there are several issues with this design.

First, and most noticable, this is effectively an untyped interface, precisely the opposite of one of the biggest benefits of using an interface definition language (IDL) like gRPC.
Everything is just strings!
Can you `json.Unmarshal` it?
Sometimes!
Into what structures?
Depends!
Also, it can change at any time, because there's no way to guarantee backwards-compatibility at the protobuf definition level, and catching formatting breakages further downstream is hard to do for any API with nearly one hundred methods (hidden behind the façade of a single RPC method) with many, _many_ optional fields that are omitted most of the time.

Second, and much more subtly, this single RPC is a _streaming_ method.
This is necessary to support commmands such as `Backup`, which need to run uninterrupted by a closed connection, potentially for hours.
However, the design of `vtctld`'s logger essentially `tee`'s log lines both to a file and to the client.
This is used to send responses to the client _and_ to log useful information to a cluster operation for later inspection and debugging.
This means that _even if_ (1) you know the structure of the response data and (2) we're careful to never break that between versions, we can _still_ break your response parsing if we add a log line to a given command.
Computers are hard!

## `VtctldServer`

To solve these problems, we decided to [introduce a new gRPC interface to the `vtctld`][initial_pr], with the intention of replacing and eventually retiring the old interface.

It's defined in the same protobuf file, which results in the (possibly confusing) import name of [`vtctlservice.VtctldServer`][vtctldserver_protobuf].

### Structure

(A quick preface: We're going to mostly speak in generalities here, because to detail each individual special case, exception, and difference could turn this blog post into a novel-length [reamde][reamde].
We strongly advise checking the actual protobuf definitions and client `--help` output for a permanently-authoritative source)

In general, we created one unary RPC for each vtctl command that the old CLI tooling advertised.
Each RPC would take a request message, prefixed with the command name, and return a response message, and the CLI arguments would become fields on the request message.

For example, the `ApplyRoutingRules` vtctl command, defined as:

```go
func commandApplyRoutingRules(ctx context.Context, wr *wrangler.Wrangler, subFlags *pflag.FlagSet, args []string) error {
	routingRules := subFlags.String("rules", "", "Specify rules as a string")
	routingRulesFile := subFlags.String("rules_file", "", "Specify rules in a file")
	skipRebuild := subFlags.Bool("skip_rebuild", false, "If set, do no rebuild the SrvSchema objects.")
	dryRun := subFlags.Bool("dry-run", false, "Do not upload the routing rules, but print what actions would be taken")
	var cells []string
	subFlags.StringSliceVar(&cells, "cells", cells, "If specified, limits the rebuild to the cells, after upload. Ignored if skipRebuild is set.")

    // ... logic goes here
}
```
<br/>

becomes the following RPC:

```proto
// proto/vtctlservice.proto
service Vtctld {
    rpc ApplyRoutingRules(vtctldata.ApplyRoutingRulesRequest) returns (vtctldata.ApplyRoutingRulesResponse) {};
}

// ===============

// proto/vtctldata.proto
message ApplyRoutingRulesRequest {
    vschema.ShardRoutingRules shard_routing_rules = 1;
    bool skip_rebuild = 2;
    repeated string rebuild_cells = 3;
}

message ApplyRoutingRulesResponse {
}
```
<br/>

This structure allows us to provide a well-defined interface for each individual cluster management action, as well as understand if a change is breaking compatibility between versions, neither of which were possible with the old structure.

Note that the `--dry-run` and `--rules_file` options are handled on the client side, and so did not make it into the request message definition. See &mdash; exceptions!.

There are few other general exceptions[^1] to call out, so you know what to look for when searching for a particular command or RPC.

#### Exception 1: Consolidation

First, in the old model, occasionally there were several instances of similar commands that we have compressed into a single RPC with different options to switch between the subtle behavioral differences.
That was ... pretty wordy, so, an example!

Before:

```go
func commandGetTablet(...) // "<tablet alias>"
func commandListAllTablets(...) // "[--keyspace=''] [--tablet_type=<PRIMARY,REPLICA,RDONLY,SPARE>] [<cell_name1>,<cell_name2>,...]"
func commandListTablets(...) // "<tablet alias> ..."
func commandListShardTablets(...) // "<keyspace/shard>"
```
<br/>

After:

```proto
service Vtctld {
    rpc GetTablet(vtctldata.GetTabletRequest) returns (vtctldata.GetTabletResponse) {};
    rpc GetTablets(vtctldata.GetTabletsRequest) returns (vtctldata.GetTabletsResponse) {};
}

message GetTabletRequest {
    topodata.TabletAlias tablet_alias = 1;
}

message GetTabletResponse {
    topodata.Tablet tablet = 1;
}

message GetTabletsRequest {
    // Keyspace is the name of the keyspace to return tablets for. Omit to return
    // tablets from all keyspaces.
    string keyspace = 1;
    // Shard is the name of the shard to return tablets for. This field is ignored
    // if Keyspace is not set.
    string shard = 2;
    // Cells is an optional set of cells to return tablets for.
    repeated string cells = 3;
    // Strict specifies how the server should treat failures from individual
    // cells.
    //
    // When false (the default), GetTablets will return data from any cells that
    // return successfully, but will fail the request if all cells fail. When
    // true, any individual cell can fail the full request.
    bool strict = 4;
    // TabletAliases is an optional list of tablet aliases to fetch Tablet objects
    // for. If specified, Keyspace, Shard, and Cells are ignored, and tablets are
    // looked up by their respective aliases' Cells directly.
    repeated topodata.TabletAlias tablet_aliases = 5;
    // tablet_type specifies the type of tablets to return. Omit to return all
    // tablet types.
    topodata.TabletType tablet_type = 6;
}

message GetTabletsResponse {
    repeated topodata.Tablet tablets = 1;
}
```
<br/>

So, depending on which fields you set in a `GetTablets` call, you will get either the behavior of `ListTablets`, `ListAllTablets`, or `ListShardTablets`.
Meanwhile, the `GetTablet` RPC is a 1-to-1 drop-in for the legacy `GetTablet` command.

#### Exception 2: Pluralization

Second, certain commands would only operate on a single instance of a resource at a time.
For example, if you wanted to delete N shards, you needed to make N round-trips to a `vtctl` by invoking N `DeleteShard` commands.

For these sorts of commands, we've tried to "pluralize" them, to operate on multiple reserouces with a single round-trip to the `vtctld`.
So, `DeleteShard` becomes `DeleteShards`, and `DeleteTablet` becomes `DeleteTablets`, and so on.
For the destructive operations (like the two `Delete*` RPCs above), we perform them sequentially, and, if any instance fails (i.e. we fail to delete the 3rd tablet), the overall RPC returns an error.

#### Exception 3: Streaming

As we said earlier, the old gRPC API had a single, _streaming_ RPC, through which all `vtctl` commands were proxied.
In most &mdash; but not all! &mdash; cases, these "streamed" responses only ever consisted of one packet from the server, but to properly consume stream, you needed to write a receive loop that would only ever iterate once:

```go
stream, err := client.ExecuteVtctlCommand(
    ctx,
    []string{"GetTablet", "zone1-101"},
    24 * time.Hour,
)
if err != nil {
    // Fail.
}
defer stream.Close()

for {
    e, err := stream.Recv()
    switch err {
    case nil:
        // Marshal the event's bytes into a tablet structure
        // and carry on with what you actually cared about doing.
    case io.EOF:
        break
    default:
        // Fail.
    }
}
```
<br/>

Silly!
That's why we moved to unary RPCs, which allows you to write the above code with the new API as:

```go
resp, err := client.GetTablet(
    ctx,
    &vtctldatapb.GetTabletRequest{
        Alias: &topodatapb.TabletAlias{Cell: "zone1", Uid: 101},
    },
)
if err != nil {
    // Fail.
}

// Do something with resp.Tablet, which is already a
// strucutred Tablet object.
```
<br/>

Ahhhh, isn't unary so much cleaner?

However, there are a few cluster management operations that legitimately benefit from a streaming model between the client and the server.
In those few cases, where we may have an extremely long-running operation, or want some sort of progress indication, we've kept the streaming response paradigm.
`Backup` and `Restore` are the two most clear examples, but again, we recommend you check against the actual RPC definition at time of programming for the authoritative source.

<!-- aside about how state machine commands like `Reshard` are actually better for these systems? -->

### Errors

In addition to the "one RPC per command" remit of the new API, the other noteworthy element of our gRPC implementation of that API is a revisiting of errors.
The old API's implementation almost exclusively[^2] returned plain Go `error` types back up to the `ExecuteVtctlCommand` implementation, which were dutifully translated by `grpc-go` into `UNKNOWN` errors, which is ... not super helpful.

When implementing the new API, we tried to, wherever possible, use the `vterrors` package to surface more helpful information back to the caller wherever possible.
Enjoy![^3]

## Status

At the time of publication, the new API is very nearly at parity with the legacy API.
There are just a few more commands to build RPCs for, most notably:

- `Reshard`, `MoveTables`, and the family of VReplication-related commands.
- `OnlineDDL` and its subcommands.

We are aiming to have these ready by v17, so stay tuned for that!

To help you understand what's there, what's not, and what's changed, we've provided a [transition guide][transition_guide] which also includes a [table][transition_table] outlining the naming differences between APIs.

It's also worth noting that many of the old API commands have been refactored to use the implementation powering the new API under the hood, with a small translation layer to transform the responses back into their old data structures ([like these](https://github.com/vitessio/vitess/blob/8f68f3f72fe8151beb531e7a16eef1abb0314809/go/vt/vtctl/vtctl.go#L1439-L1526)), if you needed some additional confidence in the correctness of the new implementation.

## Example: VTAdmin

The primary consumer of the new API within the Vitess codebase is [VTAdmin][vtadmin_blog_post].
It uses the structured gRPC interface to perform cluster management operations on all of the clusters it's configured to manage.
If you're looking for an example of the API from a client-side perspective, this is a good place to look.

A fair warning, though &mdash; there's a small bit of indirection to allow VTAdmin to proxy through "some `vtctld` in the cluster" as opposed to needing to dial a _particular_ `vtctld`, but from a "how do I use this API" perspective, just look for `cluster.Vtctld.{RPCMethodName}(...)` calls inside `go/vt/vtadmin`.

## Example: Audit backups

The other big benefit to the structured API is that it's (relatively) easy to program against.
You can import the gRPC client definition and then write well-typed code to fulfill more advanced automation needs you might have.
(You can also generate a client for your language of choice, say, Ruby or C++ and so on, but you don't want an example in those languages from me, I promise).

For example, you could write a program to assert that all your shards have had a backup created in the last hour, if that was something you cared about.
That could look roughly[^4] like:

```go
package main

import (
    "context"
    "flag"
    "log"
    "time"

    "vitess.io/vitess/go/protoutil"
    "vitess.io/vitess/go/vt/grpcclient"
    "vitess.io/vitess/go/vt/vtctl/grpcvtctldclient"
    "vitess.io/vitess/go/vt/vtctl/vtctldclient"

    mysqlctlpb "vitess.io/vitess/go/vt/proto/mysqlctl"
    vtctldatapb "vitess.io/vitess/go/vt/proto/vtctldata"
)

var (
    ksShards = flag.String("shards", "example/-", "CSV of <ks/shard> to check")
    server = flag.String("server", ":15999", "address of vtctld")
)

func checkShard(ctx context.Context, client vtctldclient.VtctldClient, now time.Time, ks string, shard string) error {
    resp, err := client.GetBackups(ctx, &vtctldatapb.GetBackupsRequest{
        Keyspace: ks,
        Shard: shard,
    })
    if err != nil {
        return err
    }

    if len(resp.Backups) < 1 {
        return fmt.Errorf("no backups for %s/%s", ks, shard)
    }

    // Sort resp.Backups by resp.Backups[i].Time >= resp.Backups[j].Time.
    // This puts the most recent backup at resp.Backups[0].

    backupTime := protoutil.TimeFromProto(resp.Backups[0].Time)
    if backupTime.After(now.Add(-1 * time.Hour)) {
        return fmt.Errorf("most recent backup for %s/%s is at %s, which is more than 1 hour ago", ks, shard, backupTime)
    }

    return nil
}

func main() {
    flag.Parse()

    var ksShardNames [][2]string // list of [2]string where first element is keyspace and second is shard

    // [elided]: iterate ksShards and parse each into keyspace and shard names

    client, err := grpcvtctldclient.NewWithDialOpts(*server, grpcclient.FailFast(false))
    if err != nil {
        panic(err)
    }

    now := time.Now()
    ctx := context.WithTimeout(context.Background(), 30 * time.Second)

    var wg sync.WaitGroup
    for _, ksShard := range ksShardNames {
        wg.Add(1)
        go func(ks, shard string) {
            defer wg.Done()
            if err := checkShard(ctx, client, now, ks, shard); err != nil {
                log.Printf(err)
            }
        }(ksShard[0], ksShard[1])
    }

    wg.Wait()
}

```
</br>

Neat, huh?

## `vtctldclient`

Of course, we're not going to make you write a bunch of code if you just want to invoke an RPC or two.
Similar to the old model, which included a `vtctlclient` binary for invoking vtctl commands on a remote server, we now include a `vtctldclient` for making RPCs to a remote server using the new API.

So, if you just need to fire off a quick RPC, or are feeling particularly bold and want to write the above example in a shell script, you can use the new binary for it:

```
$ vtctldclient --server ":15999" GetBackups "ks/-"
$ vtctldclient --server ":15999" ApplySchema --sql "CREATE TABLE foo (id INT(11) NOT NULL)" "my_other_ks"
```
<br/>

For more information, you can check the [reference docs][vtctldclient_reference_docs], or run `vtctldclient help` or `vtctldclient help <command>`.

A quick but important callout &mdash; note the additional "d"!
It's subtle, and the sheer number of consecutive, full-height consonants does not help the matter, but we've found it's very easy for old habits to omit it.
Omitting it, of course, results in your unintentionally using the old binary, which isn't what you wanted, probably won't work in subtle ways, and soon won't work at all.
To be extremely, annoyingly, pedantically, clear about it:

```diff
- vtctlclient
+ vtctldclient
```

## Future Work

We're publishing this at the tail end of the project, because we're excited and we want to share this with you, but there's still a small bit of future work to do!
Namely, we're going to finish the migration, adding RPCs and implementations for the vtctl commands that are still absent (see [Status](#status) above).
Then, we'll be deleting the old `vtctlclient` binary and corresponding protobuf service and message definitions, plus any related code.

This means you should start adopting the new client now (in v17), especially since the old client has already [been deprecated in v12][vtctlcommand_deprecation].

## Wrapping Up

We're really excited about this project coming to a close, and we hope you're able to use the new API to do some cool stuff, or, to simplify the cool stuff you were already doing!
We'd love to get your feedback: what you like, what you want to see, or anything at all!
You can find us [on GitHub][vitess_repo] or in the [Vitess slack][vitess_slack] in the `#feat-vtctl-api` channel.

[initial_pr]: https://github.com/vitessio/vitess/pull/7128
[reamde]: https://www.nealstephenson.com/reamde.html
[RFC]: https://github.com/vitessio/vitess/issues/7058
[transition_guide]: ../../docs/17.0/reference/vtctldclient-transition/
[transition_table]: ../../docs/17.0/reference/vtctldclient-transition/command_diff/
[vitess_repo]: https://github.com/vitessio/vitess
[vitess_slack]: https://vitess.io/slack
[vtadmin_blog_post]: ../../blog/2022-12-05-vtadmin-intro/
[vtctlcommand_deprecation]: https://github.com/vitessio/vitess/blob/7af519e7b983a5fb6bcb87a5c1ab9e8520f2e5f2/go/cmd/vtctl/vtctl.go#L177
[vtctldclient_reference_docs]: ../../docs/17.0/reference/programs/vtctldclient/
[vtctldserver_protobuf]: https://github.com/vitessio/vitess/blob/4e28f163609d5378a34d5b021e4d16261091905c/proto/vtctlservice.proto#L33

[^1]: Is this a new oxymoron?
[^2]: Notable exceptions include `CreateKeyspace` and `Backup`, which at least did some argument checking and returned `INVALID_ARGUMENT` errors in some cases.
[^3]: While we sincerely hope your RPCs don't fail, we at least want to be helpful if they do!
[^4]: We're omitting some details here, so this won't strictly compile, but it's directionally correct as an example.