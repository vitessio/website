---
title: start
series: zkctl
---
## zkctl start

Runs an already initialized zookeeper server.

```
zkctl start [flags]
```

### Options

```
  -h, --help   help for start
```

### Options inherited from parent commands

```
      --config-file string                                          Full path of the config file (with extension) to use. If set, --config-path, --config-type, and --config-name are ignored.
      --config-file-not-found-handling ConfigFileNotFoundHandling   Behavior when a config file is not found. (Options: error, exit, ignore, warn) (default warn)
      --config-name string                                          Name of the config file (without extension) to search for. (default "vtconfig")
      --config-path strings                                         Paths to search for config files in. (default [<WORKDIR>])
      --config-persistence-min-interval duration                    minimum interval between persisting dynamic config changes back to disk (if no change has occurred, nothing is done). (default 1s)
      --config-type string                                          Config file type (omit to infer config type from file extension).
      --keep-logs duration                                          keep logs for this long (using ctime) (zero to keep forever)
      --keep-logs-by-mtime duration                                 keep logs for this long (using mtime) (zero to keep forever)
      --log-err-stacks                                              log stack traces for errors
      --log-format string                                           log output format: json for machine-readable JSON, text for human-readable colored output (default "json")
      --log-level string                                            minimum log level when structured logging is enabled (debug, info, warn, error) (default "info")
      --log-rotate-max-size uint                                    size in bytes at which logs are rotated (glog.MaxSize) (default 1887436800)
      --log-structured                                              enable structured JSON logging (default true)
      --pprof strings                                               enable profiling
      --pprof-http                                                  enable pprof http endpoints
      --purge-logs-interval duration                                how often try to remove old logs (default 1h0m0s)
  -v, --version                                                     print binary version
      --zk.cfg string                                               zkid@server1:leaderPort1:electionPort1:clientPort1,...) (default "6@<hostname>:3801:3802:3803")
      --zk.extra stringArray                                        extra config line(s) to append verbatim to config (flag can be specified more than once)
      --zk.myid uint                                                which server do you want to be? only needed when running multiple instance on one box, otherwise myid is implied by hostname
```

### SEE ALSO

* [zkctl](../)	 - Initializes and controls zookeeper with Vitess-specific configuration.

