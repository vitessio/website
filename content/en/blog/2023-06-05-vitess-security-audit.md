---
author: 'Deepthi Sigireddi'
date: 2023-06-05
slug: '2023-06-05-vitess-security-audit'
tags: ['security','Vitess','MySQL']
title: 'Vitess Security Audit Results'
description: "Third-party security audit of Vitess completed"
---

The Vitess Maintainer team is pleased to announce the results of a recent third-party security audit of the Vitess code base.

Vitess had previously been audited in 2019. Given the amount of time that has passed, and the magnitude of change during that time, the maintainer team decided to request a fresh audit.
Starting in March 2023, an independent team from [Ada Logics](https://adalogics.com) performed a full security audit of Vitess with a special focus on VTAdmin, which is a relatively new addition to Vitess.

## Scope
The goals of the audit were to:

* Produce a formal threat model of VTAdmin.
* Perform a manual audit of the VTAdmin code following the threat model. 
* Align Vitess’s fuzzing suite with the threats identified by the maintainers. 
* Perform a manual audit of the remaining Vitess code base.
* Conduct a Supply Chain Levels for Software Artifacts (SLSA) review of Vitess.

## Outcomes
* No Critical issues were found during the audit. 
* A total of 12 Moderate/Low/Informational issues were reported.
* Vitess published two Moderate Severity CVEs and patch releases with associated fixes for them.
* All the reported issues that are under our control have either been fixed, or have a plan in place to be fixed before the end of the year.
* We ended up deleting some unused code as a result of the audit, which is always a good thing.
* Ada Logics contributed two additional fuzzers to the fuzzing test suite for Vitess.
* The Vitess team started work on generating SLSA artifacts such as provenance attestation before the audit commenced, this is still in progress.

Some highlights from the report:

> Our overall assessment of VTAdmin is highly positive. VTAdmin follows secure design and code practices.

> The VTAdmin code is clean and well-structured, making it easy to understand and audit.

> This professional response to security disclosures is an important element of well-maintained security policy.

We are grateful to the [Cloud Native Computing Foundation](https://cncf.io) for sponsoring this audit, and to [OSTIF](https://ostif.org) for facilitating it.
Special thanks are due to Andrew Mason and Dirkjan Bussink for doing most of the remediation work, and to Adam Korczynski and David Korczynski of Ada Logics for conducting the audit.

You can read the full audit report [here](../../files/VIT-03-report-security-audit.pdf).
