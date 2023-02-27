---
title: Release Cycle
description: Learn how the Vitess release cycle works
weight: 1
---

The release cycle of a major version is five months long, which can be converted into 21 weeks.
Below is a breakdown of how these weeks are planned.

- [Week 1 (Planning)](#week-1--planning-)
- [Week 2 - 17 (Development)](#week-2---17--development-)
- [Week 17 (Code Freeze RC-1)](#week-17--code-freeze-rc-1-)
- [Week 18 (RC-1)](#week-18--rc-1-)
- [Week 18 - 20 (Bug Fixes)](#week-18---20--bug-fixes-)
- [Week 20 (Code Freeze GA)](#week-20--code-freeze-ga-)
- [Week 21 (GA)](#week-21--ga-)
- [Beyond Week 21 (EOL)](#beyond-week-21--eol-)

### Week 1 (Planning)

The cycle begins as soon as we branch out the previous major version.

At the beginning of the cycle the maintainers gather to establish the roadmap of the upcoming release.
A [public GitHub project](https://github.com/orgs/vitessio/projects) is then created to track the progress of different teams.

### Week 2 - 17 (Development)

From the first month of the cycle until the end of the fourth month, the maintainers contribute to the release according to the roadmap and incoming priorities.

### Week 17 (Code Freeze RC-1)

During the 17th week, the last week of the fourth month, we enter the code freeze of the RC-1 release.
This is usually done right before the weekend, on a Thursday or a Friday.

At this time, the release team creates the release branch (`release-xx.0`) from `main`.
Creating a release branch implies that `main` moves into the next release cycle.  

The release team freezes the release branch until the RC-1 release.
This process leaves enough time to the team to fix and avoid unexpected issues.

Step-by-step breakdown of how the release team achieves this step can be found in the [pre-release instructions](https://github.com/vitessio/vitess/blob/main/doc/internal/ReleaseInstructions.md#pre-release).

### Week 18 (RC-1)

After creating and freezing the release branch for at least a weekend, we proceed to the RC-1 release. A new tag is created, the documentation is updated with the newly created version, and the community is informed of this new release.

At the same time, the release team will create an RC-1 release of the `vitess-operator` to match the new Vitess RC-1 release.

Step-by-step breakdown of how the release team achieves this step can be found in the [release instructions](https://github.com/vitessio/vitess/blob/main/doc/internal/ReleaseInstructions.md#release).

### Week 18 - 20 (Bug Fixes)

Right after RC-1 we expect end-users to report bugs as they try out the new RC-1 release.

This two weeks period is dedicated to fixing any bugs that are found on RC-1 before we release GA.

### Week 20 (Code Freeze GA)

The release team will freeze the release branch and block non-essential incoming changes until the GA release is out.
This is usually done right before the weekend, on a Thursday or Friday.

It allows the release team to fix and avoid unexpected issues.

Step-by-step breakdown of how the release team achieves this step can be found in the [pre-release instructions](https://github.com/vitessio/vitess/blob/main/doc/internal/ReleaseInstructions.md#pre-release).

### Week 21 (GA)

This week closes our five month release cycle.
We publish the GA release of our newest major version.

At the same time, the release team will officially announce the newest release through a blog post, a Slack message, and a Tweet.

Step-by-step breakdown of how the release team achieves this step can be found in the [release instructions](https://github.com/vitessio/vitess/blob/main/doc/internal/ReleaseInstructions.md#release).

### Beyond Week 21 (EOL)

The Vitess maintainer team maintains a major version for up to one year.

As mentioned in [VEP #5](https://github.com/vitessio/enhancements/blob/main/veps/vep-5.md#support-lifecycle), high severity bug fixes will be ported over to the release branch.
If needed and requested, a patch version can be released.

After a year of support, bug fixes and other developments will not be ported over to the release branch.
At this time, the documentation for the release will be archived.
