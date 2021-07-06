---
author: 'Florent Poinsard, Manan Gupta'
date: 2021-07-06
slug: '2021-07-06-announcing-arewefastyet'
tags: ['Vitess','MySQL', 'benchmark', 'arewefastyet']
title: 'Announcing Arewefastyet - Nightly Benchmarks'
description: "Announcing Arewefastyet - Nightly Benchmarks Project"
---

In a world where end-to-end performance is becoming a critical metric for both users and businesses, our techniques have become more advanced allowing us to deliver fast and optimized software products that meet the market expectations. To reach such expectations benchmarking comes in. Benchmarking lets us measure and compare the performance of a software version against another. Developed and used for a very long time, a lot of techniques have emerged and we can draw a line to define two categories, namely: micro and macro benchmarks. The former, benchmarks a small part of the codebase, usually at the method or functionality level. Whereas the latter measures the performance of the whole codebase and uses an environment similar to what end-users will experience. These two categories are analogous to unit tests and end-to-end tests.

Vitess’s performance is critical to its users, from a [blog post](https://slack.engineering/scaling-datastores-at-slack-with-vitess/) written by Slack’s engineering team, Vitess serves 2.3 million QPS at peak, it is thus fundamental for us to ensure we ship code that has high performance. For that reason, we have created a toolset named “arewefastyet”.

## How arewefastyet works

Executing a benchmark against Vitess is not benign, benchmarks can be unreliable and hard to reproduce, this section introduces how arewefastyet achieves it.

At the core of arewefastyet lies the execution engine. This engine is responsible for the entire lifespan of a benchmark, or as we call it: an execution. An execution can be triggered from a variety of sources such as a manual trigger from the CLI, a cron schedule, or based on an event (new pull request, new release, …). Triggering an execution results in the creation of a new pipeline, which is thoroughly configured using a YAML file provided by the trigger. The YAML file contains the required configurations to run the entire benchmark, some of which define how to provision the benchmark’s infrastructure, store results, notify maintainers, and so on.

Each execution gets a dedicated server on which the benchmark can be run. The hardware used is provided by [Equinix Metal](https://metal.equinix.com), a cloud provider on which all the benchmarks we execute rely. The default configuration uses the [m2.xlarge.x86](https://metal.equinix.com/developers/docs/servers/server-specs/#m2xlargex86) servers. These servers are bare-metal servers thus increasing our reliability and confidence. The provision of an execution’s infrastructure is accomplished through the use of Terraform that lets us manage our infrastructure in a reproducible manner. Once a server is provisioned several [Ansible roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) are executed to apply dynamic configurations and settings on the server based on the upcoming benchmark. Between two benchmarks a server is likely going to be configured differently, for instance, a macro-benchmark needs to have a Vitess cluster created whereas a micro-benchmark does not. Configuring a server implies installing required packages and binaries, tweaking hard drive and network settings, building Vitess and arewefastyet codebases, setting up a Vitess cluster. The setup of the Vitess cluster is based on the configuration initially provided by the trigger. The default configuration benchmarks Vitess using a sharded [keyspace](https://vitess.io/docs/concepts/keyspace/) with six [vtgates](https://vitess.io/docs/concepts/vtgate/) and two [vttablets](https://vitess.io/docs/concepts/tablet/). Once an execution’s server is ready to be used, Ansible’s ultimate task is to call arewefastyet’s CLI to start benchmarking Vitess.

Vitess is coded in Golang, a programming language that is shipped with its standard testing library, luckily this library encapsulates a micro benchmarking toolset. Vitess’s codebase has numerous tests, right next to them lies a multitude of micro-benchmarking tests. These micro-benchmarking tests are executed, using `go test -bench`, by [arewefastyet’s microbench command](https://github.com/vitessio/arewefastyet/blob/master/docs/arewefastyet_microbench_run.md), their results are then parsed and analyzed before being stored in a MySQL database. The results we get from go’s standard library measure how well each function is performing using a few metrics such as the number of nanoseconds per iteration, number of bytes used per iteration. 

Where micro-benchmarks are great to measure unit-level performance, macro-benchmarks give us a better understanding of the overall performance, however, their setup is more complicated since we want to reproduce something close to what users will be experiencing. As mentioned earlier, during the configuration phase, we instantiate a new Vitess cluster that contains six vtgates, two vttablets, an [etcd](https://etcd.io) cluster, and a [vtctld](https://vitess.io/docs/concepts/vtctld/) server. The tool [sysbench](https://github.com/planetscale/sysbench), a tool that enables multi-threaded database benchmarks, is at the core of our macro benchmarks, we divide its execution into three steps: preparation, warm-up, run, the three of which are executed one by one by [arewefastyet’s macrobench command](https://github.com/vitessio/arewefastyet/blob/master/docs/arewefastyet_macrobench_run.md). The preparation and warm-up steps are meant to create all the required data and files, as well as running a small benchmark to get the system warmed up. The run step starts the sysbench benchmark against the Vitess cluster using the configuration the user provides. Arewefastyet supports two types of macro benchmarks: OLTP and TPC-C, the former benchmarks Vitess using transactional queries, while the latter is a benchmark that portrays the scenario of a wholesale supplier using OLTP-based queries. Each execution of macro-benchmark will use one of these two types. Once the macro benchmark has run, we fetch the results generated by sysbench and store them in a MySQL database. The results we get from sysbench measure the latency, and the number of transactions and queries per second (TPS and QPS).

In addition to sysbench’s measurements, the system and Vitess metrics are also recorded. During the configuration of the server, a Prometheus backend starts and becomes responsible for scrapping metrics out of the system and the Vitess cluster. Once the benchmark has started metrics are funneled from our Prometheus backend to a centralized server where metrics are kept in an InfluxDB database. Executions’ servers are meant to be ephemeral, they are destroyed when reaching the end of the benchmark, this motivated the use of a long-term and centralized server that stores our time series data. Moreover, a Grafana frontend runs adjacent to the InfluxDB server and provides the maintainer team of Vitess with real-time dashboards on each execution. The number of metrics we can visualize is large, although arewefastyet uses two metrics to build benchmark results, namely CPU time and memory consumption. They give good confidence in Vitess’s resource usage. The number of supported metrics is not limited and meant to grow in the future.

Once a benchmark is finished and its results are stored we can provide a feasible comparison between the same trigger’s previous execution and the current execution, this comparison is sent through a Slack channel.
Below is a diagram of the whole execution process.

<img src="/files/blog-arewefastyet/execution-pipeline.png" width="auto" height="auto" alt="Execution Pipeline" />

## The Link With Vitess

In order to continuously benchmark Vitess, arewefastyet has a bunch of cron jobs setup that run daily at midnight (CEST). The cron jobs take care of benchmarking: the main branch, the release branches, tags, and PRs with the `Benchmark Me` label of Vitess. The results we get from these cron-triggered benchmarks are compared against previous benchmarks of the same type, this allows us to catch any performance regression as soon as possible. We run the following comparisons: 
 
  - Main branch against the previous day results on main branch.
  - Main branch with the last release.
  - Release branch against the previous day results on release branch.
  - Release branch against the last patch release for that release.
  - Pull Request against the base of the head of the PR.

After these comparisons, if we find that any of the benchmarks have deteriorated by more than 10%, we send a Slack message to notify maintainers about the regression.
Furthermore, we benchmark the performance of both query planners Vitess has - the current defaults to the `v3` planner and the experimental, [under-work](https://github.com/vitessio/vitess/issues/7280), `Gen4` planner. With this, we are able to track the performance boost that `Gen4` provides over the current `v3` planner.

## Website

All the results accumulated through the cron jobs are available to be seen and compared on the website [arewefastyet](https://benchmark.vitess.io/). Within this section we describe the different pages available on the website. 

### [Microbenchmark Page](https://benchmark.vitess.io/microbench)
This page can be used to compare the results of all releases (after 7.0.0) on the microbenchmarks. They can also be compared against the latest results on main.

<img src="/files/blog-arewefastyet/microbench.png" width="auto" height="auto" alt="Microbenchmark page" />

Clicking on any of the individual benchmarks opens up another page where we can see the results of that microbenchmark on the past few days.

<img src="/files/blog-arewefastyet/microbenchSingle.png" width="auto" height="auto" alt="Single Microbenchmark page" />

### [Macrobenchmark Page](https://benchmark.vitess.io/macrobench)
Like its microbenchmark counterpart, this page also compares the results of all releases (after 7.0.0) and main on OLTP and TPCC benchmarks. We can also compare the results of Gen4 planner by using the toggle button in the menu bar (highlighted in the green box).

<img src="/files/blog-arewefastyet/macrobench.png" width="auto" height="auto" alt="Macrobenchmark page" />

### [V3 vs Gen4](https://benchmark.vitess.io/v3_VS_Gen4)
This page compares the performance of the v3 planner and Gen4 planner on all the releases after 10.0.0 in which it was introduced

<img src="/files/blog-arewefastyet/v3VsGen4.png" width="auto" height="auto" alt="v3 VS Gen4 page" />

### [Search Page](https://benchmark.vitess.io/search)
This page can be used to check the results for a specific sha commit if they exist for the micro and macro benchmarks. The functionality of the Gen4 switch button remains the same.

<img src="/files/blog-arewefastyet/search.png" width="auto" height="auto" alt="Search page" />

### [Compare](https://benchmark.vitess.io/compare)
This page is similar to the search page except that it compares the results of 2 SHAs provided on all the benchmarks, both micro and macro. 

<img src="/files/blog-arewefastyet/compare.png" width="auto" height="auto" alt="Compare page" />

## Summary

In all, arewefastyet is a tool provided to both the users and developers to quickly compare the results of the different releases of Vitess. It makes it easier for the users to migrate to a higher release and have confidence in the expected performance impact. It enables the maintainers of Vitess to track performance regressions early on and fix them as soon as possible.

