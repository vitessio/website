---
title: Configuration
description: Frequently Asked Questions about Vitess
weight: 2
---

## What foreign key support exists in Vitess?

If you are getting errors with foreign keys, please note that we generally discourage the use of foreign keys, and more specifically foreign key constraints. There may be unexpected consequences when using them in sharded keyspaces.  

However, you can use foreign key constraints when their scope is contained within a shard or unsharded keyspace. You may find that some foreign key syntax will not be accepted through `vtctlclient ApplySchema...`. You may be able to submit the foreign key syntax through vtgate or directly through the mysqld instance.  

Please note that if you do shard or re-shard an existing keyspqce with foreign keys, you will need to take extra steps to confirm they are working as intended. 

## How do I connect to vtgate using MySQL protocol?

In the example [vtgate-up.sh](https://github.com/vitessio/vitess/blob/main/examples/common/scripts/vtgate-up.sh) script you'll see the following lines:

```sql
-mysql_server_port $mysql_server_port \
-mysql_server_socket_path $mysql_server_socket_path \
-mysql_auth_server_static_file "./mysql_auth_server_static_creds.json" \
```

In this example, vtgate accepts MySQL connections on port 15306 and the authentication information is stored in the json file. You can then connect to it using the following command:

```sql
mysql -h 127.0.0.1 -P 15306 -u mysql_user --password=mysql_password
```

## Must the application know about the sharding scheme in Vitess?

The application does not need to know about how the data is sharded. This information is stored in a VSchema which the VTGate servers use to automatically route your queries. This allows the application to connect to Vitess and use it as if it’s a single giant database server.

## Can the primary/replica be pinned to one region?

Yes, you can keep a primary/replica in the primary region and can keep a read only replica in another region.

## Can data replication from a primary region cell be controlled?

If you want to replicate data from a primary region cell to secondary region cell you would need to use [VReplication](https://vitess.io/docs/reference/vreplication/vreplication/).

Please note that Vitess has some regulatory requirements that certain data can't leave the primary region.

## Can I change the default database name?

Yes. You can start vttablet with the `-init_db_name_override` command line option to specify a different db name. There is no downside to performing this override.