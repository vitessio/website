---
title: VStream API and Resharding
description: How VStream API handles a reshard
weight: 8
aliases: ['/docs/design-docs/vreplication/vstream/stream-migration/']
---

## Stream Migration on a Resharding Operation

While subscribing to the [VStream API](../../vstream/) you need to specify the shards from which to stream events. While
streaming it is possible that the underlying keyspace is resharded. Thus some or all of the shards which were originally
specified may be replaced by new shards after the resharding operation is completed.

Stream migration logic within VReplication handles this transparently within `vtgate`. The Event streaming will be paused
momentarily during the actual cutover (when writes are switched) and you will start getting the events
([`VEvent`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#VEvent)) (and updated
[`VGTID`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#VGtid)s) for the new set of shards once the cutover
is completed.

### An Illustration

Here is a sample session using the scripts from the [local example](../../../../get-started/local).

Run the steps up to and including `205_clean_commerce.sh`. Now start a [VStream API](../../vstream/) client in a
separate terminal to stream events from the `customer` table in the `customer` keyspace, which is currently unsharded.

```json
{
  ShardGtids: []*binlogdatapb.ShardGtid{
        {
            Keyspace: "customer",
            Shard:    "0",
        },
    },
}
```

</br>

Initial events will be streamed:

```proto
[type:BEGIN  type:FIELD field_event:<table_name:"customer.customer" fields:<name:"customer_id" type:INT64 table:"customer" org_table:"customer" database:"vt_customer" org_name:"customer_id" column_length:20 charset:63 flags:49667 > fields:<name:"email" type:VARBINARY table:"customer" org_table:"customer" database:"vt_customer" org_name:"email" column_length:128 charset:63 flags:128 > > ]
[type:VGTID vgtid:<shard_gtids:<keyspace:"customer" shard:"0" gtid:"MySQL56/060a409d-8e10-11eb-9bb5-04ed332e05c2:1-45" > > ]
[type:ROW row_event:<table_name:"customer.customer" row_changes:<after:<lengths:1 lengths:16 values:"1alice@domain.com" > > >  type:ROW row_event:<table_name:"customer.customer" row_changes:<after:<lengths:1 lengths:14 values:"2bob@domain.com" > > >  type:ROW row_event:<table_name:"customer.customer" row_changes:<after:<lengths:1 lengths:18 values:"3charlie@domain.com" > > >  type:ROW row_event:<table_name:"customer.customer" row_changes:<after:<lengths:1 lengths:14 values:"4dan@domain.com" > > >  type:ROW row_event:<table_name:"customer.customer" row_changes:<after:<lengths:1 lengths:14 values:"5eve@domain.com" > > >  type:VGTID vgtid:<shard_gtids:<keyspace:"customer" shard:"0" gtid:"MySQL56/060a409d-8e10-11eb-9bb5-04ed332e05c2:1-45" table_p_ks:<table_name:"customer" lastpk:<rows:<lengths:1 values:"5" > > > > >  type:COMMIT ]
[type:BEGIN  type:VGTID vgtid:<shard_gtids:<keyspace:"customer" shard:"0" gtid:"MySQL56/060a409d-8e10-11eb-9bb5-04ed332e05c2:1-45" > >  type:COMMIT ]
```

</br>

Now run the resharding scripts and switch reads (steps/scripts 301, 302, 303, and 304). The following events are now seen:

```proto
[type:VGTID vgtid:<shard_gtids:<keyspace:"customer" shard:"0" gtid:"MySQL56/060a409d-8e10-11eb-9bb5-04ed332e05c2:1-46" > >  type:DDL timestamp:1616748652 statement:"alter table customer change customer_id customer_id bigint not null" current_time:1616748652480051077 ]
[type:VGTID vgtid:<shard_gtids:<keyspace:"customer" shard:"0" gtid:"MySQL56/060a409d-8e10-11eb-9bb5-04ed332e05c2:1-47" > >  type:OTHER timestamp:1616748652 current_time:1616748652553883482 ]
```

</br>

Run the 305 step/script to switch writes. You will see that the [`VGTID`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#VGtid)s)
will include the new shards `-80` and `80-` instead of `0`:

```proto
[type:BEGIN timestamp:1616748733 current_time:1616748733480901644  type:VGTID vgtid:<shard_gtids:<keyspace:"customer" shard:"0" gtid:"MySQL56/060a409d-8e10-11eb-9bb5-04ed332e05c2:1-48" > >  type:COMMIT timestamp:1616748733 current_time:1616748733480932466 ]
[type:BEGIN timestamp:1616748733 current_time:1616748733486715446  type:VGTID vgtid:<shard_gtids:<keyspace:"customer" shard:"0" gtid:"MySQL56/060a409d-8e10-11eb-9bb5-04ed332e05c2:1-49" > >  type:COMMIT timestamp:1616748733 current_time:1616748733486749728 ]

[type:BEGIN timestamp:1616748733 current_time:1616748733519198641  type:VGTID vgtid:<shard_gtids:<keyspace:"customer" shard:"80-" gtid:"MySQL56/6a60d315-8e10-11eb-b894-04ed332e05c2:1-76" > shard_gtids:<keyspace:"customer" shard:"-80" gtid:"MySQL56/629442b7-8e10-11eb-a0bb-04ed332e05c2:1-75" > >  type:COMMIT timestamp:1616748733 current_time:1616748733519244822 ]
[type:BEGIN timestamp:1616748733 current_time:1616748733520355854  type:VGTID vgtid:<shard_gtids:<keyspace:"customer" shard:"80-" gtid:"MySQL56/6a60d315-8e10-11eb-b894-04ed332e05c2:1-76" > shard_gtids:<keyspace:"customer" shard:"-80" gtid:"MySQL56/629442b7-8e10-11eb-a0bb-04ed332e05c2:1-76" > >  type:COMMIT timestamp:1616748733 current_time:1616748733520403210 ]
```

</br>

Insert new rows: this will result in row events from the new shards. Shards will only stream changes from the point of
resharding.

```bash
$ mysql -u root --host=127.0.0.1 -P 15306 -e "insert into customer(customer_id, email) values(6,'rohit@planetscale.com'), (7, 'mlord@planetscale.com')"
```

```proto
[type:BEGIN timestamp:1616749631 current_time:1616749631516372189  type:FIELD timestamp:1616749631 field_event:<table_name:"customer.customer" fields:<name:"customer_id" type:INT64 table:"customer" org_table:"customer" database:"vt_customer" org_name:"customer_id" column_length:20 charset:63 flags:53251 > fields:<name:"email" type:VARBINARY table:"customer" org_table:"customer" database:"vt_customer" org_name:"email" column_length:128 charset:63 flags:128 > > current_time:1616749631517765487  type:ROW timestamp:1616749631 row_event:<table_name:"customer.customer" row_changes:<after:<lengths:1 lengths:22 values:"6sougou@planetscale.com" > > row_changes:<after:<lengths:1 lengths:23 values:"7deepthi@planetscale.com" > > > current_time:1616749631517779353  type:VGTID vgtid:<shard_gtids:<keyspace:"customer" shard:"80-" gtid:"MySQL56/6a60d315-8e10-11eb-b894-04ed332e05c2:1-77" > shard_gtids:<keyspace:"customer" shard:"-80" gtid:"MySQL56/629442b7-8e10-11eb-a0bb-04ed332e05c2:1-76" > >  type:COMMIT timestamp:1616749631 current_time:1616749631517789376 ]
```
