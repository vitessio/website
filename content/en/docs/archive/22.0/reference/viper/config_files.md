---
title: Config Files
weight: 4
slug: 'config-files'
---

`viperutil` provides a few flags that allow binaries to read values from config files in addition to defaults, environment variables and flags.
They are:

- `--config-path`
    - Default: `$(pwd)`
    - EnvVar: `VT_CONFIG_PATH` (parsed exactly like a `$PATH` style shell variable).
    - FlagType: `StringSlice`
    - Behavior: Paths for `ReadInConfig` to search.
- `--config-type`
    - Default: `""`
    - EnvVar: `VT_CONFIG_TYPE`
    - FlagType: `flagutil.StringEnum`
        - Values: everything contained in `viper.SupportedExts`, case-insensitive.
    - Behavior: Force viper to use a particular unmarshalling strategy; required if the config file does not have an extension (by default, viper infers the config type from the file extension).
- `--config-name`
    - Default: `"vtconfig"`
    - EnvVar: `VT_CONFIG_NAME`
    - FlagType: `string`
    - Behavior: Instructs `ReadInConfig` to only look in `ConfigPaths` for files named with this name (with any supported extension, unless `ConfigType` is also set, in which case only with that extension).
- `--config-file`
    - Default: `""`
    - EnvVar: `VT_CONFIG_FILE`
    - FlagType: `string`
    - Behavior: Instructs `ReadInConfig` to search in `ConfigPaths` for explicitly a file with this name. Takes precedence over `ConfigName`.
- `--config-file-not-found-handling`
    - Default: `WarnOnConfigFileNotFound`
    - EnvVar: (none)
    - FlagType: `string` (options: `IgnoreConfigFileNotFound`, `WarnOnConfigFileNotFound`, `ErrorOnConfigFileNotFound`, `ExitOnConfigFileNotFound`)
    - Behavior: If viper is unable to locate a config file (based on the other flags here), then `LoadConfig` will:
        - `Ignore` => do nothing, return no error. Program values will come entirely from defaults, environment variables and flags.
        - `Warn` => log at the WARNING level, but return no error.
        - `Error` => log at the ERROR level and return the error back to the caller (usually `servenv`.)
        - `Exit` => log at the FATAL level, exiting immediately.
- `--config-persistence-min-interval`
    - Default: `1s`
    - EnvVar: `VT_CONFIG_PERSISTENCE_MIN_INTERVAL`
    - FlagType: `time.Duration`
    - Behavior: If viper is watching a config file, in order to synchronize between changes to the file, and changes made in-memory to dynamic values (for example, via vtgate's `/debug/env` endpoint), it will periodically write in-memory changes back to disk, waiting _at least_ this long between writes.
    If the value is 0, each in-memory `Set` is immediately followed by a write to disk.

For more information on how viper searches for config files, see the [documentation][viper_read_in_config_docs].

If viper was able to locate and load a config file, `LoadConfig` will then configure the dynamic registry to set up a watch on that file, enabling all dynamic values to pick up changes to that file for the remainder of the program's execution.
If no config file was used, then dynamic values behave exactly like static values (i.e. the dynamic registry copies in the settings loaded into the static registry, but does not set up a file watch).

## Re-persistence for Dynamic Values

Prior to the introduction of viper in Vitess, certain components (such as `vttablet` or `vtgate`) exposed `/debug/env` HTTP endpoints that permitted the user to modify certain configuration parameters at runtime.

This behavior is still supported, and to maintain consistency between update mechanisms, if:
- A config file was loaded at startup
- A value is configured with the `Dynamic: true` option

then in-memory updates to that value (via `.Set()`) will be written back to disk.
If we skipped this step, then the next time viper reloaded the disk config, the in-memory change would be undone, since viper does a full load rather than something more differential.
Unfortunately, this seems unavoidable.

To migitate against potentially writing to disk "too often" for a given user, the `--config-persistence-min-interval` flag defines the _minimum_ time to wait between writes.
Internally, the system is notified to write "soon" only when a dynamic value is updated.
If the wait period has elapsed between changes, a write happens immediately; otherwise, the system waits out the remainder of the period and persists any changes that happened while it was waiting.
Setting this interval to zero means that writes happen immediately.

[viper_read_in_config_docs]: https://github.com/spf13/viper#reading-config-files
