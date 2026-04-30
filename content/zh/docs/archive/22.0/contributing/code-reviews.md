---
title: 代码审查
---

每个GitHub的pull请求必须经过代码审查并获得批准才能合并到主分支中。


## 都审查点儿啥

作者和参与评审的人都需要回答以下共性的问题：

*   此次修改是否与现有设计匹配，是否解决了现存的一个BUG？
*   此次修改是否有适当的单元测试？所有更改都应该增加覆盖范围。当单元测试覆盖不可能时，我们至少需要集成测试覆盖。
*   Is this change going to log too much? (Error logs should only happen when the component is in bad shape, not because of bad transient state or bad user queries)
这项更改会记录太多日志吗？（错误日志只应在组件内部发生异常时记录，而不是由于错误的瞬态状态或错误的用户查询）
*   此更改是否符合我们的编码约定/样式？Linter运行是否正常？
*   这符合我们目前的模式吗？示例包括RPC模式，使用Context的Retries / Waits / Timeouts模式 ...

此外，我们建议每一位作者在提交评论之前都要仔细阅读自己的评论，并检查您是否遵循下面的建议。在提交之前，我们通常在浏览`git diff --cached` 时检查这些类型的内容。

*   检查差异，就仿佛你是审查员
    *   检查是否签入了本不该签入的文件?（临时/生成的文件）。
    *   仅限谷歌：删除谷歌机密信息（如内部URL）。
    *   查找调试时添加的临时代码/注释。
        *   示例: fmt.Println("AAAAAAAAAAAAAAAAAA")
    *   查找缩进中的不一致。
        *   除go外，所有内容都使用2个空格。
        *   在Go中，只需使用goimports。

*   提交消息格式:
    *   ```
        <component>: 这是对更改的简短描述。

        如有必要，后面会有更多的句子，例如解释变化的意图、它如何适应更大的图景或它具有的含义（例如，系统中的其他部分必须进行调整）。

        有时，此消息还可以包含更多的参考资料，例如基准数字，以证明为什么以这种方式实施更改。
        ```
*   Comments
    *   `// `后面最好写个完整的句子
    *    `//`后面带个空格.

在审核期间，请确保您处理所有评论。点击图标（reviewable.io）标注完成或者回复“完成”。 （GitHub Review）将评论标记为已解决。当它准备好合并时，应该有0个未解决的讨论。

## 指定 Pull 请求

如果您想将评论发送给特​​定的一组队友，请将其添加为受让人（pull request的右侧）他们会收到邮件。

在讨论过程中，您还可以 *@username* ，他们也会收到一封电子邮件。

如果您想要收到通知，即使您没有被提及，也可以转到[repository page](https://github.com/vitessio/vitess) 点击 *Watch*.

## 同意 Pull 请求

作为审阅者，您可以通过两种方式批准Pull请求：

* 通过GitHub的新代码审查系统批准Pull请求

* 回复评论，其中包含单词 *LGTM*  (Looks Good To Me 我觉得没问题)

## 合并 Pull 请求

PR在获得批准并且Travis测试通过后，Vitess团队将合并您的Pull请求。

