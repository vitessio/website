---
title: Binlog Streaming
weight: 5
---

VTGate supports direct binlog streaming via the MySQL replication protocol (`COM_BINLOG_DUMP_GTID`) and gRPC (`BinlogDumpGTID` RPC). This allows standard CDC (Change Data Capture) tools like Debezium and Fivetran to connect to Vitess without special VStream-aware adapters.

{{< warning >}}
Only GTID-based replication (`COM_BINLOG_DUMP_GTID`) is supported. File/position-based replication (`COM_BINLOG_DUMP`) is not supported and returns an error.
{{< /warning >}}

For CDC workflows that need automatic resharding, multi-shard aggregation, or event filtering, use [VStream](../../vreplication/vstream/) instead.

## How It Works

```
┌─────────────┐      MySQL       ┌─────────────┐       gRPC        ┌─────────────┐      MySQL       ┌─────────────┐
│             │    Protocol      │             │                   │             │    Protocol      │             │
│  CDC Client │◄────────────────►│   VTGate    │◄─────────────────►│  vttablet   │◄────────────────►│    MySQL    │
│             │                  │             │                   │             │                  │             │
└─────────────┘                  └─────────────┘                   └─────────────┘                  └─────────────┘
```

When a CDC client sends `COM_BINLOG_DUMP_GTID` to VTGate:

1. VTGate routes the request to the targeted vttablet
2. vttablet opens a MySQL replication connection to its underlying MySQL instance
3. Binlog events stream from MySQL through vttablet and VTGate back to the client
4. Events pass through without parsing or filtering

## Configuration

### Enable Binlog Dump

Binlog streaming is disabled by default. Enable it with `--enable-binlog-dump` on VTGate:

```bash
vtgate --enable-binlog-dump
```

### Authorize Users

By default, no users can perform binlog dump operations. Use `--binlog-dump-authorized-users` to specify which users can stream binlogs:

```bash
# Allow specific users (comma-separated)
vtgate --enable-binlog-dump --binlog-dump-authorized-users="repl_user,cdc_user"

# Allow all users
vtgate --enable-binlog-dump --binlog-dump-authorized-users="%"
```

## Tablet Targeting

Binlog streaming requires targeting a specific shard. You can target at the shard level (`keyspace:shard`) or at the tablet level (`keyspace:shard@type|alias`).

Shard-level targeting routes through the gateway's health checking, so CDC tools don't need to know specific tablet aliases. However, tablet-level targeting is recommended when consistency between the initial snapshot and binlog position matters. This ensures:

1. The initial binlog position obtained from the tablet
2. Data read via `SELECT` statements
3. The binlog stream from that position forward

all come from the same tablet.

### Specifying Target via Username

Many CDC tools don't support setting a default database at connection time. VTGate allows specifying the target as part of the username using a pipe-delimited format:

```
user|keyspace:shard@type|alias
```

| Format | Username Example | Description |
|--------|-----------------|-------------|
| 2-piece | `vt_repl|commerce:0@primary` | User with target |
| 3-piece | `vt_repl|commerce:0@primary|zone1-100` | User with target and tablet alias |
| 4-piece | `vt_repl|commerce:0@primary|zone1-100|olap` | User with target, alias, and OLAP workload |

The target string follows the standard Vitess format: `keyspace:shard@tablet_type`.

### Specifying Target via USE Statement

If your CDC tool supports it, you can issue a `USE` statement before starting the binlog dump:

```sql
USE `commerce:0@primary`;
```

## Limitations

Binlog streaming has limitations compared to [VStream](../../vreplication/vstream/):

| Feature | Binlog Streaming | VStream |
|---------|-----------------|---------|
| Protocol | MySQL replication or gRPC | gRPC |
| Shard handling | One stream per shard | Consolidates multiple shards |
| Event filtering | No filtering | Filter by table, query predicate |
| Automatic failover | No | Yes |
| Reshard support | No | Yes |
| MoveTables support | No | Yes |
| Client compatibility | Any MySQL CDC tool | Requires VStream adapter |

Key limitations to be aware of:

- **Per-shard streaming**: You must run a separate binlog stream per shard. There's no automatic merging of events from multiple shards.
- **No automatic failover**: If the targeted tablet becomes unavailable, the stream fails. Your CDC client must detect this and reconnect to a different tablet.
- **No resharding support**: Binlog streaming doesn't handle `MoveTables` or `Reshard` operations. If your keyspace is resharded while streaming, you'll need to manually reconfigure your CDC streams.
- **No event filtering**: All binlog events from the underlying MySQL are streamed. Filtering must be done client-side.

If any of these limitations are problematic for your use case, use [VStream](../../vreplication/vstream/) instead.

## gRPC Access

VTGate also exposes binlog streaming via gRPC through the `BinlogDumpGTID` streaming RPC. This is useful for clients that can't or prefer not to use the MySQL replication protocol.

### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `keyspace` | string | Yes | The keyspace to stream binlog events from |
| `shard` | string | Yes | The specific shard within the keyspace |
| `tablet_type` | TabletType | No | Tablet type to stream from (default: PRIMARY) |
| `tablet_alias` | TabletAlias | No | Target a specific tablet by alias |
| `binlog_filename` | string | No | Binlog filename to start from (requires `tablet_alias`) |
| `binlog_position` | uint64 | No | Position within binlog file (requires `tablet_alias`) |
| `gtid_set` | string | No | GTID set to start streaming from (e.g., `uuid:1-100`) |
| `flags` | uint32 | No | Raw MySQL flags (e.g., `BINLOG_DUMP_NON_BLOCK`) |

If you don't specify `tablet_alias`, VTGate uses health-check-based tablet selection for routing. If you specify `binlog_filename` or a non-default `binlog_position`, you must also provide `tablet_alias` since binlog filenames and positions differ across replicas.

### Response

`BinlogDumpResponse` streams raw MySQL binlog packets, including MySQL protocol headers. Your client must parse these packets according to the MySQL binlog protocol.

## Example: Connecting with a MySQL Client

```bash
# Connect with tablet target in username
mysql -h vtgate-host -P 15306 -u 'vt_repl|commerce:0@primary|zone1-100' -p

# Get current binlog position
SHOW MASTER STATUS;

# The CDC tool would then use this position to start COM_BINLOG_DUMP_GTID
```

{{< info >}}
Binlog data contains all changes made to the database, including potentially sensitive information. Restrict `--binlog-dump-authorized-users` to specific service accounts, use TLS for connections to VTGate, and audit which users are accessing binlog streams. Be aware that binlogs may contain internal MySQL data beyond row changes.
{{< /info >}}
