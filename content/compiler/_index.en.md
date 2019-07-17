+++
title = "Compiler"
draft =  "false"
+++

Abstractly a compiler is a program that takes as input a representation of some sort and transforms this representation into another one as its output.

{{<mermaid align="center">}}
graph LR;
subgraph input file
A[Representation A]
end
A[Representation A] --> C(fa:fa-tools Compiler)
C --> B
subgraph output file
B[Representation B]
end
{{< /mermaid >}}

Usually, the input file contains a programming language source (a C source file for example) and the output file contains an executable file for the target machine or
for a virtual machine.
A compiler generally produces different kind of intermediate representations before producing the final representation. The compiler can, depending on the source language,
some static analysis to detect some errors before the execution of the program. The compiler can transform the source program, without modifying its semantic, into a more
efficient code : this transformation is called optimisation.

* In the [**MiniJava**]({{%relref "compiler/minijava/_index.md" %}}) part, we will study a kind of compiler, a transpiler or source to source compiler, for which the input
representation will be a programming language (the [MiniJava language](http://www.cambridge.org/resources/052182060X/)) and the output representation will be another programming
language ([the C language](https://en.wikipedia.org/wiki/C_%28programming_language%29)). In this way, we will be able to take advantage of the presence of a C compiler and focus
only on the static type checking and the generation in C of the object orienting part of MiniJava.\
This first compiler will be an easier step into compilation but still will be a very practical approach to compilation because we will produce quickly a compiler
without the hard part of generating optimized machine code for a given architecture.
