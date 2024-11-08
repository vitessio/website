---
title: Troubleshooting Distributed Atomic Transactions
weight: 65
---

For users running sharded keyspaces in Vitess, we support atomic transactions across multiple shards using 2PC (Two-Phase Commit). You can find more details on configuring your cluster for distributed transactions in the [Distributed Transaction](../../../reference/features/distributed-transaction/) documentation.

Although distributed transactions are designed to run smoothly, issues may occasionally occur. This guide will help you troubleshoot and resolve these issues.

## Finding Issues

There are several methods to determine whether something has gone wrong in distributed transactions: 

1. **Monitor `vttablet` metrics** - The `vttablet` process exposes various metrics that can be used to monitor the health of the system. Here are the ones to look out for -
   1. `CommitPreparedFail` - This metric indicates the number of times a commit has failed after being prepared. It is categorized into two classes of errors: retryable and non-retryable. Non-retryable errors will require human intervention.
   2. `RedoPreparedFail` - Similar to `CommitPreparedFail`, this metric shows the number of times redoing a transaction has failed after preparation. Non-retryable errors here will also need human intervention.
2. **`GetUnresolvedTransactions` RPC** - This command lists unresolved transactions in the system. You can check the state of these transactions to determine if any are stuck in a failed state. More details on the command can be found [here](../../../reference/programs/vtctldclient/vtctldclient_distributedtransaction/vtctldclient_distributedtransaction_unresolved-list).
3. **Transactions page in VTAdmin** - The VTAdmin UI provides a page to view all unresolved transactions in the system. It uses the same RPC command as mentioned above.

## Fixing The Issue

Once a transaction has been identified as irreversibly failed, human intervention is required to correct the database state. Follow these steps:
1. Query the `redo_state` and `redo_statement` tables on all participating shards using the dtid to get more information about the transaction.
2. Each shard will display the status of the transaction on that shard. For shards where the transaction has failed, the information will include the writes that were part of the transaction.
3. Using this information, rerun the writes on all the failing shards.
4. After making the necessary changes, conclude the transaction by running the `ConcludeTransaction` RPC command. More details about this command can be found [here](../../../reference/programs/vtctldclient/vtctldclient_distributedtransaction/vtctldclient_distributedtransaction_conclude).

Please open an issue on the Vitess GitHub repository to allow further investigation and resolution of the problem.
