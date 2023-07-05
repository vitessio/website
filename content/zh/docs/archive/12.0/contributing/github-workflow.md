---
title: GitHub 工作流程
---

如果您是Git和GitHub的新手，我们建议您阅读此页面。否则，您可以跳过它。

我们的GitHub工作流程是一个所谓的三角工作流程：

<img src="https://cloud.githubusercontent.com/assets/1319791/8943755/5dcdcae4-354a-11e5-9f82-915914fad4f7.png" alt="visualization of the GitHub triangular workflow " style="width: 100%;"/>

*Image Source:* https://github.com/blog/2042-git-2-5-including-multiple-worktrees-and-triangular-workflows



这个托管的代码仓库我们称为*upstream*。
您可以从我们的上游代码仓库克隆一份代码，并在其中开发和提交您的更改（在上图中显示为*local*）。然后将更改推送到您forked代码仓库（*origin*）并向我们发送pull请求
。最后，我们将把你的pull请求合并回*upstream*代码仓库。

## Remotes

您从您的fork代码仓库中clone一份代码, `origin` remote
应该显示成这样:

```
$ git remote -v
origin  git@github.com:<yourname>/vitess.git (fetch)
origin  git@github.com:<yourname>/vitess.git (push)
```

为了帮助您保持fork仓与主仓同步，添加一个`upstream`远程

```
$ git remote add upstream git@github.com:vitessio/vitess.git
$ git remote -v
origin  git@github.com:<yourname>/vitess.git (fetch)
origin  git@github.com:<yourname>/vitess.git (push)
upstream        git@github.com:vitessio/vitess.git (fetch)
upstream        git@github.com:vitessio/vitess.git (push)
```

同步你的本地`master`分支，执行以下操作：

```
$ git checkout master
(master) $ git pull upstream master
```

注意：在上面的示例输出中，我们使用`(master)`前缀提示符，
强调命令必须从分支`master`运行。

有一个小技巧，您可以不写`upstream master`，只运行`git pull`命令。前提是您设置了`master`分支跟踪到`vitessio/vitess`分支。如下命令所示：

```
(master) $ git branch --set-upstream-to=upstream/master
```

现在，以下命令同步您的本地`master`分支:

```
(master) $ git pull
```

## 主题分支

在开始处理更改之前，请创建主题分支：

```
$ git checkout master
(master) $ git pull
(master) $ git checkout -b new-feature
(new-feature) $ # You are now in the new-feature branch.
```

尝试在完成它们的过程中分批次逐步提交，并在每次的提交更改时附上提交消息注明更改内容。
有关更多指导，请参阅[代码审查页面](../code-reviews)。

当你在一个包中做出修改的时候，你可以在该包中运行`go test`来进行单元测试验证您的修改是否有效。

当你准备测试整个系统的时候，从Git tree根目录运行整套测试体系，运行 `make
test`  

如果尚未安装`make test`的所有依赖项，则还可以观察Travis CI测试结果。
CI 在您提交pull request时候自动执行，你可以等待并观察CI是否顺利通过，如果有问题，CI会跑不过，您可以根据CI的错误提示定位问题，不方便的一点是CI的执行过程很长，您需要耐心等待。

## 交付你的工作

运行`git commit`时，使用`-s`选项添加Signed-off-by行。

这是[the Developer Certificate of Origin](https://github.com/apps/dco)所必须的要求。

## 发送 Pull 请求

将您的分支推送到代码仓（并将其设置为使用`-u`进行跟踪):

```
(new-feature) $ git push -u origin new-feature
```

您可以从`git push`中省略`origin`和`-u new-feature`参数,只需运行如下两个Git命令进行配置更改：

```
$ git config remote.pushdefault origin
$ git config push.default current
```

第一个设置可以避免每次输入`origin`。而第二个设置，Git假设GitHub端的远程分支
与您的本地分支同名。

在此更改之后，您可以运行不带参数的`git push`：

```
(new-feature) $ git push
```

转到[repository 页面](https://github.com/vitessio/vitess) ,将会提示您从最近推送的分支创建一个Pull请求。
您也可以 [手动选择分支](https://github.com/vitessio/vitess/compare).

## 解决变更


如果您需要根据代码审阅者的建议进行代码修复，只需要在此分支上完成修改后再次提交，然后推送即可：

```
$ git checkout new-feature
(new-feature) $ git commit
(new-feature) $ git push
```

一个提交请求只反映出您所在主题分支的变化，和主分支无关。

一旦您的提交请求被合并后：

*  关闭GitHub问题（如果没有自动关闭）
*  删除您的本地主题分支（`git branch -d new-feature`）

