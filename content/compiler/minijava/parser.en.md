+++
title = "Syntactic Analysis"
weight = 40
mathjax = true
+++

{{<mermaid align="center">}}
graph LR;
A[MiniJava source file] -->|characters| B(fa:fa-tools<br/> Lexical <br/> analysis)
B -->|tokens| C(fa:fa-tools <br/> Syntactic <br/> analysis)
C -->|abstract syntax tree| D(fa:fa-tools <br/> Typechecker)
D -->|abstract syntax tree| E(fa:fa-tools <br/> C code <br/> generator)
E -->|characters| F[C source file]
classDef green fill:#74B559,stroke:#222723,stroke-width:5px;
class C green
{{< /mermaid >}}
