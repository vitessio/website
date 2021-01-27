---
title: Set Statements
description:
weight: 1
---

## Use Case
There are multiple applications/frameworks that tweak session system variables at the start of the connection to configure the system in specific ways. Some do it for all connections it uses, and some do it only for specific workloads, such as import, installation, etc.

To support these use cases, Vitess needs to allow SET statements to be set on a per-connection basis.

The recommendation is to change the setting at a global level during Vitess tablet setup. When this is done, sessions can use the normal connection pools, which is the most efficient way to operate. However, this design allows for sessions with VTgate changing these system variables and Vitess will make sure that they are set for all connections with MySQL for that session.

## System variable types
Vitess internally classifies system variables into three types - Ignore, Reserve, and Vitess-aware.

### Ignore modification
These are the system variables for which Vitess validates the current setting and notify users via warning that settings are either ignored or modification was not allowed. E.g. default_storage_engine, debug, etc.

### Vitess Aware
These are the system variables for which Vitess needs to change behavior based on the settings. E.g. autocommit, client_found_rows, etc.

### Reserve connection
These are the system variables that Vitess will send down to the storage engine and modify the settings at the session connection level. E.g. sql_mode, sql_safe_updates, etc.

This document contains the design for this type of system variables.

## Design
### VTTablet
Reserve Pool
VTTablet will have a new pool named reserved pool. Connections in the reserved pool are tied to a specific session and are closed when the session is closed.

QueryService interface changes:

* ReserveExecute: Reserve a connection, execute the set statements, and the query.
* ReserveBeginExecute: Reserve a connection, execute the set statements, move the reserve connection to active transaction pool and execute begin and the query.
* ReserveRelease: This closes the reserved connection and also rollback the transaction if it is in an open state.
* BeginExecute: ReserveId will be added as a parameter to the request.
* Execute: ReserveId will be added as a parameter to the request.

Connections that have updated session system variables will at the end of a transaction (Commit/Rollback) be moved to the reserve pool - they can’t be reused by other sessions.

### VTGate
When a session issues a SET statement to change a system variable, VTGate will compare the provided value with the already configured value. If it differs, it is stored in the session.

A connection with the vttablet is reserved when a query is sent from the client connection. The stored settings are applied first to the reserved connection and then the query is executed.
Storing the changed setting in the session enables VTGate to apply settings to any new connection that is opened with different shards.

State | Reserved | Transaction | Recorded SETs
| -- | -- | -- | -- |
|clear | F | F | F |
|remember-sets | F | F | T |
|reserved | T | F | T |
|inTx | F | T | F |
|reserved-inTx | T | T | T |

From State | Query | Vtgate Action | API on tablet | To State
| -- | -- | -- | -- | -- |
| clear | SET system var | Record statement | No call | remember-sets |
| remember-sets | SET system var | Record statement | No call | remember-sets |
| reserved | SET system var | Record statement | Execute | reserved |
| inTx | SET system var | Record statement | ReserveExecute | reserved-inTx |
| reserved-inTx | SET system var | Record statement | Execute | reserved-inTx |
| remember-sets | Query |   | ReserveExecute | reserved |
| reserved | Query |   | Execute | reserved |
| reserved-inTx | Query |   | Execute | reserved-inTx |
| remember-sets | Begin + Query |   | ReserveBeginExecute | reserved-inTx |
| reserved | Begin + Query |   | BeginExecute | reserved-inTx |
| remember-sets | Commit/Rollback | No-op | No call | remember-sets |
| reserved | Commit/Rollback | No-op | No call | reserved |
| reserved-inTx | Commit/Rollback |   | Commit/Rollback | reserved |
| remember-sets | Close Connection | Close Session | No call | clear |
| reserved | Close Connection | Close Session | ReserveRelease | clear |
| reserved-inTx | Close Connection | Close Session | ReserveRelease | clear |

## Release Plan
The release plan would be to update vttablet < vtctl < vtgate in this particular order.

## Assumption
The order of the SET statements is not maintained. Different Vitess shards might see settings being applied in any order.
