---
title: "What does it mean if a VTTablet is unhappy?"
shorten_nav_links: true
notoc: true
weight: 2
---

An unhappy VTTablet is one whose replication is lagging beyond the limit to which the `--degraded_threshold` is set. An unhappy VTTablet could still be serving queries. 

VTGate will always prefer happy VTTablets over unhappy VTTablets, however if all your VTTablets are unhappy then it will serve all of them.
