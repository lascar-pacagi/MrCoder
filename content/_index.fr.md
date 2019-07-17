+++
title = "MrCodeur"
disableNextPrev = true
+++

# **MrCodeur**
"C'est en forgeant qu'on devient forgeron"
___

## Objectif

Ce petit coin du web est dédié à l'apprentissage de l'informatique avec pour principe de coder pour apprendre. Nous parcourrons
ensemble, pas à pas, différents thèmes de l'informatique, construisant tout au long des logiciels pour comprendre en profondeur les différents sujets.
J'espère que ce site sera utile pour certains d'entre vous et que vous vous amuserez tout en apprenant.

## Structure du site

Je vais utiliser du texte, des vidéos et du code pour expliquer les différents sujets:

* Les vidéos seront en français avec des sous-titres anglais.
* Le code sera sur [github](https://github.com/lascar-pacagi).

Choisissez votre sujet sur le panneau de gauche ou parmis les thèmes ci-dessous, et nous allons pouvoir commencer à explorer ensemble le monde vaste et passionnant
de l'informatique !

## Thèmes abordés
* [**MiniJava transpileur**]({{%ref "/compiler/minijava/_index.md" %}})
 * Nous transformons un fichier source contenant un programme écrit dans un sous-ensemble du langage [Java](https://fr.wikipedia.org/wiki/Java_(langage)),
le langage [MiniJava](http://www.cambridge.org/resources/052182060X/), en un fichier en langage [C](https://fr.wikipedia.org/wiki/C_(langage)). Nous utilisons
ensuite [gcc](https://gcc.gnu.org/) pour traduire le fichier en langage C en un fichier exécutable.\
Pour effectuer cette transpilation, nous faisons d'abord une analyse lexicale du fichier source, puis une analyse syntaxique, puis une vérification du typage (analyse statique)
et enfin une génération du code C à partir de l'arbre syntaxique abstrait de MiniJava. Les difficultés principales pour la génération du code C sont la représentation des classes,
l'implémentation de la liaison dynamique et l'ajout du ramasse miettes.\
Le transpileur est écrit en [OCaml](https://ocaml.org/index.fr.html) en utilisant [Menhir](http://gallium.inria.fr/~fpottier/menhir/menhir.html.fr) pour l'analyse syntaxique.