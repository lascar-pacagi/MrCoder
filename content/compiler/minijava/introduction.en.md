+++
title = "Introduction"
weight = 20
+++

We will build a transpiler, or source to source compiler, for a subset of [Java](https://en.wikipedia.org/wiki/Java_%28programming_language%29),
the [MiniJava](http://www.cambridge.org/resources/052182060X/) language. The input representation for our compiler is the MiniJava language and
the output representation is the [C](https://en.wikipedia.org/wiki/C_%28programming_language%29) language.\
A sample program which computes the [factorial](https://en.wikipedia.org/wiki/Factorial) of a given number is given below.

{{< highlight java >}}
class Factorial {
    public static void main(String[] a) {
         System.out.println(new Fac().computeFac(10));
    }
}

class Fac {
    public int computeFac(int num) {
        int numAux;
        if (num < 1) numAux = 1;
        else numAux = num * (this.computeFac(num-1));
        return numAux;
    }
}
{{< /highlight>}}

{{% notice tip %}}
As Minijava is a subset of Java, we will be able to compile our MiniJava programs using the Java compiler `javac`. This will be very usefull to test the validity of our translations in C.
Indeed, we will be able to compare the output of the program compiled with the Java compiler with the output of the program obtained by our transpiler.
{{% /notice %}}

## Overview of the Transpiler

We will use the following MiniJava program as a running example for this section.
<a name="minijava_introduction_prog"></a>
{{< highlight java >}}
class Print42 {
    public static void main(String[] a) {
            System.out.println(35 + 2 * 3 + 1);
    }
}
{{< /highlight >}}

The following figure shows the main steps to transform a MiniJava program to a transpiled C source file.

{{<mermaid align="center">}}
graph LR;
A[MiniJava source file] -->|characters| B(fa:fa-tools<br/> Lexical <br/> analysis)
B -->|tokens| C(fa:fa-tools <br/> Syntactic <br/> analysis)
C -->|abstract syntax tree| D(fa:fa-tools <br/> Typechecker)
D -->|abstract syntax tree| E(fa:fa-tools <br/> C code <br/> generator)
E -->|characters| F[C source file]
{{< /mermaid >}}

We will now describe the different steps shown on the figure above.\

To follow along with the videos that follow, start to install the dependencies as stated [here](https://github.com/lascar-pacagi/MiniJava/blob/master/README.md).
Then download the code

{{< highlight git >}}
git clone --recurse-submodules git@github.com:lascar-pacagi/MiniJava.git
cd MiniJava
git checkout v1.0
make
{{< /highlight >}}

The `master` branch is the version with a garbage collector and the tag `v1.0` is a version without a garbage collector.
If you want to modify the version 1.0, you can create a new branch (`from_v1.0` for example)

{{< highlight git >}}
git checkout -b from_v1.0 v1.0
{{< /highlight >}}

The code we use during the videos is given below.

{{% attachments /%}}

### Lexical Analysis

The first step is the lexical analysis. This phase will group characters into words. Those words are called tokens. After this step we get a more structured information where
the keywords of MiniJava, the identifiers, the integer constants and the boolean constants have been recognized. This is in this phase that commentaries and whitespaces are suppressed.\
For the program given [above](#minijava_introduction_prog), the `scanner`, the program responsible of the lexical analysis phase, will produce the following stream of tokens. For example,
we can see that the keyword `CLASS` has been recognized, as the integer constant `INT_CONST 35`.

{{< highlight bash >}}
CLASS
IDENT ‘Print42‘
LBRACE
PUBLIC
STATIC
VOID
MAIN
LPAREN
STRING
LBRACKET
RBRACKET
IDENT ‘a‘
RPAREN
LBRACE
SYSO
LPAREN
INT_CONST ‘35‘
PLUS
INT_CONST ‘2‘
TIMES
INT_CONST ‘3‘
PLUS
INT_CONST ‘1‘
RPAREN
SEMICOLON
RBRACE
RBRACE
EOF
{{< /highlight >}}

{{< youtube DaSCO7JwpGU >}}

### Syntactic Analysis

The second step, the syntactic analysis, takes as input the stream of tokens and produces an abstract syntax tree which represents the structure of the program with a tree
data structure.\
For the program given [above](#minijava_introduction_prog), the `parser`, the program responsible of the syntactic analysis phase, will produce the following tree. We can see
the arithmetic expression with the operators precedence explicitly stated (expressions deeper in the tree have more priority).

{{< highlight bash >}}
program
  ├name Print42
  ├main_args a
  └main
     └ISyso
        └EBinOp OpAdd
          ├EBinOp OpAdd
          │  ├EConst (ConstInt 35)
          │  └EBinOp OpMul
          │    ├EConst (ConstInt 2)
          │    └EConst (ConstInt 3)
          └EConst (ConstInt 1)
{{< /highlight >}}

The syntactic analyser needs to know the structure of a MiniJava program. This structure is given in the form of a grammar.
The MiniJava grammar, in its [EBNF](https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form) form is given below.
Another version, certainly easier to read for us, using [syntax diagrams](https://en.wikipedia.org/wiki/Syntax_diagram) is given [here](/fr/compiler/minijava/grammar.xhtml).^[The description of the grammar
used to generate the diagram does not follow exactly the EBNF form. Details are given [here](https://www.w3.org/TR/xml/#sec-notation).]

{{< highlight ebnf >}}
Program = MainClass { ClassDeclaration } 'eof' ;

MainClass = 'class' Identifier '{' 'public' 'static' 'void' 'main' '(' 'String' '[' ']' Identifier ')' '{' Statement '}' '}' ;

ClassDeclaration = 'class' Identifier [ 'extends' Identifier ] '{' { VarDeclaration } { MethodDeclaration } '}' ;

VarDeclaration = Type Identifier ';' ;

MethodDeclaration = 'public' Type Identifier '(' [ Type Identifier { ',' Type Identifier } ] ')' '{' { VarDeclaration } { Statement } 'return' Expression ';' '}' ;

Type = 'int' '[' ']'
        | 'boolean'
        | 'int'
        |  Identifier ;

Statement = '{' { Statement } '}'
        | 'if' '(' Expression ')' Statement 'else' Statement
        | 'while' '(' Expression ')' Statement
        | 'System.out.println' '(' Expression ')' ';'
        | Identifier '=' Expression ';'
        | Identifier '[' Expression ']' '=' Expression ';' ;

Expression = Expression ( '&&' | '<' | '+' | '-' | '*' ) Expression
        | Expression '[' Expression ']'
        | Expression '.' 'length'
        | Expression '.' Identifier '(' [Expression {',' Expression}] ')'
        | Integer
        | 'true'
        | 'false'
        | Identifier
        | 'this'
        | 'new' 'int' '[' Expression ']'
        | 'new' Identifier '(' ')'
        | '!' Expression
        | '(' Expression ')' ;

Letter = 'A' | 'B' | 'C' | 'D' | 'E' | 'F' | 'G'
       | 'H' | 'I' | 'J' | 'K' | 'L' | 'M' | 'N'
       | 'O' | 'P' | 'Q' | 'R' | 'S' | 'T' | 'U'
       | 'V' | 'W' | 'X' | 'Y' | 'Z' | 'a' | 'b'
       | 'c' | 'd' | 'e' | 'f' | 'g' | 'h' | 'i'
       | 'j' | 'k' | 'l' | 'm' | 'n' | 'o' | 'p'
       | 'q' | 'r' | 's' | 't' | 'u' | 'v' | 'w'
       | 'x' | 'y' | 'z' ;

Digit = '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' ;

Integer = Digit { Digit } ;

Character = Letter | Digit | '_' ;

Identifier = Letter { Letter | Digit | '_' } ;

{{< /highlight>}}

{{< youtube xUatwjMbjYk >}}

<!-- Pour reprendre la description donnée par [Andrew W. Appel](https://www.cs.princeton.edu/~appel/) dans -->
<!-- une annexe de son livre [*Modern Compiler Implementation in Java*](https://www.cs.princeton.edu/~appel/modern/), on a : -->

### Typechecker

The third step, the typechecker, takes as input the abstract syntax tree and will check if the types are correct. For example, the typechecker will check if we call
a method with the correct number of arguments, that the operators `+` and `*` are used with integer operands, that a class is compatible with another one using
the class hierarchy, ...

{{< youtube mz0kVQd0rXY >}}

### Code Generation

The last step is the code generator phase. We will again visit the abstract syntax tree to generate C code. For our [running example](#minijava_introduction_prog),
we get the following C source file.

{{< highlight c >}}
#include <stdio.h>
int main(int argc, char *argv[]) {
  printf("%d\n", ((35 + (2 * 3)) + 1));
  return 0;
}
{{< /highlight >}}

{{< youtube 4wsr3Zr1vjs >}}

### Semantic of a MiniJava Program

The semantic of a MiniJava program is given by its semantic as a Java program^[See [here](https://docs.oracle.com/javase/specs/) for the semantic of the Java language.].
The main restrictions are

* No class has `Object` as a superclass.
* No `super` keyword.
* Only a default constructor.
* The only types available are
  * `int`.
  * `boolean`.
  * `int[]`.
  * User defined classes.
* No overloading.
* All methods return a value. The `return` statement is at the end.
* `System.out.println()` only prints integers.
* No interfaces, no exceptions, no generic types, no lambdas.

We explain in the following video the main differences between Java and MiniJava.

{{< youtube tNKBDxaML8c >}}

We described briefly in the video the default initialization mechanism in Java (and MiniJava).
We give further details below. You can look [here](https://docs.oracle.com/javase/specs/jls/se12/html/jls-4.html#jls-4.12.5) for all the details.

Let's consider the following Java program `Init.java`.

{{< highlight java "linenos=inline">}}
class Init {
    public static void main(String[] args) {
        int i;
        boolean b;
        int[] a;
        System.out.println(i + " " + b + " " + a);
    }
}
{{< /highlight >}}

When we compile it, we get the following error messages.

{{< highlight bash >}}
$ javac Init.java
Init.java:6: error: variable i might not have been initialized
        System.out.println(i + " " + b + " " + a);
                           ^
Init.java:6: error: variable b might not have been initialized
        System.out.println(i + " " + b + " " + a);
                                     ^
Init.java:6: error: variable a might not have been initialized
        System.out.println(i + " " + b + " " + a);
                                               ^
3 errors
{{< /highlight >}}

Indeed, the three variables `i`, `b` and `a` are put on the stack when `main` is called. Java does not initialize
local variables, and their values are whatever was currently in those locations on the stack.
The compiler rejects this program because of the arbitrary values that go into those variables, by telling
us that those variables have not been initialized.

On the other hand, the following program is correct, because attributes have a default value.

{{< highlight java "linenos=inline">}}
class Init {
    public static void main(String[] args) {
        new Default().print();
    }
}

class Default {
    private int i;
    private boolean b;
    private int[] a;

    public void print() {
        System.out.println(i + " " + b + " " + a);
    }
}
{{< /highlight >}}

And we get the following output.

{{< highlight bash >}}
$ javac Init.java
$ java Init
0 false null
{{< /highlight >}}


### Review of Java's Dynamic Binding

We will review dynamic binding in Java in the following video, because the management of dynamic binding will
be one of the most difficult point to handle in our transpiler.

{{< youtube zYWyqyrNSOs >}}


## Questions

Let's have a look again at the [MiniJava grammar](/fr/compiler/minijava/grammar.xhtml).
We would like to add to the language

* The `==` operator.
* Constructors.
* `private` methods and constructors.

{{%expand "How to update the grammar to add those new elements?" %}}
[MiniJava grammar updated](/fr/compiler/minijava/grammar_private_constructor_equality.xhtml).
{{% /expand%}}

---

{{%expand "In the previous question, what terminals did you add to the grammar (a terminal in the grammar will become a token for the scanner)?"%}}
`==` and `private`.
{{% /expand%}}

---

Consider the following Java program.

{{< highlight java "linenos=inline">}}
class A {
    public int m1(int n) {
        System.out.println("int A:m1(int n)");
        return 0;
    }
}

class B extends A {
    public boolean m1(int n) {
        System.out.println("boolean B:m1(int n)");
        return false;
    }
}
{{< /highlight >}}


{{%expand "Does this code compile?" %}}
This code doesn't compile. Indeed, on line 9, the `m1` method overrides the `m1` method of line 2:
It has the same name and the same parameters. But to correctly overrides the `m1` method of line 2,
the return type must be compatible, and `boolean` is not compatible with `int`.
{{% /expand%}}

---

Consider the following Java program.

{{< highlight java "linenos=inline">}}
class A {
    public int m1(int n) {
        System.out.println("int A:m1(int n)");
        return 0;
    }
    public boolean m1(int n) {
        System.out.println("boolean A:m1(int n)");
        return false;
    }
}
{{< /highlight >}}


{{%expand "Does this code compile?" %}}
This code doesn't compile. Indeed, the return type is not used to differentiate methods.
Therefore, even if the methods on lines 2 and 6 have different return types, because they have the same
name and the same parameters, this is not overloading and so we have an error.
{{% /expand%}}

---

Consider the following Java program.

{{< highlight java "linenos=inline">}}
class A {
    public int m1(A a) {
        System.out.println("int A:m1(A a)");
        return 0;
    }
    public boolean m1(B b) {
        System.out.println("boolean A:m1(B b)");
        return false;
    }
}

class B extends A {
}
{{< /highlight >}}


{{%expand "Does this code compile?" %}}
This code compiles. This time, the method on line 6 overloads the method on line 2 because the parameter
is of a different type.
{{% /expand%}}


## Ressources

{{% notice info %}}
[Java language course from Princeton](https://introcs.cs.princeton.edu/java/home/)\
[Java language course from Microsoft](https://www.edx.org/professional-certificate/microsoft-introduction-to-code-objects-and-algorithms)\
[Java language specifications](https://docs.oracle.com/javase/specs/)\
[MiniJava page](http://www.cambridge.org/resources/052182060X/)\
[MiniJava syntactic diagram](/fr/compiler/minijava/grammar.xhtml)\
[C language course part 1](https://www.edx.org/v2/course/c-programming-language-foundations)\
[C language course part 2](https://www.edx.org/v2/course/modular-programming-and-memory-management)\
[C language course part 3](https://www.edx.org/v2/course/programming-in-c-pointers-and-memory-management)\
[C language course part 4](https://www.edx.org/v2/course/c-programming-advanced-data-types)\
[Learn C by building a Lisp](http://www.buildyourownlisp.com/)\
[C language specifications (C11 norm)](http://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf)
{{% /notice %}}