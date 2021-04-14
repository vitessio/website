---
title: Query Serving
weight: 1
description: The frequent errors that the users might run into while querying Vitess
---

| Error Number | Error State |  Message | Meaning |
| :--: |:--: | :-- | -- |
| 1105 | HY000 | range queries are not allowed for insert statement: %s | TODO https://github.com/vitessio/vitess/blob/530ea87a538c4435f30b4cc443b2a318c77e2584/go/vt/vtgate/planbuilder/bypass.go#L31 |
| 1450 | HY000 | Changing schema from '%s' to '%s' is not allowed | Changing schema from rename command is not valid |
| 1109 | 42S02 | Unknown table '%s' in MULTI DELETE | TODO https://github.com/vitessio/vitess/blob/530ea87a538c4435f30b4cc443b2a318c77e2584/go/vt/vtgate/planbuilder/delete.go#L46 |
| 1056 | 42000 | group by expression cannot reference an aggregate function: '%s' | |
| 1149 | 42000 | aggregate functions take a single argument '%s' | |
| 1234 | 42000 | Incorrect usage/placement of 'SQL_CALC_FOUND_ROWS' | |
| 1234 | 42000 | Incorrect usage/placement of 'INTO' | |
| 1238 | HY000 | Variable '%s' is a read only variable | |
| 1105 | HY000 | column has duplicate set values: '%v' | Cannot assign multiple values to a column in an update statement |

