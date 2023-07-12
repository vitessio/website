---
title: Gen4 and V3 Compatibility
weight: 2
aliases: ['/docs/reference/gen4-against-v3/', '/docs/reference/gen4-and-v3-compatibility/']
---

The latest version of the Vitess query planner, `Gen4`, changes most of the planner's internals.
To ensure `Gen4` produces plans that, once executed, give us the same results as what `V3` would do, we have developed
a small test tool that runs queries using both `Gen4` and `V3` planners and compare their results. If the results we got are different
from the two planners, the query will fail and the difference will be printed in VTGate's logs as a warning.

This tool is enabled by the use of a new planner: `Gen4CompareV3`, to use it, we must start VTGate with the `--planner-version`
flag set to `Gen4CompareV3`. Once set, new queries will be tested against both `Gen4` and `V3`.
