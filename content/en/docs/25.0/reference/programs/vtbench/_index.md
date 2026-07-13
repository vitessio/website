---
title: vtbench
series: vtbench
---
## vtbench

vtbench is a load testing client for benchmarking query workloads against Vitess using different client/server protocols.

### Synopsis

vtbench executes the same SQL statement repeatedly across multiple parallel threads, measuring query latency and throughput. Three connection protocols are supported for testing different parts of the Vitess stack:

- **mysql**: MySQL protocol to VTGate (default)
- **grpc-vtgate**: gRPC protocol to VTGate
- **grpc-vttablet**: gRPC protocol directly to VTTablet

```
vtbench [flags]
```

### Examples

MySQL protocol to VTGate:
```
vtbench \
  --protocol mysql \
  --host vtgate-host.my.domain \
  --port 15306 \
  --user db_username \
  --db-credentials-file ./vtbench_db_creds.json \
  --db @replica \
  --sql "select * from loadtest_table where id=123456789" \
  --threads 10 \
  --count 10
```

gRPC to VTGate:
```
vtbench \
  --protocol grpc-vtgate \
  --host vtgate-host.my.domain \
  --port 15999 \
  --db @replica \
  --sql "select * from loadtest_table where id=123456789" \
  --threads 10 \
  --count 10
```

gRPC to VTTablet:
```
vtbench \
  --protocol grpc-vttablet \
  --host tablet-loadtest-00-80.my.domain \
  --port 15999 \
  --db loadtest/00-80@replica \
  --sql "select * from loadtest_table where id=123456789" \
  --threads 10 \
  --count 10
```

### Output

vtbench prints benchmark results including:

- **Average Rows Returned**: Mean rows per query
- **Errors**: Count of query errors by error code, or `Errors: 0` if none occurred
- **Average Query Time**: Mean latency per query
- **Total Test Time**: Wall-clock duration of the benchmark
- **QPS (Per Thread)**: Queries per second achieved by each thread
- **QPS (Total)**: Aggregate queries per second across all threads
- **Query Timings**: Latency histogram showing distribution of query times

Example output:
```
Initializing test with mysql protocol / 10 threads / 1000 iterations
Average Rows Returned: 1
Errors: 0
Average Query Time: 2.5ms
Total Test Time: 25.3s
QPS (Per Thread): 39.5
QPS (Total): 395.2
Query Timings:
1ms-2ms: 3500
2ms-5ms: 5800
5ms-10ms: 680
10ms-20ms: 20
```

When errors occur with `--continue-on-error`, the output shows error counts by code:
```
Errors:
  ALREADY_EXISTS: 5
  DEADLINE_EXCEEDED: 2
```

### Options

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--host` | string | | VTGate host(s) in the form `host1,host2,...` |
| `--port` | int | | VTGate port |
| `--unix-socket` | string | | VTGate unix socket (mutually exclusive with host/port) |
| `--protocol` | string | `mysql` | Client protocol: `mysql`, `grpc-vtgate`, or `grpc-vttablet` |
| `--user` | string | | Username for mysql protocol (password from `--db-credentials-file`) |
| `--db` | string | | Database name, keyspace, or target (e.g., `@replica`, `keyspace`, `keyspace/shard`) |
| `--sql` | string | | SQL statement to execute (required) |
| `--threads` | int | `2` | Number of parallel threads |
| `--count` | int | `1000` | Number of queries per thread |
| `--deadline` | duration | `5m` | Maximum duration for the test run |
| `--continue-on-error` | bool | `false` | Continue running on query errors instead of stopping |
| `--db-credentials-file` | string | | Path to JSON file containing database credentials |

### Error handling

By default, vtbench stops a thread when a query error occurs. Transient errors such as timeouts, connection resets, and deadlocks immediately halt the benchmark.

Use `--continue-on-error` to continue running through errors. Each thread executes its full `--count` of queries even when individual queries fail. Errors are logged and counted in the final summary. This is useful for:

- Measuring error rates under load
- Benchmarks where some errors are expected (e.g., duplicate key inserts)
- Understanding throughput in the presence of failures

The `--deadline` timeout is always respected, even with `--continue-on-error`. A canceled or timed-out context stops the benchmark regardless of this setting.
