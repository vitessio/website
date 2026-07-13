---
title: Subsharding Vindex
weight: 15
---

### Introduction

A subsharding vindex is a functional unique vindex. It is constructed by using
a set of columns from the table to be sharded.  If all the columns in this
vindex are provided in a query's `WHERE` clause, then the query is guaranteed to
be routed to a single shard.  If an ordered subset of columns are provided,
starting with the first column in the vindex, then the query can usually be
routed to a subset of shards instead of all shards.

### Use cases

A common use case for a subsharding vindex is when a given entity’s data fits
on more than one shard (e.g a large tenant in a SaaS scenario) and there is
no suitable intermediary grouping construct.  Storing that entity’s data across
all shards will lead to scatter queries. Scatter queries are especially expensive for
keyspaces with large numbers of shards.

An additional use case could be geo-sharding, where the data for a particular
region should reside within a subset of shards which are co-located in that
region.

### Prerequisite
The subsharding vindex only works with Gen4 query planner.

### Usage

This vindex is registered as `multicol` vindex.
It takes 3 parameters as input:

1. `column_count` - the number of columns provided for using the vindex.
2. `column_vindex` - a list of functional vindexes, mapping to hashing functions, to be used on each column in turn to compute the hash value for that column.
3. `column_bytes` - number of bytes to be used from each column's hash value after applying its hashing function on it to produce keyspace id. These must sum to 8 bytes to make up the 64 bit keyspace ID.

Example usage in VSchema:

```json
"vindexes": {
  "multicol_vdx": {
    "type": "multicol",
    "params": {
      "column_count": "3",
      "column_bytes": "1,3,4",
      "column_vindex": "hash,binary,unicode_loose_xxhash"
    }
  }
}
```
```json
"tables": {
  "multicol_tbl": {
    "column_vindexes": [
      {
        "columns": ["cola","colb","colc"],
        "name": "multicol_vdx"
      }
    ]
  }
}
```
`column_count` is a required parameter.
A maximum of 8 columns can be used in this vindex i.e. `column_count <= 8`

`column_vindex` should contain the vindex names in a comma-separated list. It should be less than or equal to column_count.
The default vindex is `hash`, If a vindex is not provided for a column, then `hash` will be used for that column.
Each vindex in `column_vindex` should implement the following interface otherwise the initialization will fail. See below for the list of [standard Vitess vindexes](#hashing-function-implementation) that implement this interface.

```go
// Hashing defines the interface for vindexes that export the Hash function to be used by multi-column vindex.
type Hashing interface {
	Hash(id sqltypes.Value) ([]byte, error)
}
```

Here is an example of how the keyspace ID is constructed:

```
Given that we allocate bytes from the following columns:
c1 - 1 byte
c2 - 3 bytes
c3 - 4 bytes

For the column Cn -> Cn.Hash(Cn_values)[0 : n_bytes_allocated_for_column]

keyspace_id:
|_c1|_c2__c2__c2|_c3__c3__c3__c3|
|_0_|_1_|_2_|_3_|_4_|_5_|_6_|_7_|
```

`column_bytes` should contain the number of bytes for each column in a comma-separated list. The numbers should add up to 8.
If the number of bytes is not provided for all columns, they are inferred by assigning equal numbers to the remaining unassigned columns.

Example 1:

```
Given:
column_count = 5
column_bytes = 1, , 3

col 1 -> 1
col 2 -> not provided
col 3 -> 3
col 4 -> not provided
col 5 -> not provided

Calculated:
remaining bytes = 8 - 1 - 3 -> 4
remaining columns = 5 - 2 -> 3
col 2 -> 2
col 4 -> 1
col 5 -> 1
```

Example 2:
```
given: 3 columns, 8 bytes
output: c1 -> 3, c2 -> 3, c3 -> 2
```

Example 3:
```
given: 3 columns, first column is 1 byte.
output: c1 -> 1, c2 -> 4, c3 -> 3
```

### Hashing Function Implementation

The Vindexes that can be used in a subsharding vindex by implementing the required hashing interface are:

* `binary`
* `binary_md5`
* `hash`
* `numeric`
* `numeric_static_map`
* `reverse_bits`
* `unicode_loose_md5`
* `unicode_loose_xxhash`
* `xxhash`


### Example

For a concrete example, assume we have a table with `BIGINT` columns:

```
CREATE TABLE t1 (
    c1 BIGINT NOT NULL,
    c2 BIGINT NOT NULL,
    c3 BIGINT NOT NULL,
    c4 BIGINT NOT NULL,
    PRIMARY KEY (c1)
);
```

We want to form a subsharding vindex with 4 bytes from column `c1`, 2 bytes
from column `c2` and 2 bytes from column `c3`, using the `xxhash` hashing
function for each column. The complete vschema would look something like:

```
{
  "sharded": true,
  "vindexes": {
    "t1_multicol": {
      "type": "multicol",
      "params": {
        "column_count": "3",
        "column_bytes": "4,2,2",
        "column_vindex": "xxhash,xxhash,xxhash"
      }
    },
    "xxhash": {
      "type": "xxhash"
    }
  },
  "tables": {
    "t1": {
      "columnVindexes": [
        {
          "columns": [
            "c1",
            "c2",
            "c3"
          ],
          "name": "t1_multicol"
        }
      ]
    }
  }
}
```

Now, if we have a sharded Vitess cluster, let us observe the routing when all
columns are provided:

```
mysql> vexplain plan select * from t1 where c1=1 and c2=1 and c3=1 \G
*************************** 1. row ***************************
JSON: {
	"OperatorType": "Route",
	"Variant": "EqualUnique",
	"Keyspace": {
		"Name": "customer",
		"Sharded": true
	},
	"FieldQuery": "select c1, c2, c3, c4 from t1 where 1 != 1",
	"Query": "select c1, c2, c3, c4 from t1 where c1 = 1 and c2 = 1 and c3 = 1",
	"Table": "t1",
	"Values": [
		"1",
		"1",
		"1"
	],
	"Vindex": "t1_multicol"
}
1 row in set (0.00 sec)
```

This is as expected.  Let's see the plans when a subset of columns,
in order of their appearance in the vindex is provided:

```
mysql> vexplain plan select * from t1 where c1=1 and c2=1 \G
*************************** 1. row ***************************
JSON: {
	"OperatorType": "Route",
	"Variant": "SubShard",
	"Keyspace": {
		"Name": "customer",
		"Sharded": true
	},
	"FieldQuery": "select c1, c2, c3, c4 from t1 where 1 != 1",
	"Query": "select c1, c2, c3, c4 from t1 where c1 = 1 and c2 = 1",
	"Table": "t1",
	"Values": [
		"1",
		"1"
	],
	"Vindex": "t1_multicol"
}
1 row in set (0.00 sec)

mysql> vexplain plan select * from t1 where c1=1 \G
*************************** 1. row ***************************
JSON: {
	"OperatorType": "Route",
	"Variant": "SubShard",
	"Keyspace": {
		"Name": "customer",
		"Sharded": true
	},
	"FieldQuery": "select c1, c2, c3, c4 from t1 where 1 != 1",
	"Query": "select c1, c2, c3, c4 from t1 where c1 = 1",
	"Table": "t1",
	"Values": [
		"1"
	],
	"Vindex": "t1_multicol"
}
1 row in set (0.00 sec)
```

Note that the number of shards that these types of queries target. For queries that provide a
subset of the subsharding vindex's columns in the `WHERE` clause the target is
dependent on the structure (byte allocation) of the vindex and the number
of shards in the keyspace.

Next, let's show that providing no columns scatters (as expected):

```
mysql> vexplain plan select * from t1 \G
*************************** 1. row ***************************
JSON: {
	"OperatorType": "Route",
	"Variant": "Scatter",
	"Keyspace": {
		"Name": "customer",
		"Sharded": true
	},
	"FieldQuery": "select c1, c2, c3, c4 from t1 where 1 != 1",
	"Query": "select c1, c2, c3, c4 from t1",
	"Table": "t1"
}
1 row in set (0.01 sec)
```

Similarly, providing a column (or subset of columns) from the subsharding
vindex that does not include the first column will lead to a scatter:

```
mysql> vexplain plan select * from t1 where c3=1 \G
*************************** 1. row ***************************
JSON: {
	"OperatorType": "Route",
	"Variant": "Scatter",
	"Keyspace": {
		"Name": "customer",
		"Sharded": true
	},
	"FieldQuery": "select c1, c2, c3, c4 from t1 where 1 != 1",
	"Query": "select c1, c2, c3, c4 from t1 where c3 = 1",
	"Table": "t1"
}
1 row in set (0.00 sec)

mysql> vexplain plan select * from t1 where c2=1 and c3=1 \G
*************************** 1. row ***************************
JSON: {
	"OperatorType": "Route",
	"Variant": "Scatter",
	"Keyspace": {
		"Name": "customer",
		"Sharded": true
	},
	"FieldQuery": "select c1, c2, c3, c4 from t1 where 1 != 1",
	"Query": "select c1, c2, c3, c4 from t1 where c2 = 1 and c3 = 1",
	"Table": "t1"
}
1 row in set (0.00 sec)
```
