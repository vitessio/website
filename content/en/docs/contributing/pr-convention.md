---
title: PR Naming Conventions
description: A naming convention for GitHub pull requests
weight: 1
---

## Background

There's a clear need of improving GitHub naming conventions for the following sections.

- Pull Request Naming
- Branch Naming
- Commit Message Naming
- Tag Naming
- Label Addition

## Feature

The most problematic area we see is the Pull Request Naming Convention and Labels hence we'd like to come up with guidelines and once agreed by maintainers provide a Template that will help streamline the above areas.

For Issue Templates please refer to this [section](https://github.com/vitessio/vitess/tree/main/.github/ISSUE_TEMPLATE).

## Solution

### Naming Convention

The suggested solution would be creating general guidelines for this naming convention update.

- Short and descriptive summary
- End with corresponding ticket/story id (e.g., GitHub issue, etc.)
- Should be capitalized and written in imperative present tense
- Not end with a period

#### Consists of Three Parts:

* Title: Short informative summary of the pull request
* #[Issue_ID]
* Description: More detailed explanatory text describing the PR for the reviewer

Suggested Format:
Description #[Ticket_ID]
Example:
```Fix where clause in information schema with correct database name #6599```

#### Description:

- Separated with a blank line from the subject
- Explain what, why, etc.
- Max 72 chars
- Each paragraph capitalized
- Example and/or Reproduce steps

```
Overview of the Issue
The query sent down from VTGate to Vttablet does not replace the where clause of the information schema queries for table_schema = 'keyspace' to table_schema = 'databasename'

Reproduction Steps
Steps to reproduce this issue, for example:

Deploy the following vschema:

{
  "sharded": false,
  "tables": {
  }
}
```

### Labels

Two class of labels have been created and 1 label from each class must be added to all the pull requests.
The two classes and the corresponding labels are as follows :-

* **Component**
  * Build/CI
  * Cluster Management
  * Java
  * Observability
  * Query Serving
  * VReplication
  * VTAdmin
  * vttestserver

* **Type**
  * Announcement
  * Bug
  * CI/Build
  * Documentation
  * Enhancement
  * Feature Request
  * Internal Cleanup
  * Performance
  * Question
  * RFC
  * Testing

Additionally, other labels may be added as appropriate.

## Other Suggestions

* How to write good pull requests via GitHub templates [link](https://docs.github.com/en/free-pro-team@latest/github/building-a-strong-community/about-issue-and-pull-request-templates)

## Call for feedback

We're looking for the community's feedback on the above suggestions/flow. Thank you for taking the time to read and respond!
