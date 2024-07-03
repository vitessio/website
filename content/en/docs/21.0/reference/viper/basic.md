---
title: Framework Basics
weight: 2
---

In order to integrate smoothly with existing Vitess configuration mechanisms (including flags, `vttablet`'s YAML-based configuration, `/debug/env` endpoints, etc) we have introduced a thin framework on top of viper, which:

- Requires values to be `Configure`d.
- Separates static values (which do not change at runtime even if the config-file they were loaded from is updated) from dynamic values.

## `Configure` Options

In order to properly configure a value for use, `Configure` needs to know, broadly speaking, three things:

1. The key name being bound.
1. What "things" it should be bound to (i.e. other keys via aliases, environment variables, and flag names), as well as if it has a default value.
1. How to `Get` it out of a viper.

`Configure`, therefore, has the following signature:

```go
func Configure[T any](key string, options Options[T]) Value[T]
```

The first parameter provides the key name (point 1 of our above list); all other information is provided via various `Options` fields, which looks like:

```go
type Options[T any] struct {
    // what "things" to bind to
    Aliases []string
    FlagName string
    EnvVars []string

    // default, if any
    Default T

    // whether it can reload or not (more on this later)
    Dynamic bool

    // how to "get" it from a viper (more on this slightly less later)
    GetFunc func(v *viper.Viper) func(key string) T
}
```

## `Get` funcs

In most cases, module authors will not need to specify a `GetFunc` option, since, if not provided, `viperutil` will do its best to provide a sensible default for the given type `T`.

This requires a fair amount of `reflect`ion code, which we won't go into here, and unfortunately cannot support even all primitive types (notably, array (not slice!!) types).
In these cases, the `GetFuncForType` will panic, allowing the module author to catch this during testing of their package.
They may then provide their own `GetFunc`.

The full suite of types, both supported and panic-inducing, are documented by way of unit tests in [`go/viperutil/get_func_test.go`](https://github.com/vitessio/vitess/blob/main/go/viperutil/get_func_test.go).

## Debug Endpoint

Any component that parses its flags via one of `servenv`'s parsing methods will get an HTTP endpoint registered at `/debug/config` which displays the full viper configuration for debugging purposes.
It accepts a query parameter to control the format; anything in `viper.SupportedExts` is permitted.

## Caveats and Gotchas

- Config keys are case-insensitive.
`Foo`, `foo`, `fOo`, and `FOO` will all have the same value.
    - **Except** for environment variables, which, when read, are case-sensitive (but the config key they are _bound to_ remains case-insensitive).
      For example, if you have `viper.BindEnv("foo", "VT_FOO")`, then `VT_FOO=1 ./myprogram` will set the value to `1`, but `Vt_FoO=1 ./myprogram will not`.
      The value, though, can still be read _from_ viper as `Foo`, `foo`, `FOO`, and so on.

- The `Unmarshal*` functions rely on `mapstructure` tags, not `json|yaml|...` tags.

- Any config files/paths added _after_ calling `WatchConfig` will not get picked up by that viper, and a viper can only watch a single config file.