+++
title = "MrCoder"
disableNextPrev = true
+++

# **MrCoder**
"C'est en forgeant qu'on devient forgeron" (french proverb)
___

## Goal

This little corner of the web is dedicated to learn computer science by coding stuff.
We will go together, step by step, through different themes of computer science, building along the way softwares to
thoroughly understand the different subjects.
I hope this will be helpful for some of you and that you will have fun learning.

## Site structure

I will use text, videos and code to explain the different subjects:

* Videos are in french with english subtitles.
* Code is on [github](https://github.com/lascar-pacagi).

Go to the left panel or look at the themes below to choose your subject and let's dive into the vast and beautiful world of computer science!

## Subjects overview
* [**MiniJava transpiler**]({{%relref "compiler/minijava/_index.md" %}})
 * We transform a [MiniJava](http://www.cambridge.org/resources/052182060X/#java) source file, which is a subset of [Java](https://en.wikipedia.org/wiki/Java_(langage)),
 into a [C](https://en.wikipedia.org/wiki/C_%28programming_language%29) source file. We then use [gcc](https://gcc.gnu.org/) to translate the C file into an executable one.\
 To do this transpiling, we first do a lexical analysis of the MiniJava source file, then a syntax analysis, then we typecheck the code and finally, we generate a C source file
 from the abstract syntax tree of MiniJava. The most difficult parts for the code generation are the class and dynamic binding representations and the inclusion of a garbage collector.\
 The transpiler is written in [OCaml](https://ocaml.org/) using [Menhir](http://gallium.inria.fr/~fpottier/menhir/menhir.html.en) for the parser.
