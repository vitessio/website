---
title: Code Reviews
---

Every GitHub pull request must go through a code review and get approved before it will be merged into the master branch.

## What to look for in a Review

Both authors and reviewers need to answer these general questions:

*   Does this change match an existing design / bug?
*   Is there proper unit test coverage for this change? All changes should
    increase coverage. We need at least integration test coverage when unit test
    coverage is not possible.
*   Is this change going to log too much? (Error logs should only happen when
    the component is in bad shape, not because of bad transient state or bad
    user queries)
*   Does this change match our coding conventions / style? Linter was run and is
    happy?
*   Does this match our current patterns? Example include RPC patterns,
    Retries / Waits / Timeouts patterns using Context, ...

Additionally, we recommend every author to look over your own reviews just before committing them and check if you are following the recommendations below. We usually check these kinds of things while skimming through `git diff --cached` just before committing.

*   Scan the diffs as if you're the reviewer.
    *   Look for files that shouldn't be checked in (temporary/generated files).
    *   Look for temporary code/comments you added while debugging.
        *   Example: fmt.Println("AAAAAAAAAAAAAAAAAA")
    *   Look for inconsistencies in indentation.
        *   Use 2 spaces in everything except Go.
        *   In Go, just use goimports.
*   Commit message format:
    *   ```
        <component>: This is a short description of the change.

        If necessary, more sentences follow e.g. to explain the intent of the change, how it fits into the bigger picture or which implications it has (e.g. other parts in the system have to be adapted.)

        Sometimes this message can also contain more material for reference e.g. benchmark numbers to justify why the change was implemented in this way.
        ```
*   Comments
    *   `// Prefer complete sentences when possible.`
    *   Leave a space after the comment marker `//`.

If your reviewer leaves you comments, make sure that you address them and then click "Resolve conversation". There should be zero unresolved discussions before the PR is ready to merge.

## Assigning a Pull Request

Vitess uses [code owners](https://github.blog/2017-07-06-introducing-code-owners/) to auto-assign reviewers to a particular PR. If you have been granted membership to the Vitess team, you can add additional reviewers using the right-hand side pull request menu.

During discussions, you can also refer to somebody using the *@username* syntax and they'll receive an email as well.

If you want to receive notifications even when you aren't mentioned, you can go to the [repository page](https://github.com/vitessio/vitess) and click *Watch*.

## Approving a Pull Request

As a reviewer you can approve a pull request through two ways:

* Approve the pull request via GitHub's code review system
* Reply with a comment that contains *LGTM*  (Looks Good To Me)

## Merging a Pull Request

Pull requests can be merged after they were approved and the CI tests have passed.

