+++
title = "Analyse lexicale"
weight = 30
+++

{{<mermaid align="center">}}
graph LR;
A[source en MiniJava] -->|caractères| B(fa:fa-tools<br/> Analyse <br/> lexicale)
B -->|unités lexicales| C(fa:fa-tools <br/> Analyse <br/> syntaxique)
C -->|arbre syntaxique abstrait| D(fa:fa-tools <br/> Analyse <br/> de types)
D -->|arbre syntaxique abstrait| E(fa:fa-tools <br/> Générateur <br/> de code C)
E -->|caractères| F[source en C]

classDef green fill:#74B559,stroke:#222723,stroke-width:5px;
class B green
{{< /mermaid >}}


## Expressions régulières

## Analyseur lexical

## Vidéos

## Questions

## Ressources