---
title: Subsharding Vindex
weight: 11
---

### Introduction

A subsharding vindex is a functional unique vindex. It is represented by using a set of columns from the table. 
If all the columns are provided in query routing using where clause then it is routed to single shard.
If subset of columns in order of the appearance are provided then the query is routed to subset of shards instead of all shards.

### Use Case

A common use case is when a given entity’s data fits on more than one shard (e.g a whale tenant) and there is no suitable intermediary grouping construct.
Storing that entity’s data across all shards will lead to expensive scatter queries.

This is also applicable for geo-sharding use cases where the data for particular region should recide in subset of shards which are co-located to that region.

### Usage

This vindex is registered as `multicol` vindex.

The Vindex takes in 3 inputs
1. `column_count` - the number of columns that would be provided for using the vindex.
2. `column_vindex` - hashing function each column will use to provide hash value for that column
3. `column_bytes` - bytes to be used from each column's hash value after applying hashing function on it to produce keyspace id.

Example Usage in VSchema:

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
`column_count` is the mandatory parameter that needs to be provided.
A maximum of 8 columns can be used in this vindex i.e. `column_count <= 8`

`column_vindex` should contain the vindex name in a comma-separated list. It should be less than equal to column_count.
Default vindex is `hash` vindex, any column for which vindex is not provided, the default vindex will be used.
Vindex in `column_vindex` should implement the below interface otherwise the initialization will fail.

```go
// Hashing defined the interface for the vindexes that export the Hash function to be used by multi-column vindex.
type Hashing interface {
	Hash(id sqltypes.Value) ([]byte, error)
}
```

Eg for how keyspace id is created
```
Given
c1 - 1 byte
c2 - 3 bytes
c3 - 4 bytes

For the column Cn -> Cn.Hash(Cn_values)[0 : n_bytes_allocated_for_column]

keyspace_id:
|_c1|_c2__c2__c2|_c3__c3__c3__c3|
|_0_|_1_|_2_|_3_|_4_|_5_|_6_|_7_|
```

`column_bytes` should contain bytes in a comma-separated list. The total count should be equal to 8 bytes.
If for some columns bytes are not represented then it is calculated by assigning equal bytes to remaining unassigned columns.

Eg:
```
Given:
column_count = 5
column_bytes = 1, , 3

col 1 -> 1
col 2 -> not-provided
col 3 -> 3
col 4 -> not-provided
col 5 -> not-provided

Calculated:
remaining bytes = 8 - 1 - 3 -> 4
remaining columns = 5 - 2 -> 3
col 2 -> 2
col 4 -> 1
col 5 -> 1
```

### Hashing Function Implementation
Below is the list of vindex that has implemented the hashing interface required to be passed in `column_vindex` for using `multicol` vindex.

* binary
* binary_md5
* hash
* numeric
* numeric_static_map
* reverse_bits
* unicode_loose_md5
* unicode_loose_xxhash
* xxhash
