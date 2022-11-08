---
title: VStream
description: Change event streams
weight: 75
---

Vitess Gateways (`vtgate`) provide a `VStream` API that allows clients to subscribe
to a change event stream for a set of tables.

## Use Cases

 * **Change Data Capture (CDC)**: `VStream` can be used to capture changes to a
   table and send them to a downstream system. This is useful for building
   real-time data pipelines.

## Overview

`VStream` supports copying the current contents of a table — as you will often not
have the binary logs going back to the creation of the table — and then begin streaming
new changes to the table from that point on. It also supports resuming this initial copy
phase if it's interrupted for any reason.

Events in the stream are [MySQL row based binary log events](https://dev.mysql.com/doc/refman/en/mysqlbinlog-row-events.html)
and can be processed by event bridges which support Vitess such as
[Debezium](https://debezium.io/documentation/reference/stable/connectors/vitess.html)
and to some extent bridges that support MySQL such as
[GoldenGate](https://docs.oracle.com/en/middleware/goldengate/core/21.3/gghdb/using-oracle-goldengate-mysql.html).
Other products such as [AirByte](https://airbyte.com) can also be used with [custom
Vitess connectors](https://docs.airbyte.com/connector-development/).

{{< warning >}}
We recommend Debezium as it has native Vitess support and has been used in production
environments by many Vitess users.
{{< /warning >}}

## API Details

## Notes

### More Reading

  * [VStream Copy design doc](https://vitess.io/docs/design-docs/vreplication/vstream/vscopy/)
