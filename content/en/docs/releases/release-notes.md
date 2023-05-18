---
title: Release Notes
description: Learn how release notes are generated
weight: 3
---

The [release notes](https://github.com/vitessio/vitess/releases) of Vitess describe what a new release is about. We list the new features, bug fixes, important announcement, deprecation notice, etc.

Since we publish release notes for each release, it was important to us to have a tool that can automatically generate them for us.
This tool can be found in [this package](https://github.com/vitessio/vitess/tree/main/go/tools/release-notes).

### How to use the release notes generation tool

{{< info >}}
You must have the `gh` tool installed first. Click [here](https://github.com/cli/cli) if you don't already have it.
{{< /info >}}

First, we need to `git fetch` the remote we want to work with and make sure we are up-to-date with the server.

Then, we use the Makefile command `release-notes` as followed:

```shell
make VERSION="v15.0.0" FROM="v14.0.0" TO="HEAD" SUMMARY="./doc/releasenotes/15_0_0_summary.md" release-notes
```

> In this example we are generating release notes for `v15.0.0`.

The `FROM` argument is required, it tells the tool from which point in time we need to analyze the different pull requests.
The value here is `v14.0.0` which corresponds to the `v14.0.0` release git tag.

The `TO` argument is not required and defaults to `HEAD`.
It tells the tool the upper limit point in time for the pull request analysis.
Here the value is `upstream/main` corresponding to the main branch of `vitessio/vitess`.

The `VERSION` argument is the name of the new release.

The `SUMMARY` argument is optional, it is a path to a README file that contains text to prefix the release notes with what the maintainers wrote before the release.
