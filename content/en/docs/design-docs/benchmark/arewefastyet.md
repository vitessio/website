---
title: arewefastyet
description: Nightly Benchmarking project for Vitess
weight: 1
---

## Background

With the codebase of Vitess becoming larger and complex changes getting merged, we need to ensure our changes are not degrading the performance of Vitess.

## Benchmarking Tool

To solve the aforementioned issue, we use a tool named arewefastyet that automatically tests the performance of Vitess. The performance are measured through a set of benchmarks divided into two categories: `micro` and `macro`, the former focuses on unit-level functions, and the latter targets system-wide performance changes. Those benchmarks are run every night if there are new commits, release or pull request needing benchmarks.   

The GitHub repository where lies all of arewefastyet's code can be found on [vitessio/arewefastyet](https://github.com/vitessio/arewefastyet).

### Pull Request needing benchmarks

When a pull request affect the performance of Vitess, one might wish to benchmark it before merging it. The latter can be done by setting the `Benchmark me` label to your pull request. Each night, at midnight central european time, the head commit of your pull request will be benchmarked and compared against the pull request's base.

## Website

The performances of Vitess can be observed throughout different releases, git SHAs, and nightly builds on arewefastyet's website at [https://benchmark.vitess.io](https://benchmark.vitess.io).

The website lets us:

* See previous nightly benchmarks.
* Search results for a specific git SHA.
* Compare two results for two git SHAs.
* See micro and macro benchmarks results throughout different releases.
* Compare performance between VTGate's v3 planner and Gen4 planner.
