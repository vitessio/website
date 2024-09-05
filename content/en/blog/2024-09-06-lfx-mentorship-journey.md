---
author: 'Jad Chahed'
date: 2024-09-06
slug: '2024-09-06-lfx-mentorship-journey'
tags: ['Vitess', 'Arewefastyet', 'mentorship']
title: 'LFX Mentorship Journey'
description: "My experience as an LFX mentee contributing to Vitess's 'Arewefastyet' project."
---

## Introduction

This summer, I had the incredible opportunity to participate in the [LFX Mentorship program](https://lfx.linuxfoundation.org/tools/mentorship/), where I contributed to [Vitess](https://vitess.io/), a [CNCF graduated project](https://www.cncf.io/projects/vitess/). Vitess is a cloud-native database designed for horizontal scaling of [MySQL](https://www.mysql.com/). My specific focus during this mentorship was on the "[Arewefastyet](https://github.com/vitessio/arewefastyet)" subproject, an essential benchmarking platform for Vitess. "Arewefastyet" plays a crucial role in ensuring that each new version of Vitess maintains or improves performance, making it a vital component of the Vitess ecosystem.

## Mentorship Experience

### Initial Goals and Expectations

At the beginning of my mentorship, the primary objective was clear: to redesign and revamp the ["Arewefastyet" website](https://benchmark.vitess.io/). Although I have extensive experience with TypeScript, particularly within the Angular framework, [this project](https://github.com/vitessio/arewefastyet/issues/525) presented a new challenge—migrating to a React-based system and focusing on creating a design that not only looked good but also offered a seamless user experience (UX).

To help achieve these goals, I incorporated the [Shadcn](https://ui.shadcn.com/) library, which provided pre-built, highly customizable UI components that significantly streamlined the development process, especially for complex features like tables and forms. The combination of Shadcn with React allowed for a more consistent and polished user interface across the site.

The scope of my work was divided into "scoped" and "optional" tasks. The completion of the "scoped" tasks was crucial for the success of my mentorship. These tasks included everything from creating a new public Figma board to implementing the design on the website, ensuring consistency across all pages, and integrating new features such as a benchmark [history page](https://benchmark.vitess.io/history).

### Key Challenges and Learning

Given my strong background in [TypeScript](https://www.typescriptlang.org/), the technical challenges of working with [React](https://react.dev/) were manageable, though they required a shift in mindset from my usual [Angular](https://angular.dev/) development. However, the most significant challenge was creating a design that balanced aesthetics with functionality. I had to ensure that the site was not only visually appealing but also easy to navigate and use, particularly for users who needed to interact with complex benchmarking data.

Another challenge was the sheer volume and complexity of the data being presented. "Arewefastyet" handles a large volume of benchmarking data, and making this data easily understandable and navigable was no small feat. I had to design and implement a new page that would list all available benchmarks for each commit, branch, and tag while ensuring that users could easily track performance changes over time.

With guidance from my mentors, I was able to overcome these challenges, learning a great deal in the process. The experience of collaborating closely with experienced developers, discussing design choices, and iterating on feedback was invaluable.

### Milestones Achieved

Throughout the mentorship, I achieved several key milestones, which I’m particularly proud of:

- **New Figma Board**: I started by creating a new [public Figma board](https://www.figma.com/design/kPIMCP3A5hQeD66UTKtuQH/arewefastyet?node-id=14-21&t=HKGQMY2WK6sO3a5F-1), which served as the foundation for the redesign. This board was reviewed and approved by my mentors and other contributors and maintainers, ensuring alignment with the overall Vitess design guidelines.

- **Responsive Design**: I ensured that the new design was fully responsive, maintaining a consistent user experience across all devices.

- **Benchmark History Page**: I implemented a new page that lists all available benchmarks, providing users with a comprehensive history of performance metrics across various versions of Vitess.

<div style="width:500px; margin: 0 auto">
<img src="/files/2024-09-06-lfx-mentorship-journey/history-page.png" alt="Distribution: 45% More than 3 years, 36% - 1 to 3 years, 13% - 6 months to 1 year, and 6% - Less than 6 months." style="margin-top:6px"/>
</div>

- **Improved Navigation**: I significantly improved the navigation across the website, thanks to the power of Shadcn components. Pagination was added to every table, making it easier to browse large datasets. Additionally, I integrated a search bar that allows users to quickly find specific commits, and I added functionality to compare commits across the site.

|  Before | After |
|  -----  | ----- |
|![Status hero before](/files/2024-09-06-lfx-mentorship-journey/status-hero-before.png) | ![Status hero after](/files/2024-09-06-lfx-mentorship-journey/status-hero-after.png)|
|![Status previous executions before](/files/2024-09-06-lfx-mentorship-journey/status-previous-executions-before.png) | ![Status previous executions after](/files/2024-09-06-lfx-mentorship-journey/status-previous-executions-after.png)|
|![Daily hero before](/files/2024-09-06-lfx-mentorship-journey/daily-hero-before.png) | ![Daily hero after](/files/2024-09-06-lfx-mentorship-journey/daily-hero-after.png)|
|![Daily hero before](/files/2024-09-06-lfx-mentorship-journey/daily-oltp-chart-before.png) | ![Daily hero after](/files/2024-09-06-lfx-mentorship-journey/daily-oltp-chart-after.png)|

- **Frontend and Backend Integration**: In addition to frontend work, I also contributed to the backend, collaborating with my mentors to make necessary changes in Golang that supported the new frontend features.

These milestones not only fulfilled the requirements of my mentorship but also added significant value to the "Arewefastyet" project, making it more user-friendly and easier to maintain.

## Extending Beyond the Original Scope: Building an Admin Dashboard

By the time I completed the "scoped" tasks, I still had a significant portion of my mentorship period remaining. To make the most of this time, I took on an additional, more challenging task: creating an admin dashboard for the "Arewefastyet" project.

### The Challenge: Learning Golang on the Fly

The admin dashboard was a critical addition that would allow Vitess maintainers to manage benchmark execution queues directly, rather than relying solely on cron jobs. This feature was designed to give maintainers greater control and flexibility, making the benchmarking process more efficient and responsive to the needs of the project.

Building this dashboard required me to dive into [Golang](https://go.dev/), a language I had not worked with before. Given that almost all of Vitess's codebase and the benchmarking system were already written in Go, it made sense to implement the admin dashboard using Go as well. This meant I had to learn Go on the job, quickly getting up to speed with its syntax and best practices.

### Implementation with Golang and HTMX

The admin dashboard was built entirely with Go on the backend and [HTMX](https://htmx.org/) for dynamic frontend updates. HTMX allowed me to create a highly interactive interface without relying heavily on JavaScript frameworks, which kept the dashboard lightweight and responsive.

The dashboard features include:

- Queue Management: Maintainers can now add or remove benchmark executions from the queue manually, providing greater control over the benchmarking process.

- Access Control: The dashboard is secured so that only authorized maintainers or administrators can access it, ensuring that sensitive operations are restricted to trusted users.

This admin dashboard represents a significant step forward for the "Arewefastyet" project, providing maintainers with powerful new tools to manage benchmarks more effectively.

## Sharing My Experience at KubeCon NA

As a recognition of the work I completed during this mentorship, my mentor has invited me to co-present a talk at the upcoming [KubeCon North America](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/) in Salt Lake City. [This talk](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/program/schedule/) will cover the details of my contributions to the "Arewefastyet" project, including the challenges I faced and the solutions we implemented.

If you’ve enjoyed reading this article and are interested in learning more about the technical aspects of my work or the broader implications for the Vitess project, I warmly invite you to attend our session at KubeCon. It will be a fantastic opportunity not only to delve deeper into the project but also to discuss and share experiences in person. I look forward to meeting and connecting with others in the community!

## Personal Growth and Reflection

This mentorship was a period of immense growth for me. Technically, I deepened my knowledge of React and TypeScript, and I gained hands-on experience with Figma and responsive design principles. Additionally, learning Golang on the fly and successfully implementing a critical new feature in a language I was unfamiliar with was both challenging and rewarding.

Beyond the technical skills, I developed important soft skills such as communication and time management. Working with mentors located in different time zones taught me how to manage my time effectively and how to communicate clearly in a remote, collaborative environment.

The feedback I received from my mentors was invaluable. They provided guidance on everything from code quality to design choices, helping me to refine my approach and deliver high-quality work. This experience has given me greater confidence in my abilities, and I am eager to continue contributing to Vitess and other open-source projects.

## Conclusion

Participating in the LFX Mentorship program has been one of the most rewarding experiences of my career so far. It provided me with the opportunity to contribute to a significant open-source project, work closely with experienced developers, and develop both my technical and soft skills.

I highly encourage anyone interested in open-source development to consider applying for this program. The mentorship, learning opportunities, and sense of community are truly unparalleled.

If you're interested in seeing the work I've done during this mentorship, feel free to check out the [Arewefastyet](https://github.com/vitessio/arewefastyet) project on GitHub. I'm always open to feedback and discussions, so don't hesitate to reach out!
