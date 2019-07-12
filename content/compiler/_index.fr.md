+++
title = "Compilation"
disableNextPrev = true
+++
De manière abstraite, un compilateur est un programme qui transforme un fichier d'entrée contenant une certaine représentation en un fichier
de sortie contenant une autre représentation.

{{<mermaid align="center">}}
graph LR;
subgraph fichier d'entrée
A[Représentation A]
end
A[Représentation A] --> C(fa:fa-tools Compilateur)
C --> B
subgraph fichier de sortie
B[Représentation B]
end
{{< /mermaid >}}

Généralement, le fichier d'entrée sera un fichier contenant un langage de programmation (fichier en langage C par exemple) et le fichier de sortie sera un fichier contenant
une représentation exécutable directement par la machine (avec l'aide du système d'exploitation) ou par une machine virtuelle.
Un compilateur va généralement produire plusieurs représentations intermédiaires avant de produire la représentation finale. Le compilateur pourra effectuer, selon le langage source,
de l'analyse statique de types pour essayer de détecter des erreurs avant l'exécution du programme et pourra transformer le programme source, sans changer sa sémantique, en un code
plus efficace que ce que l'utilisateur avait écrit : cette transformation est appelée optimisation.

* Dans la partie [**MiniJava**]({{%relref "compiler/minijava/_index.md" %}}) nous allons étudier une sorte de compilateur qui se nomme transpileur, aussi appelé compilateur source à source, dans lequel la représentation d'entrée
sera un langage de programmation (le langage [MiniJava](http://www.cambridge.org/resources/052182060X/)), et la représentation de sortie sera elle aussi un langage de
programmation (le langage [C](https://fr.wikipedia.org/wiki/C_(langage))).
Nous pourrons ainsi profiter de l'existence d'un compilateur pour le langage C et nous
concentrer seulement sur l'analyse statique du fichier source et sur la génération en C des éléments liés à l'orientation objet.\
Ce premier compilateur nous permettra de rentrer plus en douceur dans le domaine de la compilation tout en montrant une approche très pratique pour écrire plus rapidement un compilateur
sans avoir à se soucier de la difficulté de générer du code machine optimisé pour une architecture particulière.
