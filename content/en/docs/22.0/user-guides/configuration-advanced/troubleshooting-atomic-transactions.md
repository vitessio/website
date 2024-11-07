---
title: Troubleshooting Distributed Atomic Transactions
weight: 65
---

For users running sharded keyspaces in Vitess, we support atomic transactions across multiple shards using 2PC (Two-Phase Commit). More details on how to configure your cluster to allow distributed transactions can be found in the [Distributed Transaction](../../../reference/features/distributed-transaction/) documentation.

While we don't expect any problems, it is possible that you may encounter issues when running distributed transactions. This guide will help you troubleshoot and resolve these issues.

## Finding Issues

There are a couple of ways to know whether something has gone wrong in distributed transactions - 

1. **Metrics provided by `vttablet`s** - The `vttablet` process exposes a number of metrics that can be used to monitor the health of the system. Here are the ones to look out for -
   1. `CommitPreparedFail` - This metric shows the number of times a commit has failed after it was already prepared. It is further sub-divided into 2 class of errors. One retryable, and the other not. Any non-retryable error will require human intervention.
   2. `RedoPreparedFail` - Similar to the previous metric, it shows the number of times a redoing a transaction has failed after it was already prepared. Any non-retryable error here too will require human intervention.
2. **`GetUnresolvedTransactions` RPC** - This command shows the list of unresolved transactions in the system. The state of these transactions can be checked to see if they are stuck in a failed state or not. More details on the command can be found [here](//TODO: add link).
3. **Transactions page in VTAdmin** - The VTAdmin UI provides a page to view all the unresolved transactions in the system. It works using the RPC same command as the previous one.

## Fixing The Issue

Once we have found a transaction that is permanently failed, we need human intervention to fix the database state. Here are the steps to follow -
1. Get more information about the transaction using the dtid of the transaction. This can be done by running the `GetTransactionInfo` RPC command. More information about the command can be found [here](//TODO: add link).
2. The output of the command will contain the list of participating shards in the transaction. For each shard, it will have the status of the transaction on that shard. For the shards where the transaction has failed, it will have the writes that were part of the transaction.
3. With this information, you can rerun the writes on all the failing shards.
4. Once all the changes are made, the transaction can be concluded by running the `ConcludeTransaction` RPC command. More information about the command can be found [here](//TODO: add link).

The same information can be gleaned from VTAdmin page by navigating to the transactions page, and clicking on the transaction in question.

We would also request you to open an issue on Vitess, so that the underlying problem can be investigated and fixed.
