---
title: Character set support
description: Supported character sets and configuration
weight: 30
---

# Overview

Ideally all textual data should be unicode. The best character set to be used today is `utf8mb4` (4 byte UTF8), the successor to `utf8`. However, legacy systems may carry non-UTF characters sets, specific to European, Chinese, or other languages.

VReplication supports copying & streaming across multiple character sets. Moreover, it supports conversion from one character set to another. An important use case is importing from an external data source that uses non-UTF8 encoding, into a UTF8-encoded Vitess cluster.

Unless told otherwise, VReplication assumes the stream's source and target both use _trivial_ character sets that do not require any special encodings. These are:

- `utf8`
- `utf8mb4`
- `ascii`
- `binary`

To be able to work with other character sets:

- Verify VReplication supports the specific character sets.
- VReplication needs to be told how which character sets it's converting from/to.

# Supported character sets

The list of supported character sets is dynamic and may grow. You will find it under `CharacterSetEncoding` in https://github.com/vitessio/vitess/blob/main/go/mysql/constants.go

The current list of supported character sets/encodings is:

- ascii
- binary
- cp1250
- cp1251
- cp1256
- cp1257
- cp850
- cp852
- cp866
- gbk
- greek
- hebrew
- koi8r
- latin1
- latin2
- latin5
- latin7
- utf8
- utf8mb4

# Converting/encoding

- In VRecpliation's filter query, make sure to convert all non-trivial character sets to UTF like so:
 
```
select ..., convert(column_name using utf8mb4) as column_name, ...
```

- In VReplication's rule, add one or more `convert_charset` entries. Each entry is of the form: 

```
convert_charset:{key:"<column_name>" value:{from_charset:"<charset_name>" to_charset:"<charset_name>"}}
```

### Example

In this simplified example, we wish to stream from this source table:

```sql
create table source_names (
  id int,
  name varchar(64) charset latin1 collate latin1_swedish_ci,
  primary key(id)
)
```

And into this target table:

```sql
create table target_names (
  id int,
  name varchar(64) charset utf8mb4,
  primary key(id)
)
```

Note that we wish to convert column `name` from `latin1` to `utf8mb4`.

The rule would looks like this:

```
keyspace:"commerce" shard:"0" filter:{
  rules:{
    match:"target_names" 
    filter:"select `id` as `id`, convert(`name` using utf8mb4) as `name` from `source_names`" 
    convert_charset:{key:"name" value:{from_charset:"latin1" to_charset:"utf8mb4"}}
  }
}
```

# Internal notes

Right now `to_charset` is not actually used in the code. The write works correctly whether `to_charset` is specified or not, and irrespective of its value. It "just works"" because the data gets encoded from a `utf8` in Go-plane, via MySQL connector and onto the specific column. However, future implementations may require explicit definition of `to_charset`.

As for the filter query, right now it's the user's responsibility to identify non-UTF columns in the source table. In the future, Vitess should be able to auto detect those, and automatically select `convert(col_name using utf8mb4) as col_name`.
