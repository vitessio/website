---
title: Analyzing SQL statements in bulk
weight: 98
---

# Introduction 

This document covers the way our [VTexplain tool](../../reference/vtexplain) can be used to evaluate how Vitess executes multiple SQL statements. 

## Prerequisites

You can find a prebuilt binary version of the VTExplain tool in [the most recent release of Vitess](https://github.com/vitessio/vitess/releases/).

You can also build the `vtexplain` binary in your environment. To build this binary, refer to the [Build From Source](../../contributing/build-from-source) guide.

## Overview

To analyze multiple SQL queries and determine how Vitess executes each statement, follow these steps:

1. Gather the queries from your current production database
1. Filter out specific queries
1. Populate fake values for your queries
1. Run the VTexplain tool via a script
1. Add your SQL schema
1. Add your VSchema
1. Run the VTexplain tool and capture the output
1. Check your output for errors

## 1. Gather the queries from your current production database

These queries should be most, if not all, of the queries that are sent to your current production database tracked over an extended period of time. You may need to track your sent queries for days or weeks depending on your setup. You will need to normalize the queries you will be analyzing. To do this, you can use any MySAL monitoring tool, like VividCortex, Monyog, or PMM.

## 2. Filter out specific queries

Remove from your list any unsupported queries or queries from non-application sources. The following are examples of queries to remove are:

* LOCK/UNLOCK TABLES  -  These are likely coming from schema management tools, which you wouldn't want run against vtgate
* FLUSH/PURGE LOGS  - These are likely coming from management scripts
* performance_schema queries  -  This is not supported by Vitess 
* BEGIN/COMMIT  -  These are supported, but not as stand-alone queries in vtexplain

An example pipeline to filter out these specific queries is:
```
cat queries.txt \
 | grep -v performance_schema \
 | grep -v information_schema \
 | grep -v @@ \
 | grep -v "SELECT ? $" \
 | grep -v "PURGE BINARY" \
 | grep -v "^SET" \
 | grep -v "^EXPLAIN" \
 | grep -v ^query \
 | grep -v ^BEGIN \
 | grep -v ^COMMIT \
 | grep -v ^FLUSH \
 | grep -v ^LOCK \
 | grep -v ^UNLOCK \
 | grep -v mysql > queries_for_vtexplain.txt
```

## 3. Populate fake values for your queries

Once the queries are normalized in prepared statement style you will need to generate a populate fake values in order for VTExplain to run properly. An example pipeline you can run to do this is:

```
cat queries.txt \
 | perl -p -e 's#\? = \?#1 = 1#g' \
 | perl -p -e 's#= \?#="1"#g' \
 | perl -p -e 's#LIMIT \?#LIMIT 1#g' \
 | perl -p -e 's#\> \?#> "1"#g' \
 | perl -p -e 's#IN \(\?\)#IN (1)#g' \
 | perl -p -e 's#\? AS ONE#1 AS ONE#g' \
 | perl -p -e 's#BINARY \?#BINARY \"1\"#g' \
 | perl -p -e 's#\< \?#< "2"#g' \
 | perl -p -e 's#, \?#, "1"#g' \
 | perl -p -e 's#VALUES \(...\)#VALUES \(1,2\)#g' \
 | perl -p -e 's#IN \(\.\.\.\)#IN \(1,2\)#g' \
 | perl -p -e 's#\- \? #\- 50 #g' \
 | perl -p -e 's#BETWEEN \? AND \?#BETWEEN 1 AND 10#g' \
 | perl -p -e 's#LIKE \? #LIKE \"1\" #g' \
 | perl -p -e 's#OFFSET \?#OFFSET 1#g' \
 | perl -p -e 's#\?, \.\.\.#\"1\", \"2\"#g' \
 | perl -p -e 's#\/ \? #\/ \"1\" #g' \
 | perl -p -e 's#THEN \? ELSE \?#THEN \"2\" ELSE \"3\"#g' \
 | perl -p -e 's#THEN \? WHEN#THEN \"4\" WHEN#g' \
 | perl -p -e 's#SELECT \? FROM#SELECT \"6\" FROM#g' \
 | perl -p -e 's#SELECT \?  AS#SELECT id AS#g' \
 | perl -p -e 's#\`DAYOFYEAR\` \(\?\)#DAYOFYEAR \("2020-01-20"\)#g' \
 | perl -p -e 's#YEAR \(\?\)#YEAR \("2020-01-01"\)#g' \
 | grep -v mysql > queries_for_vtexplain.txt
 ```

## 4. Run the VTExplain tool via a script

In order to analyze every query in your list you likely will want to run a script to do this. We have an example python script below that assumes a sharded setup with 4 shards that you will need to adjust to match your individual requirements:

```
$ cat testfull.py
for line in open("queries_for_vtexplain.txt", "r").readlines():
    sql = line.strip()
    print("vtexplain -schema-file schema.sql -vschema-file vschema.json -shards 4 -sql '%s'" % sql)
x
$ python testfull.py > run_vtexplain.sh
```

## 5. Add your SQL schema

You will need to add your proposed SQL schema to the file created by the script (e.g. schema.sql). A very simple example SQL schema is below. You will need to create one that matches your needs.

```
$ cat schema.sql
CREATE TABLE `user` (
  `user_id` bigint(20) NOT NULL,
  `name` varchar(128) DEFAULT NULL,
  `balance` decimal(13,4) DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  KEY `balance` (`balance`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

## 6. Add your VSchema

You will need to add your VSchema to the file created by the script (e.g. schema.json). A very simple example VSchema to match the SQL schema is below. You will need to create one that matches your needs.

```
$ cat vschema.json
{
    "ks1": {
        "sharded": true,
        "vindexes": {
            "hash": {
                "type": "hash"
            }
        },
        "tables": {
            "user": {
                "column_vindexes": [
                    {
                        "column": "user_id",
                        "name": "hash"
                    }
                ]
            }
        }
    }
}
```

## 6. Run the VTExplain tool and capture the output

This step will generate the output you need to analyze to determine what queries may have issues with your proposed VSchema. It may take a long time to finish if you have a number of queries.

```
$ sh -x run_vtexplain.sh 2> vtexplain.output
```

## 7. Check your output

Once you have your full output in vtexplain.output you can use grep for ERROR to review any issues found.

### Example: Scatted across shards

The following query is scattered across both shards, and then aggregated by vtgate.

``` shell
$ vtexplain -schema-file schema.sql -vschema-file vschema.json -shards 2 -sql 'SELECT * FROM user;'
----------------------------------------------------------------------
SELECT * FROM user

1 ks1/-80: SELECT * FROM user limit 10001
1 ks1/80-: SELECT * FROM user limit 10001
----------------------------------------------------------------------
```

### Example: Error

The following query produces an error because the AVG function isn't supported for scatter queries across multiple shards.

``` shell
$ vtexplain -schema-file schema.sql -vschema-file vschema.json -shards
2 -sql 'SELECT avg(balance) FROM user;'
ERROR: vtexplain execute error in 'SELECT avg(balance) FROM user':
unsupported: in scatter query: complex aggregate expression
```

### Example: Single shard

The following query only targets a single shard because the query supplies the sharding key.

``` shell
$ vtexplain -schema-file schema.sql -vschema-file vschema.json -shards 2 -sql 'SELECT * FROM user WHERE user_id = 100;'
----------------------------------------------------------------------
SELECT * FROM user WHERE user_id = 100

1 ks1/80-: SELECT * FROM user WHERE user_id = 100 limit 10001
----------------------------------------------------------------------
```