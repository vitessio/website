---
title: Overview
weight: 1
---

Vitess v17 introduced [`viper`][viper], a library to provide unified configuration management, to the project.

It acts as a registry for configuration values coming from a variety of sources, including:

- Default values.
- Configuration files (JSON, YAML, TOML, and other formats supported), including optionally watching and live-reloading.
- Environment variables.
- Command-line flags, primarily from `pflag.Flag` types.

It is used by a wide variety of Go projects, including [hugo][hugo] and [kops][kops].

[viper]: https://github.com/spf13/viper
[hugo]: https://github.com/gohugoio/hugo
[kops]: https://github.com/kubernetes/kops
