---
title: Contribute
description: Get involved with Vitess development
weight: 6
---

You want to contribute to Vitess? That's awesome!

In the past the maintainers have reviewed and accepted many contributions. Examples are the Java JDBC driver, the PHP PDO driver or VTGate v3 improvements.

We welcome any contribution! Before you start on larger contributions, make sure to reach out first and discuss your plans with us. 
The slack `#developers` channel is a good venue for reaching out to maintainers.

For someone new to Vitess, here are some basic pre-requisites.

## Learning Go

Vitess server code is all written in [Go aka golang](https://golang.org/). We love it for its simplicity (e.g. compared to C++ or Java) and performance (e.g. compared to Python).

Contributing to our server code will require you to learn Go. We recommend that you follow the [Go Tour](https://tour.golang.org/) to get started.

[The Go Programming Language Specification](https://golang.org/ref/spec) is also useful as a reference guide.

## Learning Vitess

Before diving into the Vitess codebase, make yourself familiar with the system and run it yourself:

* Read the [What is Vitess](../overview/whatisvitess) page, in particular the architecture section.

* Read the [Concepts](../concepts) and [Sharding](../reference/sharding) pages.

  * We also recommend watching our [latest presentations](../resources/presentations).

  * After studying the pages, try to answer the following question (click expand to see the answer):
    <details>
      <summary>
        Let's assume a keyspace with 256 range-based shards: What is the name of the first, the second and the last shard?
      </summary>
      -01, 01-02, ff-
    </details>

* Go through the [Kubernetes](../get-started/kubernetes) and [local](../get-started/local) getting started guides.

  * While going through the tutorial, look back at the [architecture](../overview/architecture) and match the processes you start in Kubernetes with the boxes in the diagram.

## Building Vitess

How-to-build guides are available for Ubuntu, MacOS and CentOS. Most of the maintainers are building on Ubuntu or Mac.

## GitHub workflow

Vitess is hosted on GitHub and the project uses the [Pull Request workflow](github-workflow).

## Coding Guidelines

Pull Requests should follow these [guidelines](code-reviews).

