---
title: Release Notes
description: Everything you need to know to contribute to the release notes of Vitess
---

The [release notes](https://github.com/vitessio/vitess/releases) of Vitess describe what a new release is about. We list the new features, bug fixes, important announcement, deprecation notice, etc.
Since we have a release note document for each release, it was important to us that we create a tool that automatically generate them for us. The tool can be found in [this package](https://github.com/vitessio/vitess/tree/main/go/tools/release-notes).

### How to use release note generation tool?

{{< info >}}
You must have the `gh` tool installed first. Click [here](https://github.com/cli/cli) if you don't already have it.
{{< /info >}}

First, we need to `git fetch` the remote we want to work with and make sure we are up-to-date with the server.

Then, we use the Makefile command `release-notes` as followed:

```shell
make release-notes FROM="v11.0.0" TO="upstream/main" VERSION="v12.0.0" SUMMARY="./my_summary.md"
```

> In this example we are generating release notes for `v12.0.0`.

The `FROM` argument is required, it tells the tool from which point in time we need to analyze the different pull requests.
The value here is `v11.0.0` which corresponds to the `v11.0.0` release git tag.

The `TO` argument is not required and defaults to `HEAD`.
It tells the tool the upper limit point in time for the pull request analysis.
Here the value is `upstream/main` corresponding to the main branch of `vitessio/vitess`.

The `VERSION` argument is the name of the new release.

The `SUMMARY` argument is optional, it is a path to a README file that contains a text that will added in the `Announcement` section of the release notes.

### How to add pull requests to the release notes?

When generating the release notes, only the pull requests labeled with `release notes` will be listed.

Pull requests can also be labeled with `release notes (needs details)`.
Those will be listed in the `Announcement` section of the release note with a special `TODO` that requires human intervention for further explanation on what the pull request do.
For instance, it can be an important pull request that deprecates a part of Vitess, or an important feature that we want to talk about.
