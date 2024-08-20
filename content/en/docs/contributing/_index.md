---
title: Contribute
description: Get involved with Vitess development
weight: 2300
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

Certainly, here's the complete, updated walkthrough section for writing and running a unit test in the Vitess project:

## Writing and Running a Unit Test

Unit tests help ensure that all components of the codebase work as expected and make it easier to catch bugs early. Here’s an example on how to write and run a unit test in Vitess: 

#### Identify an Issue

Start by looking for issues marked as [good first issue](https://github.com/vitessio/vitess/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22). Suppose you find an issue about increasing error handling capacity in a specific function.

#### Write a Unit Test

Now that we know where we want to make changes, let's navigate to the directory of the file you want to modify. Create a new test file with the same name as the original file, appending `_test` to the filename. For example, if you're working on `db.go`, your test file should be named `db_test.go`.

Here's a basic structure for your test:

```go
package main

import (
    "testing"
)

func TestFunctionName(t *testing.T) {
    // Initialize test conditions here

    // Invoke the function under scrutiny
    result := functionName(args)

    // Verify the expected outcome
    if result != expectedResult {
        t.Errorf("Expected %v, got %v", expectedResult, result)
    }
}
```

Make sure to replace `functionName`, `args`, and `expectedResult` with the actual function name, arguments, and expected outcome relevant to the issue you're working on.

#### Execute  Test

To execute your test, you can use Go's testing tool by running:

```bash
go test -v
```

The `-v` flag provides verbose output, showing you which tests passed or failed. If your test passes, you'll see output like this:

```bash
PASS
ok  	github.com/yourusername/vitess/rest_of_the_path	        0.003s
```

**Running a Specific Test**

If you want to run a particular test, such as `TestFunctionName` from our example, use:

```bash
go test -v -run TestFunctionName
```

Please remember, this is a basic example. Vitess often requires more complex tests including database operations, which may need additional setup and steps.

## GitHub Workflow

Vitess is hosted on GitHub and the project uses the [Pull Request workflow](github-workflow).

## Coding Guidelines

Pull Requests should follow these [guidelines](code-reviews).

