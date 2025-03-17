---
title: "Error: Could not open required defaults file: /path/to/my.cnf"
shorten_nav_links: true
notoc: true
weight: 4
---

If you cannot start a cluster and see that error in the logs it most likely means that AppArmor is running on your server and is preventing Vitess processes from accessing the my.cnf file. 

The workaround is to uninstall AppArmor:

```sh
sudo service apparmor stop
sudo service apparmor teardown
sudo update-rc.d -f apparmor remove
```

You may also need to reboot the machine after this. Many programs automatically install AppArmor, so you may need to uninstall again.
