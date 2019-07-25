+++
title = "MiniJava"
weight = 10
chapter = true
tags = ["compiler", "transpiler", "garbage collector", "object oriented language", "MiniJava", "C", "OCaml", "Menhir", "Bash"]
+++

# MiniJava

The compiler we study in this part is a transpiler that goes from the [MiniJava](http://www.cambridge.org/resources/052182060X/) language
to the [C](https://en.wikipedia.org/wiki/C_%28programming_language%29) language. We will construct this transpiler using the
[OCaml](https://ocaml.org/) language and [Menhir](http://pauillac.inria.fr/~fpottier/menhir/menhir.html.en) for the syntactic analysis.\
To download the code : `git clone --recurse-submodules git@github.com:lascar-pacagi/MiniJava.git`.