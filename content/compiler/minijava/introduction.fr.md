+++
title = "Introduction"
weight = 20
+++

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


<!-- Pour reprendre la description donnée par [Andrew W. Appel](https://www.cs.princeton.edu/~appel/) dans -->
<!-- une annexe de son livre [*Modern Compiler Implementation in Java*](https://www.cs.princeton.edu/~appel/modern/), on a : -->

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

Nous allons maintenant décrire les différentes étapes de la figure ci-dessus.\
Pour suivre les démos dans les différentes vidéos qui vont suivre, commencer par installer les dépendances comme indiqué [ici](https://github.com/lascar-pacagi/MiniJava/blob/master/README.md).
Télécharger ensuite le code en faisant

{{< highlight git >}}
git clone --recurse-submodules git@github.com:lascar-pacagi/MiniJava.git
cd MiniJava
git checkout v1.0
make
{{< /highlight >}}

La branche `master` est la version avec le ramasse miettes et le tag `v1.0` est une version sans ramasse miettes.
Si vous voulez apporter des modifications à la version 1.0, vous
pouvez créer une nouvelle branche (`from_v1.0` par exemple) en faisant

{{< highlight git >}}
git checkout -b from_v1.0 v1.0
{{< /highlight >}}

Le code que je vais utiliser pendant les démos se trouve ci-dessous.

{{% attachments /%}}


### Analyse lexicale

La première étape est l'analyse lexicale qui va permettre de découper un flot de caractères en mots. Ces mots sont appelés unités lexicales. On obtient alors une information
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

Dans la vidéo suivante, nous allons donner une vue d'ensemble du transpileur, et nous présenterons l'analyseur lexical de MiniJava.

{{< youtube DaSCO7JwpGU >}}

### Analyse syntaxique

La deuxième étape, l'analyse syntaxique, prend en entrée le flot d'unités lexicales et va construire un arbre syntaxique abstrait permettant de représenter la structure du
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

L'analyse syntaxique a besoin de connaître la structure d'un programme MiniJava.
Cette structure est donnée sous la forme d'une grammaire.
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

La vidéo suivante va présenter l'analyseur syntaxique de MiniJava.

{{< youtube xUatwjMbjYk >}}

### Typage

La troisième étape, l'analyse de types, va prendre en entrée l'arbre abstrait et va vérifier si le typage est correct. Par exemple, on va vérifier qu'on utilise les méthodes
avec le bon nombre de paramètres, que les opérateurs `+` et `*` sont utilisés avec des opérandes entières, qu'une classe est compatible avec une autre via la relation d'héritage, ...

La vidéo suivante va présenter une vue d'ensemble du typage dans MiniJava.

{{< youtube mz0kVQd0rXY >}}

### Génération de code

La dernière étape va consister à générer le code en C. On va de nouveau parcourir l'arbre syntaxique abstrait pour générer ce code.
Pour notre [example](#minijava_introduction_prog), on obtient le fichier C ci-dessous.

{{< highlight c >}}
#include <stdio.h>
int main(int argc, char *argv[]) {
  printf("%d\n", ((35 + (2 * 3)) + 1));
  return 0;
}
{{< /highlight >}}

La vidéo suivante va décrire succinctement la génération de code C dans MiniJava.

{{< youtube 4wsr3Zr1vjs >}}

## Sémantique de MiniJava

La sémantique de MiniJava est donnée par sa sémantique en tant que programme Java ^[Voir [ici](https://docs.oracle.com/javase/specs/) pour la sémantique du langage Java.]. Les principales restrictions sont

* Les classes n'héritent pas de la classe `Object`.
* Le mot clé `super` n'existe pas.
* Il y a simplement un constructeur par défaut.
* Les seuls types autorisés sont,
 * `int`.
 * `boolean`.
 * `int[]`.
 * Les classes définies par l'utilisateur.
* La surcharge d'opérateurs n'est pas autorisée.
* L'instruction `System.out.printl()` ne peut imprimer que des entiers.
* Toutes les méthodes doivent retourner une valeur.
* Il n'y a pas d'interface, d'exception, de généricité, de lambda.

Nous expliquons dans la vidéo suivante les principales différences entre MiniJava et Java.

{{< youtube tNKBDxaML8c >}}

Nous avons décrit rapidement l'initialisation par défaut en Java (et MiniJava) dans la vidéo. Nous apportons quelques précisions ci-dessous.
Vous pouvez regarder [ici](https://docs.oracle.com/javase/specs/jls/se12/html/jls-4.html#jls-4.12.5) pour tous les détails.

Soit le programme Java `Init.java` suivant.

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

Si on le compile, on obtient les messages d'erreur suivants.

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

En effet, les trois variables `i`, `b` et `a` sont situées sur la pile, et leurs valeurs
vont dépendre des valeurs qui sont situées sur la pile lors de l'appel du `main`. Java n'initialisant
pas les variables locales avec une valeur par défaut, le compilateur refuse le programme en nous indiquant
que l'on cherche à utiliser des variables non initialisées.

Par contre, le programme suivant est correct car les attributs ont des valeurs par défaut.

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

Et on obtient la sortie suivante.

{{< highlight bash >}}
$ javac Init.java
$ java Init
0 false null
{{< /highlight >}}

## Rappels sur la liaison dynamique en Java

Nous allons faire quelques rappels sur la liaison dynamique en Java dans la vidéo ci-dessous, car la gestion
de la liaison dynamique sera un des points difficiles à gérer dans notre transpileur.

{{< youtube zYWyqyrNSOs >}}

## Questions

Reprenons la [grammaire de MiniJava](/fr/compiler/minijava/grammar.xhtml).
Nous voudrions ajouter la possibilité d'avoir

* L'opérateur de comparaison `==`.
* Des constructeurs.
* Des constructeurs et méthodes `private`.

{{%expand "Quelles sont les modifications à apporter à cette grammaire pour incorporer ces nouveaux éléments ?" %}}
[Grammaire de MiniJava modifiée](/fr/compiler/minijava/grammar_private_constructor_equality.xhtml).
{{% /expand%}}

---

{{%expand "Dans la question précédente, quels terminaux avez-vous dû ajouter à la grammaire (un terminal dans la grammaire deviendra une unité lexicale) ?" %}}
`==` et `private`.
{{% /expand%}}

---

Soit le programme Java suivant.

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


{{%expand "Ce code compile-t-il ?" %}}
Ce code ne compile pas. En effet, à la ligne 9, la méthode `m1` est une redéfinition de la
méthode `m1` de la ligne 2 : elle à le même nom et les mêmes paramètres. Par contre, pour être
une redéfinition correcte, il aurait fallu que le type de retour `boolean` soit compatible avec
le type de retour `int`, mais ce n'est pas le cas.
{{% /expand%}}

---

Soit le programme Java suivant.

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


{{%expand "Ce code compile-t-il ?" %}}
Ce code ne compile pas. En effet, le type de retour ne permet pas de différentier deux méthodes. Donc
même si les méthodes aux lignes 2 et 6 ont des types de retour différents, comme elles se nomment pareil et ont les
mêmes paramètres, on a pas une surcharge et il y a donc une erreur.
{{% /expand%}}

---

Soit le programme Java suivant.

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


{{%expand "Ce code compile-t-il ?" %}}
Ce code compile. Cette fois-ci, la méthode à la ligne 6 est bien une surcharge de la méthode
à la ligne 2 car le paramètre est d'un type différent.
{{% /expand%}}


## Ressources

{{% notice info %}}
[Cours sur Java de Coursera partie 1](https://www.coursera.org/learn/initiation-programmation-java)\
[Cours sur Java de Coursera partie 2](https://www.coursera.org/learn/programmation-orientee-objet-java)\
[Cours sur Java de Coursera partie 3](https://www.coursera.org/learn/projet-programmation-java)\
[Cours sur Java de Princeton](https://introcs.cs.princeton.edu/java/home/)\
[Spécifications du langage Java](https://docs.oracle.com/javase/specs/)\
[Page de MiniJava](http://www.cambridge.org/resources/052182060X/)\
[Diagramme syntaxique de MiniJava](/fr/compiler/minijava/grammar.xhtml)\
[Cours sur le langage C partie 1](https://www.edx.org/v2/course/c-programming-language-foundations)\
[Cours sur le langage C partie 2](https://www.edx.org/v2/course/modular-programming-and-memory-management)\
[Cours sur le langage C partie 3](https://www.edx.org/v2/course/programming-in-c-pointers-and-memory-management)\
[Cours sur le langage C partie 4](https://www.edx.org/v2/course/c-programming-advanced-data-types)\
[Apprendre le C en construisant un Lisp](http://www.buildyourownlisp.com/)\
[Cours sur le C moderne](https://modernc.gforge.inria.fr/)\
[Spécifications du langage C (norme C11)](http://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf)
{{% /notice %}}