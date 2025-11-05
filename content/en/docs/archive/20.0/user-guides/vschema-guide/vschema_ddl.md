---
title: VSchema DDL
weight: 30
---

VSchema DDL is an experimental feature that allows users to alter the VSchema by issuing "vschema ddls" directly to vtgate. The `vschema_ddl_authorized_users` flag specifies which users can alter the vschema.

### SHOW VSCHEMA TABLES

```
SHOW VSCHEMA TABLES
```

Shows tables in VSchema.

### SHOW VSCHEMA VINDEXES

```
SHOW VSCHEMA VINDEXES
```

Shows all vindexes in VSchema.

### SHOW VSCHEMA VINDEXES FROM tbl_name

```
SHOW VSCHEMA VINDEXES [FROM | ON] tbl_name
```

Shows vindexes from table `tbl_name` in VSchema.

### ALTER VSCHEMA ADD TABLE

```
ALTER VSCHEMA ADD TABLE {keyspace_name.tbl_name | tbl_name}
```

Adds the given table to the VSchema for the current keyspace.

### ALTER VSCHEMA DROP TABLE

```
ALTER VSCHEMA DROP TABLE {keyspace_name.tbl_name | tbl_name}
```

Drops the table from the VSchema for the current keyspace.

### ALTER VSCHEMA CREATE VINDEX

```
ALTER VSCHEMA CREATE VINDEX vindex_name USING vindex_type [WITH vindex_option[, vindex_option] ...]

vindex_option: {
  name = value
}
```

Creates a vindex with the specified `vindex_type` and `vindex_option`s.

For the various vindex types and vindex options see [Vindexes documentation](https://vitess.io/docs/17.0/reference/features/vindexes/#predefined-vindexes).

### ALTER VSCHEMA DROP VINDEX

```
ALTER VSCHEMA DROP VINDEX vindex_name
```

Drops a vindex from the VSchema.

### ALTER VSCHEMA ON tbl_name ADD VINDEX

```
ALTER VSCHEMA ON tbl_name ADD VINDEX tbl_name.vindex_name (column_name[, column_name] ...) [USING vindex_type] [WITH vindex_option[, vindex_option] ...]
```

Adds a vindex for table `tbl_name` and columns `column_name`.

For the various vindex types and vindex options see [Vindexes documentation](https://vitess.io/docs/17.0/reference/features/vindexes/#predefined-vindexes).


### ALTER VSCHEMA ON tbl_name REMOVE VINDEX

```
ALTER VSCHEMA ON tbl_name REMOVE VINDEX tbl_name.vindex_name
```

Removes a vindex from table `tbl_name`.


### ALTER VSCHEMA ADD SEQUENCE

```
ALTER VSCHEMA ADD SEQUENCE tbl_name.seq_name
```

### ALTER VSCHEMA DROP SEQUENCE

```
ALTER VSCHEMA DROP SEQUENCE tbl_name.seq_name
```

### ALTER VSCHEMA ON ... ADD AUTO_INCREMENT

```
ALTER VSCHEMA ON tbl_name ADD AUTO_INCREMENT column_name USING tbl_name.seq_name
```

### ALTER VSCHEMA ON ... DROP AUTO_INCREMENT

```
ALTER VSCHEMA ON tbl_name DROP AUTO_INCREMENT
```
