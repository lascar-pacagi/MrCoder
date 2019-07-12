+++
title = "MiniJava"
weight = 10
chapter = true
tags = ["compilation", "transpileur", "ramasse miettes", "langage à objets", "MiniJava", "C", "OCaml", "Menhir", "Bash"]
+++

# MiniJava

Le compilateur que nous allons étudier dans cette partie est un transpileur permettant de passer du langage [MiniJava](http://www.cambridge.org/resources/052182060X/)
au langage [C](https://fr.wikipedia.org/wiki/C_(langage)). Il sera réalisé en en [OCaml](https://ocaml.org/index.fr.html) en utilisant
[Menhir](http://gallium.inria.fr/~fpottier/menhir/menhir.html.fr) pour l'analyse syntaxique.