---
title: Migrating from MySQL
weight: 98
---

This guide covers the recommended approach to migrate from a typical installation of MySQL to using Vitess. It uses the approach of first validating that VTGate is able to parse and route the queries that your application(s) generate, and allows you to observe any potential latency increases from queries requiring an additional hop before execution.

Once this validation is complete, you may consider moving from external MySQL tablet servers to managed MySQL.

## Setting up MySQL

The example that we will show is similar to the [local get started](../../get-started/local) guide, except that `mysqlctl` will not be used to start `mysqld`. Vitess requires that you setup multiple `mysqld` servers, since it will only read from a rdonly replica for vertical split.

To simulate an external MySQL:





 We will instead use one `mysqld` as installed via the operating system package manager. To simulate some existing data, we will load the `commerce` sample database. You can skip this step if you have an existing MySQL server:

```
yum install mysql-server
mysql < commerce.sql
```

We need to setup some additional parameters which are not the default for MySQL, but are required by Vitess:
```
log-bin
gtid-mod=ON
enforce-gtid-consistency
```

This provides us with a known MySQL server with the following credentials:
```
host=127.0.0.1
port=3306
user=root
password=
```

## Setting Up Vitess

- Start etcd
- Start vtctld
- Start our tablet
- Start a VTgate server

## Routing Traffic Through VTGate

If your application supports READ/WRITE splitting, the first step recommended would be to send a small percentage of READ traffic through VTGate so that you can observe it with minimal load.

A lower risk alternative, is that you can also take a slow query log from your existing MySQL server, process it through `pt-query-digest`, and then pipe it directly to VTGate:

```
```

This method works because the formatting of the `pt-query-digest` report is represented as comments starting with '# '.

## Sending Writes to VTGate

As you gain confidence in Vitess, the next step is to include traffic that contains data modification(s). Assuming that Vitess is placed infront of a master (as it is in this example with only one MySQL server), you can start routing transactions directly to it.

A lower risk alternative, is that you can also only send a percentage of write traffic via Vitess (for example, modifying the configuration of only one of your application servers). Because Vitess does not maintain any state, it is quite safe to have some of the traffic passing through Vitess and some routing directly to MySQL.

## Recommended Observations

Vitess is usually very efficient at routing queries, but you should account for a slight query latency increase due to the additional network hop. In cloud environments estimating 1-2ms is a good starting point, but the actual number will vary (it may even reduce query latency, as features such as connection pooling reduce the load on your MySQL server).

VTGate will produce errors when it is not able to parse and route queries. You should be observing your applications, and making sure they are not receving query errors.



