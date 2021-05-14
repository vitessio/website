---
title: Bugfixes and Release Branches
---

## Support lifetime
We support releases for 9 months, which translates to three versions.
As an example, if we just released v10.0, we support the v9.x and v8.x versions.
This means that when a bug is found, it needs to be fixed in all affected versions that are still supported.

## Types of branches

### Main 

This is the main dev branch, and this is where we will cut the next release tag from. Feature branches should be merged into this branch.

### Release
When a branch named “release-XXX” is created, it means that this branch should only
receive fixes and no new features.

### Bugfix
A bugfix branch just does this - it fixes a bug in a released branch. Bugfix branches should be aimed at the oldest supported released version that is affected by the bug. Preferably, these branches should be prefixed by "fix-".

### Feature
New features are built on separate branches. These should aim to be merged into the main branch. Preferably, these branches should be prefixed by "feature-".

## How to fix a bug
Start by figuring out which is the oldest supported release branch that has the issue.
Create a bugfix branch from the affected release branch.
Bugfixes must have an automated test (preferable end to end) that clearly shows the issue being solved - a test that fails without the fix and passes with the fix.
This makes it easy to understand what is being fixed, and protects from regressions in the future.

While you are fixing the bug, it's valuable if you take the time to step back and try to think of other places where this problem could have impacted.
It's often possible to infer that other similar problems in this or other parts of the code base can be prevented.

## Merge the bugfix into newer releases
Create the bugfix PR, get it accepted and merged into the release branch
Now follows the merge-train: if the bugfix was merged into release-n, we need to merge release-n into release-(n+1), and then release-(n+1) into release-(n+2), until we can merge the latest release into main

## Why do it this way?

1. It helps focus on the bugfix. 
It’s easy to get drawn into refactoring and cleaning code while you are doing a bugfix, but that should not be done on release branches, only on feature branches.
2. The fix will have the same commit SHA in all branches - since we are doing a single bugfix PR and then spreading it to more recent branches by forward merging them, all branches will have the same bugfix history.
 Backporting using cherry-picking creates separate fix commits on the different release branches.
3. It’s often easier to move a change forward in versions than backward.
