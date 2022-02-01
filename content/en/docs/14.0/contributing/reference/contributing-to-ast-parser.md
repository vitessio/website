---
title: Parser and AST
description: Everything you need to know to contribute to parser and AST of Vitess
---

Vitess houses its own SQL parser that is used to parse the queries users send us both at Vtgate and Vttablet. The output of the parser is stored in a Abstract Syntax Tree which is used for further processing by the planner. 

The code for the parser and AST lives [here](https://github.com/vitessio/vitess/tree/main/go/vt/sqlparser).

## Parser

Vitess uses a yacc-based parser. To convert the [yacc file](https://github.com/vitessio/vitess/blob/main/go/vt/sqlparser/sql.y) to executable [go file](https://github.com/vitessio/vitess/blob/main/go/vt/sqlparser/sql.go), run the following command in the root Vitess directory.
```bash
make parser
```

The tests for the parser live in the file [parse_test.go](https://github.com/vitessio/vitess/blob/main/go/vt/sqlparser/parse_test.go). In case any change is made to the parser, a corresponding test should be added to the test file.


## AST

The code for the Abstract Syntax Tree lives in the file [ast.go](https://github.com/vitessio/vitess/blob/main/go/vt/sqlparser/ast.go). The formatting functions for these structs live in the file [ast_format.go](https://github.com/vitessio/vitess/blob/main/go/vt/sqlparser/ast_format.go). Any additional functions for the AST structs reside in the file [ast_funcs.go](https://github.com/vitessio/vitess/blob/main/go/vt/sqlparser/ast_funcs.go).

Vitess also uses some generated code for creating functions used to clone the AST, compare its equality etc. If any change is made to any of the AST structs or their formatting functions, then the following command should be run in the root Vitess directory to update all the generated files.
```bash
make codegen
```
