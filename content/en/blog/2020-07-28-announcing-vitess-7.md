---
author: 'Deepthi Sigireddi'
date: 2020-07-28T08:00:00-08:00
slug: '2020-07-28-announcing-vitess-7'
tags: ['Guides']
title: 'Announcing Vitess 7'
---

On behalf of the Vitess maintainers team, I am pleased to announce general availability of [Vitess 7.0]

Here are some highlights:

### Improved SQL Support
Vitess now understands much more of MySQL’s syntax. We have taken the approach of studying the queries issued by common applications and frameworks, and baking them right into the end-to-end test suite.

Common issues such as `SHOW` commands not returning correct results or MySQL’s `SQL_CALC_FOUND_ROWS` feature have now been fixed. In Vitess 7, we plan to add support for setting session variables, which will address one of the largest outstanding compatibility issues.

We encourage you to spend a moment reading the [release notes](https://github.com/vitessio/vitess/releases/tag/v6.0.20-20200429).

Please download Vitess 7, and take it for a spin!
