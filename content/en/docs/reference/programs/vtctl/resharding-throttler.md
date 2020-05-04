---
title: vtctl Resharding Throttler Command Reference
series: vtctl
---

The following `vtctl` commands are available for administering Resharding Throttler.

## Commands

### ThrottlerMaxRates
 `ThrottlerMaxRates  -server <vtworker or vttablet>`

### ThrottlerSetMaxRate
 `ThrottlerSetMaxRate  -server <vtworker or vttablet> <rate>`

### GetThrottlerConfiguration
 `GetThrottlerConfiguration  -server <vtworker or vttablet> [<throttler name>]`

### UpdateThrottlerConfiguration
 `UpdateThrottlerConfiguration  -server <vtworker or vttablet> [-copy_zero_values] "<configuration protobuf text>" [<throttler name>]`

### ResetThrottlerConfiguration
 `ResetThrottlerConfiguration  -server <vtworker or vttablet> [<throttler name>]`




## See Also

* [vtctl command index](../../vtctl)
