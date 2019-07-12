+++
title = "Introduction"
weight = 20
+++

## Description de MiniJava

Nous allons réaliser un transpileur, ou compilateur source à source, pour un sous-ensemble du langage [Java](https://fr.wikipedia.org/wiki/Java_(langage)), le langage
[MiniJava](http://www.cambridge.org/resources/052182060X/). La représentation d'entrée pour notre compilateur sera donc le langage MiniJava. La représentation en sortie
de notre compilateur sera le langage [C](https://fr.wikipedia.org/wiki/C_(langage)).\
Une exemple de programme permettant de calculer une [factorielle](https://fr.wikipedia.org/wiki/Factorielle)
est donné ci-dessous.

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
Comme Minijava est un sous-ensemble de Java, nous pourrons compiler nos fichiers MiniJava en utilisant le compilateur Java ```javac``` ce qui sera pratique pour tester la validité
de nos traductions en langage C. En effet, nous pourrons comparer la sortie du programme obtenu en utilisant le compilateur Java, avec la sortie obtenue par l'exécutable obtenu
grâce à notre transpileur.
{{% /notice %}}

La grammaire de MiniJava, dans sa forme [EBNF](https://fr.wikipedia.org/wiki/Extended_Backus-Naur_Form)
est donnée ci-dessous. Une version sûrement plus lisible pour nous en [diagramme syntaxique](https://fr.wikipedia.org/wiki/Diagramme_syntaxique) est donnée
[ici](/fr/compiler/minijava/grammar.xhtml).^[La description de la grammaire qui permet de générer le diagramme ne suit pas strictement la forme EBNF. Les détails sont donnés [ici](https://www.w3.org/TR/xml/#sec-notation).]

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

Pour reprendre la description donnée par [Andrew W. Appel](https://www.cs.princeton.edu/~appel/) dans
une annexe de son livre [*Modern Compiler Implementation in Java*](https://www.cs.princeton.edu/~appel/modern/), on a :

* La sémantique de MiniJava est donnée par sa sémantique en tant que programme Java.
* La surcharge d'opérateurs n'est pas autorisée dans MiniJava.
* L'instruction `System.out.printl()` ne peut imprimer que des entiers.
* L'expression MiniJava `e.length` ne s'applique qu'à des expressions de type `int[]`.

## Vue d'ensemble du transpileur

Nous allons considérer le programme MiniJava suivant pour illustrer cette section.
<a name="minijava_introduction_prog"></a>
{{< highlight java >}}
class Print42 {
    public static void main(String[] a) {
            System.out.println(35 + 2 * 3 + 1);
    }
}
{{< /highlight >}}

La figure suivante montre les différentes étapes permettant de passer du fichier source en MiniJava au fichier source transpilé en C.

{{<mermaid align="center">}}
graph LR;
A[source en MiniJava] -->|caractères| B(fa:fa-tools<br/> Analyse <br/> lexicale)
B -->|unités lexicales| C(fa:fa-tools <br/> Analyse <br/> syntaxique)
C -->|arbre syntaxique abstrait| D(fa:fa-tools <br/> Analyse <br/> de types)
D -->|arbre syntaxique abstrait| E(fa:fa-tools <br/> Générateur <br/> de code C)
E -->|caractères| F[source en C]
{{< /mermaid >}}



* La première étape est l'analyse lexicale qui va permettre de découper un flot de caractères en mots. Ces mots sont appelés unités lexicales. On obtient alors une information
plus structurée où les mots clés du langage, les identifiants, les entiers et les booléens ont été identifiés. Cette phase va aussi nous permettre de supprimer les commentaires et
les blancs (espaces et retours à la ligne).\
Pour le programme [ci-dessus](#minijava_introduction_prog), l'analyse lexicale va produire le flot d'unités lexicales suivantes. On peut voir, par exemple, que le mot clé `CLASS`
a été identifié, que la constante entière `INT_CONST 35` aussi.

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

* La deuxième étape, l'analyse syntaxique, prend en entrée le flot d'unités lexicales, et va construire un arbre syntaxique abstrait permettant de représenter la structure du
programme sous la forme d'un arbre.\
Pour le programme [ci-dessus](#minijava_introduction_prog), on obtient l'arbre suivant. On peut y voir, par exemple, l'expression arithmétique avec de manière explicite la priorité
des opérateurs (plus c'est bas dans l'arbre et plus c'est prioritaire).

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

* La troisième étape, l'analyse de types, va prendre en entrée l'arbre abstrait et va vérifier si le typage est correct. Par exemple, on va vérifier qu'on utilise les méthodes
avec le bon nombre de paramètres, que les opérateurs `+` et `*` sont utilisés avec des opérandes entières, qu'une classe est compatible avec une autre via la relation d'héritage, ...

* La dernière étape va consister à générer le code en C. On va de nouveau parcourir l'arbre syntaxique abstrait pour générer ce code.
Pour notre [example](#minijava_introduction_prog), on obtient le fichier C ci-dessous.

{{< highlight c >}}
#include <stdio.h>
int main(int argc, char *argv[]) {
  printf("%d\n", ((35 + (2 * 3)) + 1));
  return 0;
}
{{< /highlight >}}

## Vidéo

<!-- {{< youtube qKUGR93h0y8 >}} -->

## Questions

## Ressources

{{% notice info %}}
TO DO
{{% /notice %}}