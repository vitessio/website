---
author: "Adrianna Tan"
published: 2019-03-12T07:15:00-07:00
slug: "2019-03-12-vitess-security-audit"
tags: ['Security']
title: "Vitess Security Audit Results"
---

We are happy to announce that Vitess recently underwent a security assessment, funded by CNCF / The Linux Foundation.

In February 2019, the team from Cure53 performed tests in the following areas:

* system complexity 
* cloud infrastructure
* source code auditing 
* operating system interaction 
* low-level protocol analysis 
* multi-angled penetration testing

This independent security audit was performed on locally installed systems, as well as with a Kubernetes-based cluster. The auditors performed: (1) manual code auditing and (2) code-assisted penetration testing.

Here are some highlights.

“In Cure53’s view, there is a clear intention and follow-through on
providing a secure system for scaling MySQL databases. This was achieved by keeping
the attack surface minimal and selecting the language suited for this implementation.
The auditors managed to reach wide-spanning coverage of all aspects pertinent to the
main repository of the Vitess software system. The most likely avenues for exploitation
were chosen and verified for resilience.”

“The results of this Cure53 assessment funded by CNCF / The Linux Foundation certify
that the Vitess database scaler is secure and robust. This very good outcome is
achieved by limiting the attack surface, taking appropriate care of user-supplied input
with security-driven best practices, as well as - to a certain extent - the usage of the Go
language ecosystem.”

“While the results of this assessment are few and far between and may suggest some
kind of test limitations, they in fact prove that the Vitess team delivers on the security
promises they make.”

The auditors identified three areas of improvement for the Vitess team to work on. We thank Cure53, CNCF, The Linux Foundation and all project contributors for their assistance. 

Click [here](../files/VIT-01-report.pdf) to read the report in full.  



