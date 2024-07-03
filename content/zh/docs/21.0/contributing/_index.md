---
title: 贡献Vitess
description: 我们热爱所有参与贡献的人，这篇文章将描述您如何参与到贡献Vitess中来
weight: 6
---
{{< info >}}
因为这些文档不维护，所以它们是旧的。
{{< /info >}}

什么，听说您想对vitess作出贡献？这简直太棒了！

过去的一段时间，我们审查并接受了许多外部贡献。比如Java JDBC驱动程序，PHP PDO驱动程序或以及vtgate v3改进。

我们期待来自您的任何贡献！在您开始做出更大贡献之前，请务必先与我们联系，与我们一起讨论一下您的计划。

这个页面描述了新贡献者如何熟悉Vitess和编程语言Go。


## 学习 Go

Vitess是[谷歌编程语言Go](https://golang.org/)的早期吃螃蟹的人.

与C++或Java比，我们喜欢它的简洁；与Python比，我们喜欢它的性能表现。

如果您想对我们的服务器代码作出贡献，您需要对Go有一定了解。如果您并未有太多的Go经验，我们建议您阅读以下资源。

### Go 之旅

https://tour.golang.org/


Go之旅是一个基于浏览器的教程，它解释了Go编程语言的基本概念。
它是交互式的，即您可以更改并运行右侧的所有示例。
后面的步骤也有特定的练习，你可以尝试自己完成编码。
渐进式的学习使您的学习过程变得很有趣，而且您会愈发的体会到编写Go代码是多么简单。

### Go 可读性

在Google内部，代码审核需要额外的“可读性”审核。

可读性审阅者确保被审阅者编写惯用代码并遵循编程语言的样式指南。

虽然没有Go风格指南，但Go社区中有一系列建议，这些建议加起来就是隐式风格指南。为了确保您正在编写惯用风格的Go代码，请阅读以下文档：


* Go 可读性幻灯片 https://talks.golang.org/2014/readability.slide
  * 通过许多具体的例子来了解Go的可读性。
* "高效的 Go": https://golang.org/doc/effective_go.html
  * Recommendations for writing good Go code.
* Go 代码审阅注释: https://github.com/golang/go/wiki/CodeReviewComments
  * 最接近风格指南的参考资料。

### 其他资源

如果您不确定Go的行为或语法，我们建议您在规范中查找： https://golang.org/ref/spec
它写得很好，易于理解

### 欣赏 Go

使用Go几周之后，我们希望您能像我们一样开始热爱Go。

在我们看来，谷歌acapella乐队ScaleAbility的歌曲“Write in Go”完美地捕捉了Go的特别之处。观看它，享受你学到的Go: www.youtube.com/watch?v=LJvEIjRBSDA

## 学习 Vitess

在深入了解Vitess代码库之前，请务必先熟悉Vitess架构，并尝试本地跑起来Vitess:

* 可以先看看[What is Vitess](../overview/whatisvitess) 页面, 尤其是架构部分要深入理解。

* 接下来学习[Vitess concepts](../overview/concepts) 部分和[Sharding](../sharding) 概念。

  * 我们建议您抽空看看 [latest presentations](../resources/presentations)。这些presentations包含了许多插图，有助于帮助您了解Vitess的详细工作原理。

  * 在您完成了上述学习之后，尝试回答以下问题 (单击展开可以查看答案):
    <details>
      <summary>
        一个keyspace有256个基于范围的分片，请问第一个，第二个和最后一个分片的名称是什么？
      </summary>
      -01, 01-02, ff-
    </details>

* 详细了解 [Vitess Kubernetes tutorial](../get-started/kubernetes) 部分。

  * 在阅读教程的同时，别忘了经常回顾 [架构部分](../overview/architecture/#architecture) ，想一想Kubernetes中的哪部分流程与架构图中的哪部分能够匹配上？


