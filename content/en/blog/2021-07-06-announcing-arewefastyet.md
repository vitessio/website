---
author: 'Florent Poinsard, Manan Gupta'
date: 2021-07-06
slug: '2021-07-06-announcing-arewefastyet'
tags: ['Vitess','MySQL', 'benchmark', 'arewefastyet']
title: 'Announcing Arewefastyet - Nightly Benchmarks'
description: "Announcing Arewefastyet - Nightly Benchmarks Project"
---

Benchmarking is a critical technique for delivering high performance software.
The basic idea behind benchmarking is measuring and comparing the performance of a software version against another.
Over the years, many benchmarking techniques have emerged, but we can broadly separate them in two categories: micro and macro benchmarks.
Microbenchmarks measure a small part of the codebase, usually by isolating a single function call and calling it repeatedly, whereas macrobenchmarks measure the performance of the codebase as a whole and run in an environment similar to what end-users experience.
These two categories of benchmarks are analogous to unit tests and end-to-end tests.

Vitess is critical part of the infrastructure of many large companies.
As an example, this [blog post](https://slack.engineering/scaling-datastores-at-slack-with-vitess/) from Slack’s engineering team discusses how their Vitess deployment serves 2.3 million queries per second at peak.
Because of the impact that Vitess' performance has on ___ the Vitess team has a very serious and methodical commitment to performance.
We try really hard to make sure that every Vitess version is faster than the previous one.
To ensure that we meet this commitment we have created a benchmarking toolset named “arewefastyet”.

## How arewefastyet works

Executing a benchmark against Vitess is not trivial: benchmarks can be unreliable and hard to reproduce. Let us discuss how arewefastyet achieves accurate and reproducible benchmarks at scale.

At the core of arewefastyet lies the execution engine.
This engine is responsible for the entire lifespan of a benchmark run, which is the reason we call individual runs "execution".
An execution can be triggered from a variety of sources such as a manual trigger from the CLI, a cron schedule, or based on an event (new pull request, new release, etc).
Triggering an execution results in the creation of a new pipeline, which is configured using a YAML file provided by the trigger.
The YAML file contains the required configurations to run the entire benchmark, some of which define how to provision the benchmark’s infrastructure, store results, notify maintainers, and so on.

Each execution gets a dedicated server on which the benchmark is run.
For the production deployment of arewefastyet, all the hardware used is provided by [Equinix Metal](https://metal.equinix.com).
The default configuration uses [m2.xlarge.x86](https://metal.equinix.com/developers/docs/servers/server-specs/#m2xlargex86) servers; these are bare-metal servers which greatly increase the reliability and accuracy of our benchmarks.
The provisioning of an execution’s infrastructure is accomplished through the use of Terraform, which lets us manage the exact configuration of our servers in a reproducible manner.
Once a server is provisioned, several [Ansible roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html) are executed to apply dynamic configurations and settings on each instance based on the benchmark we intend to run.
Between two different benchmark runs, a server is likely going to be configured differently. For instance, a macro-benchmark needs to have a Vitess cluster created, whereas a micro-benchmark does not.
Configuring a server implies installing required packages and binaries, tweaking hard drive and network settings, building the Vitess and arewefastyet codebases, and lastly setting up and deploying a Vitess cluster.
The settings of the Vitess cluster are based on the configuration initially provided by the trigger. The default configuration measures Vitess' performance while using a sharded [keyspace](https://vitess.io/docs/concepts/keyspace/) with six [vtgates](https://vitess.io/docs/concepts/vtgate/) and two [vttablets](https://vitess.io/docs/concepts/tablet/).
Once an execution’s server is ready to be used, Ansible’s final task is to call arewefastyet’s CLI to start the actual benchmark run.

Vitess is mostly written in Golang, and the Go standard library ships with a comprehensive testing framework which includes a micro-benchmarking toolset.
Next to the numerous unit-test in Vitess' codebase, we can also find a multitude of micro-benchmarks implemented directly in Go.
These micro-benchmarks are executed using the default `go test` runner by [arewefastyet’s microbench command](https://github.com/vitessio/arewefastyet/blob/master/docs/arewefastyet_microbench_run.md).
The results of these micro-benchmarks contain critical performance metrics such as: the number of nanoseconds per iteration, number of bytes allocated, etc.
We parse and analyze these values, and then we store them in a MySQL database, so they can be displayed later on. 

Whilst micro-benchmarks are great to measure the performance of functional units in our codebase, we need macro-benchmarks to give us a better understanding of the overall performance of the system.
The setup of a macro-benchmark is, however, much more complicated since we want to reproduce an environment closer to what users will be running in their production deployments.
As mentioned earlier, we try to deploy a realistic configuration for our benchmark Vitess cluster, including: six vtgates, two vttablets, an [etcd](https://etcd.io) cluster, and a [vtctld](https://vitess.io/docs/concepts/vtctld/) server.
The actual benchmarking of a cluster is performed by a custom fork of [sysbench](https://github.com/planetscale/sysbench), a highly configurable lua-based tool that is designed to benchmark arbitrary data stores. We divide the execution of every macro-benchmark run into three steps: preparation, warm-up, and the actual run. The three steps are executed one by one by [arewefastyet’s macrobench command](https://github.com/vitessio/arewefastyet/blob/master/docs/arewefastyet_macrobench_run.md).
The preparation step is meant to create all the required data and files on the Vitess cluster.
The warm-up steps runs a small benchmark, which is then discarded.
The run step starts the sysbench benchmark against the Vitess cluster. 
Right now arewefastyet supports two different OLTP benchmarks, a simple one which we call "OTLP", and a more complex one named "TPC-C" which mimics a real world scenario where a wholesale supplier runs complex transactional queries.
Once a macro benchmark has run, we fetch the results generated by sysbench and store them in a MySQL database.
These results measure the latency, and the number of transactions and queries per second (TPS and QPS).

In addition to sysbench’s measurements, the system and Vitess metrics are also recorded.
During the configuration of the server, a Prometheus backend starts and becomes responsible for scrapping metrics out of the system and the Vitess cluster.
Once the benchmark has started metrics are funneled from our Prometheus backend to a centralized server where metrics are kept in an InfluxDB database.
Executions’ servers are meant to be ephemeral, they are destroyed when reaching the end of the benchmark, this motivated the use of a long-term and centralized server that stores our time series data.
Moreover, a Grafana frontend runs adjacent to the InfluxDB server and provides the maintainer team of Vitess with real-time dashboards on each execution.
The number of metrics we can visualize is large, although arewefastyet uses two metrics to build benchmark results, namely CPU time and memory consumption.
They give good confidence in Vitess’s resource usage.
The number of supported metrics is not limited and meant to grow in the future.

Once a benchmark is finished and its results are stored we can provide a feasible comparison between the same trigger’s previous execution and the current execution, this comparison is sent through a Slack channel.

Below is a diagram summarizing the execution process.

<img src="/files/blog-arewefastyet/execution-pipeline.png" width="auto" height="auto" alt="Execution Pipeline" />

## The Link With Vitess

In order to continuously benchmark Vitess, arewefastyet has a bunch of cron jobs setup that run daily at midnight (CEST).
The cron jobs take care of benchmarking: the main branch, the release branches, tags, and PRs with the `Benchmark Me` label of Vitess.
The results we get from these cron-triggered benchmarks are compared against previous benchmarks of the same type, this allows us to catch any performance regression as soon as possible.
We run the following comparisons: 
 
  - Main branch against the previous day results on main branch.
  - Main branch with the last release.
  - Release branch against the previous day results on release branch.
  - Release branch against the last patch release for that release.
  - Pull Request against the base of the head of the PR.

After these comparisons, if we find that any of the benchmarks have deteriorated by more than 10%, we send a Slack message to notify maintainers about the regression.
Furthermore, we benchmark the performance of both query planners Vitess has - the current defaults to the `v3` planner and the experimental, [under-work](https://github.com/vitessio/vitess/issues/7280), `Gen4` planner.
With this, we are able to track the performance boost that `Gen4` provides over the current `v3` planner.

## Website

All the results accumulated through the cron jobs are available to be seen and compared on the website [arewefastyet](https://benchmark.vitess.io/).
Within this section we describe the different pages available on the website. 

### [Microbenchmark Page](https://benchmark.vitess.io/microbench)
This page can be used to compare the results of all releases (after 7.0.0) on the microbenchmarks.
They can also be compared against the latest results on main.

<img src="/files/blog-arewefastyet/microbench.png" width="auto" height="auto" alt="Microbenchmark page" />

Clicking on any of the individual benchmarks opens up another page where we can see the results of that microbenchmark on the past few days.

<img src="/files/blog-arewefastyet/microbenchSingle.png" width="auto" height="auto" alt="Single Microbenchmark page" />

### [Macrobenchmark Page](https://benchmark.vitess.io/macrobench)
Like its microbenchmark counterpart, this page also compares the results of all releases (after 7.0.0) and main on OLTP and TPCC benchmarks.
We can also compare the results of Gen4 planner by using the toggle button in the menu bar (highlighted in the green box).

<img src="/files/blog-arewefastyet/macrobench.png" width="auto" height="auto" alt="Macrobenchmark page" />

### [V3 vs Gen4](https://benchmark.vitess.io/v3_VS_Gen4)
This page compares the performance of the `v3` planner and `Gen4` planner on all the releases after 10.0.0 in which it was introduced.

<img src="/files/blog-arewefastyet/v3VsGen4.png" width="auto" height="auto" alt="v3 VS Gen4 page" />

### [Search Page](https://benchmark.vitess.io/search)
This page can be used to check the results for a specific commit, if no results exist for this commit then a warning will be rendered.
The functionality of the `Gen4` switch button remains the same.

<img src="/files/blog-arewefastyet/search.png" width="auto" height="auto" alt="Search page" />

### [Compare](https://benchmark.vitess.io/compare)
This page is similar to the search page except that it compares the results of two commits. 

<img src="/files/blog-arewefastyet/compare.png" width="auto" height="auto" alt="Compare page" />

## Summary

In all, arewefastyet is a tool provided to both the users and developers to quickly compare the results of the different releases of Vitess.
It makes it easier for the users to migrate to a higher release and have confidence in the expected performance impact.
It enables the maintainers of Vitess to track performance regressions early on and fix them as soon as possible.

