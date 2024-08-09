---
title: Sample First Issue
description: Walkthrough on how to fix an issue in Vitess and create a pull request.
weight: 6
---

After having Vitess locally setup for development, you can go ahead and choose an issue to work on from [here](https://github.com/vitessio/vitess/issues).
For first time contributors, some of the issues have been marked with the label *Good First Issue*. These can be found [here](https://github.com/vitessio/vitess/issues?q=is%3Aissue+is%3Aopen+label%3A%22Good+First+Issue%22).  
For this walkthrough, we will pick issue [#4069](https://github.com/vitessio/vitess/issues/4069).
Let us dive right in!

The issue is that Vitess's parser does not support parsing a string literal that starts with a number. 
The first thing to do is to reproduce the error as a unit test.
Since it is a parsing error, we can add a unit test for it in the [parse_test.go](https://github.com/vitessio/vitess/blob/main/go/vt/sqlparser/parse_test.go) file. More information on how to contribute to the AST parser is available [here](../contributing-to-ast-parser).  
We can add this to **TestValid** by adding an additional test case to the *validSQL* list -
```go
{
	input:  "create table 3t2 (c1 bigint not null, c2 text, primary key(c1))",
	output: "create table 3t2 (\n\tc1 bigint not null,\n\tc2 text,\n\tprimary key (c1)\n)",
}
```
By running the test, we can verify that indeed the test fails.
We can commit this change.

On further exploration and debugging in GoLand, the problem is traced to the tokenizer which does not parse the token *3t2* correctly. 
It should return an **ID** token, but it returns an error.  
Once we know this, we can go ahead and add another unit test for the tokenizer in the [token_test.go](https://github.com/vitessio/vitess/blob/main/go/vt/sqlparser/token_test.go) file. 
In order to do so, it is essential to try out different permutations and combinations in vanilla MySQL to know the correct behaviour. 
For example, we know that *3t2* should be parsed as an ID, but what about *3.2t3*, *3e3t3* or *0x2t3*.
Once we try these out, we can go ahead and add another unit test -
```go
func TestIntegerAndID(t *testing.T) {
	testcases := []struct {
		in  string
		id  int
		out string
	}{{
		in: "334",
		id: INTEGRAL,
	}, {
		in: "33.4",
		id: FLOAT,
	}, {
		in: "0x33",
		id: HEXNUM,
	}, {
		in: "33e4",
		id: FLOAT,
	}, {
		in: "33.4e-3",
		id: FLOAT,
	}, {
		in: "33t4",
		id: ID,
	}, {
		in: "0x2et3",
		id: ID,
	}, {
		in:  "3e2t3",
		id:  LEX_ERROR,
		out: "3e2",
	}, {
		in:  "3.2t",
		id:  LEX_ERROR,
		out: "3.2",
	}}

	for _, tcase := range testcases {
		t.Run(tcase.in, func(t *testing.T) {
			tkn := NewStringTokenizer(tcase.in)
			id, out := tkn.Scan()
			require.Equal(t, tcase.id, id)
			expectedOut := tcase.out
			if expectedOut == "" {
				expectedOut = tcase.in
			}
			require.Equal(t, expectedOut, out)
		})
	}
}
```
We can commit this change or amend the previous one, and now focus on fixing the issue.


By looking at the code, we can immediately find that the issue is with the code that checks for a letter when we are scanning a number -  
```go
// A letter cannot immediately follow a number.
if isLetter(tkn.cur()) {
	return LEX_ERROR, tkn.buf[start:tkn.Pos]
}
```
We can fix this by replacing it by - 
```go
if isLetter(tkn.cur()) {
	// A letter cannot immediately follow a float number.
	if token == FLOAT {
		return LEX_ERROR, tkn.buf[start:tkn.Pos]
	}
	// A letter seen after a few numbers means that we should parse this
	// as an identifier and not a number.
	for {
		ch := tkn.cur()
		if !isLetter(ch) && !isDigit(ch) {
			break
		}
		tkn.skip(1)
	}
	return ID, tkn.buf[start:tkn.Pos]
}
```
We can now verify that our added unit test in *token_test.go* works perfectly and can commit this change.

From CLI -

1. Navigate to the SQL Parser Directory:
   - Change your current working directory to the `sqlparser` directory within `go/vt/`. Use the following command:

     ```bash
     cd go/vt/sqlparser/
     ```

2. Run the Tests:
   - Once you are in the `sqlparser` directory, execute the following command to run the tests:

     ```bash
     go test
     ```

As a final step, we run the *parse_test.go* file to ensure that everything works. We fix any tests whose expectations have changed or any incorrect tests to reflect the change and commit it.

With these changes, the issue is resolved! But our work is not yet complete...  

If the changes in the PR are significant enough to warrant adding a section for it in the release notes, then we should do that.
After that, we need to create a pull request for our changes and address any review comments. 
While creating the pull request, we need to take care of a few things -

1. Follow the existing template for pull requests
2. Add a description of what has been fixed
3. Add the label for the correct component affected by the changes. In our case that is `Component: Query Serving`.
4. Add the label for the type of changes in the PR. In our case that is `Type: Enhancement`.
5. Add the label describing whether this PR should be backported to some of the previous releases as well. For example, in order to back port to release 15.0 we use the label `Backport to: release-15.0`.
6. Codeowners will be automatically requested for reviews.

The final PR that has been created by following these steps would look like [this](https://github.com/vitessio/vitess/pull/9456).
