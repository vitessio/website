---
author: 'Andres Taylor'
date: 2021-03-24
slug: '2021-03-24-code-generation-vitess'
tags: ['Vitess','MySQL', 'DDL', 'code generation', 'Go', 'Golang', 'cloud', 'kubernetes']
title: 'Code generation in Vitess'
description: 'How to write nice code, and eat the cake too'
---

[Cross posting from](http://systay.github.io/blog/2021/03/23/code-generation-in-vitess)

# {{ page.title }}


Golang is a wonderful language. It's simple, and most of the time not confusing or surprising.
This makes it easy to jump into library code and start reading and quickly understand what's going on.
On the other hand, coming from other languages, there are a few features that would make our lives easier.

We are building Vitess using mostly golang, and most of us are happy with this choice.
However, because of missing features in the language, we've had to build some tooling manually.

Here follows a list of how we are using meta programming in Vitess.

### GRPC messages and endpoints

Everyone uses code generation for protobuf, so that's very interesting to write about. Moving on.

### SQL Parser

We use goyacc to build our parser.
Goyacc reads input in the form of a `sql.y` file, and it outputs the `sql.go` parser we use.
Writing this manually would not really have been an option. The code would probably become slow and very difficult to maintain.
To speed up the parser to ludicrous speed, we forked the goyacc code and adapted it to our needs. You can read more about this work [here](https://github.com/vitessio/vitess/pull/7669).

### Memory usage for plans

Query planning is a resource intensive task, and to make sure we don't have to do that more than necessary, we cache plans.
Whenever you are caching, you need to be concerned about the size of your caches - you don't want the cache to eat too much memory.
To do that, you need information about how much memory plan tree consume.
And this is one of the shortcoming of golang - it's very difficult to do this.
So, again, meta generation came to the rescue.

Go comes with excellent parser and tokeniser tools to allow you to read Go code as a stream of AST objects.
Unfortunately, we need more than syntax when looking at our plans to make sense of them - we also need dependencies and type information.
To get this, we use golang.org/x/tools/go/packages.

What we do is to first find the plan struct, and from that, we find all types that are used by the fields of the plan.
```go
type Plan struct {
    Type         sqlparser.StatementType 
    Original     string
    Instructions Primitive
    BindVarNeeds *sqlparser.BindVarNeeds
    Warnings     []*querypb.QueryWarning
}
```
For every type that we encounter, we create a `CachedSize` method that can calculate the memory size of an instance.
If the type happens to be an interface, we instead find all implementations and do the same exercise again.
This is done until we have a method for all types that might show up in a plan-tree. You can look at what the these functions look like [here](https://github.com/vitessio/vitess/blob/master/go/vt/sqlparser/cached_size.go). 

### AST tooling

After parsing, the tree structure that contains the original query has been turned into an abstract syntax tree, or an AST.
It contains the information we need from the query, with the uninteresting bits such as whitespaces removed. 
It's a type safe version of the query the user sent us. 

Our AST is pretty large, and many developers work on it, adding new types and fields all the time.

In order to plan queries, we needed a couple of utilities for our AST that Go does not provide for us.

1. First of, we needed to be able to traverse the AST - a plain old visitor that could traverse the whole tree quickly. [Check out the code](https://github.com/vitessio/vitess/blob/master/go/vt/sqlparser/ast_visit.go)

2. We also need the ability to replace parts of the node. This is much like the visitor, but with a way to replace the node that is currently being visited. [Check out the code](https://github.com/vitessio/vitess/blob/master/go/vt/sqlparser/ast_rewrite.go)

3. We need a way of doing equality comparisons without using `reflect.DeepEqual`.
Struct comparisons in Go work as expected, until you have references in your structs. Then all bets are off.
DeepEqual does what we need, but it does so slowly. Comparing our generated equality methods vs `reflect.DeepEqual` gives:
   
```
name       old time/op  new time/op  delta
Equals-16   813µs ± 0%    11µs ± 1%  -98.64%  (p=0.000 n=9+9)
```

The `reflect.DeepEqual` is >72 times slower than our generated comparator. [Check out the code](https://github.com/vitessio/vitess/blob/master/go/vt/sqlparser/ast_equals.go)

4. We also need to be able to do a deep-clone of the AST. While exploring different alternative plans, we clone parts of the AST, so we can change it without changing the original. [Check out the code](https://github.com/vitessio/vitess/blob/master/go/vt/sqlparser/ast_clone.go)

5. Finally, our AST knows how to print itself. 
This is a little trickier than you might think, because we do precedence calculations for expressions to figure out where we need parenthesis. 
To make this easy to write, we use something that looks a lot like printf - this allows us developers to write nicely readable code.
Unfortunately, this is not very fast, since it basically means that we have to parse strings to be able to produce strings.
Again, using the go/packages library, we can read the astPrintf lines, and then output a faster form of the same.
The method that a developer would write would look something like:

```golang
func (node *ComparisonExpr) Format(buf *TrackedBuffer) {
	buf.astPrintf(node, "%l %s %r", node.Left, node.Operator.ToString(), node.Right)
	if node.Escape != nil {
		buf.astPrintf(node, " escape %v", node.Escape)
	}
}
```

After code generation, the output becomes:
```golang
func (node *ComparisonExpr) formatFast(buf *TrackedBuffer) {
	buf.printExpr(node, node.Left, true)
	buf.WriteByte(' ')
	buf.WriteString(node.Operator.ToString())
	buf.WriteByte(' ')
	buf.printExpr(node, node.Right, false)
	if node.Escape != nil {
		buf.WriteString(" escape ")
		buf.printExpr(node, node.Escape, true)
	}
}
```

### How to make it work

One learning we have had, is that it's a good idea to hide the generated code behind an easy-to-use API.
That is the method that the rest of the code base will interact with, not directly with the generated code.
This gives us the chance to drastically change what the generated code looks like, but not have to change anything else in the code base.
We use this pattern for the [parser](https://github.com/vitessio/vitess/blob/master/go/vt/sqlparser/parser.go), for the [rewriter](https://github.com/vitessio/vitess/blob/master/go/vt/sqlparser/rewriter_api.go), and for the [visitor](https://github.com/vitessio/vitess/blob/master/go/vt/sqlparser/ast_funcs.go#L37).

### Summary
We use code generation for two main reasons. 
We are easily bored people, so writing lots of repetitive code would be no fun. 
This code would be difficult to write correctly, and annoying to review.
Using meta programming, we can avoid the repetitive code that is hard to get right and easy to mess up.

The second reason is that it's just easier to write fast code this way. 
We benchmark and profile the generated code pretty hard, and make sure to squeeze as much juice as possible.
Then we change the generator, and wham! 642 rewriter methods have been updated. 
This would not really have been possible if we had to change those methods manually.

Honorable mention:
Most of this code is either written by, or heavily influenced by the latest rockstar to join the PlanetScale and Vitess ranks - [@vmg](http://github.com/vmg)G
