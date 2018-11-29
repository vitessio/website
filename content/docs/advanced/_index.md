---
title: Advanced Features
weight: 6
---

The pages in this Advanced Features section can be understood as a complement to the [User Guides](../user-guides) section of the docs. Here, we describe advanced Vitess features that you may want to enable or tune in a production setup.

As of {{< month-and-year >}}, some of these features are not yet documented. We plan to add documentation for them later.

Examples for undocumented features:

* Hot row protection in vttablet
* vtgate buffer for lossless failovers
* vttablet consolidator (avoids duplicated read queries to MySQL, turned on by default)
* [vtexplain](https://github.com/vitessio/vitess/blob/master/doc/VtExplain.md)
