---
title: "Error: mysqld not found in any of /usr/bin/{sbin,bin,libexec}"
shorten_nav_links: true
notoc: true
weight: 5
---

If you're all set up with Vitess but mysqld won't start, with an error like this:

```sh
E0430 17:02:43.663441    5297 mysqlctl.go:254] failed start mysql: mysqld not found in any of /usr/bin/{sbin,bin,libexec}
```

You will need to perform the following steps:

- Verify that mysqld is located in /usr/bin on all its hosts 
- Verify that PATH has been set and sourced in .bashrc 

If you have confirmed the above and are still getting the error referenced, it is likely that `VT_MYSQL_ROOT` has not been set correctly. 

On most systems `VT_MYSQL_ROOT` should be set to `/usr`  because Vitess expects to find a bin directory below that.
