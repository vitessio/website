---
title: "Collecting information for troubleshooting"
shorten_nav_links: true
notoc: true
weight: 2
---

In order to troubleshoot issues occurring in your implementation of Vitess you will need to provide the community as much context as possible.

When you reach out you should include, if possible, a summary/overview deployment document of what components are involved and how they interconnect, etc. Customers often maintain something like this for internal support purposes.

Beyond the overview deployment document, we recommend that for the best experience, you collect as many of the items listed below as possible from production Vitess systems:

- Logs (vtgate, vttablet, underlying MySQL)
- Metrics (vtgate, vttablet, underlying MySQL)
- Other statistics (MySQL processlist, MySQL InnoDB engine status, etc.)
- Application DB pool configurations
- Load balancer configurations (if in the MySQL connection path)
- Historical load patterns
