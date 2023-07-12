---
title: Dynamic Values
weight: 3
slug: 'dynamic-values'
---

Values can be configured to be either static or dynamic.
Static values are loaded once at startup (more precisely, when `viperutil.LoadConfig` is called), and whatever value is loaded at the point will be the result of calling `Get` on that value for the remainder of the process's lifetime.
Dynamic values, conversely, may respond to config changes.

In order for dynamic configs to be truly dynamic, `LoadConfig` must have found a config file (as opposed to pulling values entirely from defaults, flags, and environment variables).
If this is the case, a second viper shim, which backs the dynamic registry, will start a watch on that file, and any changes to that file will be reflected in the `Get` methods of any values configured with `Dynamic: true`.

**An important caveat** is that viper on its own is not threadsafe, meaning that if a config reload is being processed while a value is being accessed, a race condition can occur.
To protect against this, the dynamic registry uses a second shim, [`sync.Viper`](https://github.com/vitessio/vitess/blob/main/go/viperutil/internal/sync/sync.go).
This works by assigning each dynamic value its own `sync.RWMutex`, and locking it for writes whenever a config change is detected. Value `GetFunc`s are then adapted to wrap the underlying get in a `m.RLock(); defer m.RUnlock()` layer.
This means that there's a potential throughput impact of using dynamic values, which module authors should be aware of when deciding to make a given value dynamic.
