+++
title = "Analyse lexicale"
weight = 30
mathjax = true
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

Nous allons décrire l'analyseur lexical de MiniJava qui va permettre de découper les caractères
du fichier source en unités lexicales. Ces unités lexicales seront ensuite utilisées par l'analyseur
syntaxique.\
Avant de décrire cet analyseur lexical, nous allons présenter les expressions régulières qui seront utilisées
pour décrire les unités lexicales. Nous étudierons aussi les automates qui permettront d'implémenter
la reconnaissance des expressions régulières.
<a name="regular_expressions"></a>
## Expressions régulières

Les expressions régulières vont nous permettre de décrire succintement et assez intuitivement
les unités lexicales de MiniJava et seront utilisées dans le générateur d'analyseur lexical `ocamllex` que nous
allons utiliser dans notre transpiler.

### Définition

Une expression régulière va décrire un ensemble de mots sur un vocabulaire donné. Nous allons prendre comme exemple
le vocabulaire $\mathcal{V} = \\{0, 1\\}$ constitué simplement de deux éléments : `0` et `1`. Nous décrivons ci-dessous de manière
informelle les éléments de base et les opérateurs permettant de créer des expressions régulières et les mots qu'elles
décrivent.\

* Expressions régulières de base :

 * L'expression régulière $\color{green}\epsilon$ génère l'ensemble contenant simplement le mot vide^[Le mot vide est l'équivalent de la chaîne de caractères `""`.]: $\\{\epsilon\\}$.
 * Pour $c \in \mathcal{V}$, l'expression régulière $\color{green}c$ représente l'ensemble contenant un seul mot : $\\{c\\}$.
<!--  <style> -->
<!-- table { -->
<!--     width:50%; -->
<!-- } -->
<!-- </style> -->

        | <center>Expression</center> | <center>Ensemble de mots</center> |
        | :----------------:          | :----------------:                |
        | $\color{green}0$            | $\\{0\\}$                         |
        | $\color{green}1$            | $\\{1\\}$                         |

* Expressions régulières composées :

 * On peut utiliser des parenthèses pour regrouper des expressions régulières. Soit $\color{green}{r}$ une expression régulière, alors $\color{green}{\(r\)}$ représente le même ensemble de
 mots que l'expression $\color{green}{r}$.

        | <center>Expression</center> | <center>Ensemble de mots</center> |
        | :----------------:          | :----------------:                |
        | $\color{green}{(0)}$ | $\\{0\\}$ |


 * L'opérateur de concaténation permet de juxtaposer les mots engendrés par deux expressions régulières. Soit $\color{green}{r\_1}$ et $\color{green}{r\_2}$ deux expressions régulières.
 La concaténation de ces deux expressions régulières est notée : $\color{green}{r\_1r\_2}$. L'ensemble des mots décrit par cette expression régulière est
 la concaténation des mots décrit par $\color{green}{r\_1}$ avec ceux décrit par $\color{green}{r\_2}$.\
 Notons que cet opérateur est associatif, c'est-à-dire que pour toute
 expression régulière $\color{green}{r\_1}$, $\color{green}{r\_2}$ et $\color{green}{r\_3}$, on a
 $\color{green}{(r\_1r\_2)r\_3} = \color{green}{r\_1(r\_2r\_3)}$ que l'on notera simplement $\color{green}{r\_1r\_2r\_3}$.


        | <center>Expression</center> | <center>Ensemble de mots</center> |
        | :----------------:          | :----------------:                |
        | $\color{green}{\epsilon1}$  | $\\{1\\}$                         |
        | $\color{green}{10}$         | $\\{10\\}$                        |
        | $\color{green}{(10)1}$         | $\\{101\\}$                        |
        | $\color{green}{1(01)}$         | $\\{101\\}$                        |
        | $\color{green}{101}$         | $\\{101\\}$                        |

 * L'opérateur d'union permet de faire l'union des mots engendrés par deux expressions régulières. Soit $\color{green}{r\_1}$ et $\color{green}{r\_2}$ deux expressions régulières.
 L'union de ces deux expressions régulières est notée : $\color{green}{r\_1 | \\ r\_2}$. L'ensemble des mots décrit par cette expression régulière est
 l'union des mots décrit par $\color{green}{r\_1}$ avec ceux décrit par $\color{green}{r\_2}$.\
 Notons que cet opérateur est commutatif, c'est-à-dire que
 $\color{green}{r\_1\\ |\\ r\_2} = \color{green}{r\_2\\ |\\ r\_1}$. Il est aussi associatif, c'est-à-dire que pour toute
 expression régulière $\color{green}{r\_1}$, $\color{green}{r\_2}$ et $\color{green}{r\_3}$, on a
 $\color{green}{(r\_1\\ |\\ r\_2)\\ |\\ r\_3} = \color{green}{r\_1\\ |\\ (r\_2\\ |\\ r\_3)}$ que l'on notera simplement $\color{green}{r\_1\\ |\\ r\_2\\ |\\ r\_3}$.



        | <center>Expression</center>  | <center>Ensemble de mots</center> |
        | :----------------:           | :----------------:                |
        | $\color{green}{\epsilon \\ \| \\ 1}$                            | $\\{\epsilon, 1\\}$ |
        | $\color{green}{(00) \\ \| \\ (10)}$                           | $\\{00, 10\\}$      |
        | $\color{green}{(10) \\ \| \\ (00)}$                           | $\\{00, 10\\}$      |
        | $\color{green}{(0 \\ \| \\ 1)\\ \|\\ (10)}$                           | $\\{0, 1, 10\\}$      |
        | $\color{green}{0\\ \|\\ (1 \\ \| \\ (10))}$                           | $\\{0, 1, 10\\}$      |
        | $\color{green}{0 \\ \| \\ 1\\ \|\\ (10)}$                           | $\\{0, 1, 10\\}$      |
        | $\color{green}{(0\\ \|\\ 1)(0\\ \|\\ 1)}$                           | $\\{00, 01, 10, 11\\}$      |

 * L'opérateur d'itération noté `*` permet de juxtaposer $0$ ou plusieurs fois les mots engendrés par une expression régulières. Soit $\color{green}{r}$ une expression régulière, alors
 l'expression régulière $\color{green}{r^*}$ représente l'hypothétique^[Une expression régulière doit être de taille finie.] expression régulière
 $\color{green}{\epsilon \\ |\\ r\\ |\\ rr\\ |\\ rrr\\ |\\ rrrr\\ |\\ \cdots}$.


        | <center>Expression</center> | <center>Ensemble de mots</center>          |
        | :----------------:          | :----------------:                         |
        | $\color{green}{0^*}$        | $\\{\epsilon, 0, 00, 000, 0000, \cdots\\}$ |
        | $\color{green}{(0\\ \| \\ 1)^*}$ | $\\{\epsilon, 0, 1, 00, 01, 10, 11, 000, 001, 010, 011, 100, \cdots\\}$ |


{{% notice note %}}
Pour éviter trop de parenthèses, il existe une priorité entre les différents opérateurs : les parenthèses ont la plus grande priorité,
ensuite l'opérateur $\color{green}{*}$, puis l'opérateur de concaténation et enfin l'opérateur $\color{green}{|}$. On a vu aussi ci-dessus que les opérateurs
de concaténation et d'union sont associatifs, ce qui nous permet de supprimer d'avantage de parenthèses.
Ainsi, l'expression régulière $\color{green}{10^*1\\ |\\ 11\\ |\\ \epsilon}$ se lit $\color{green}{(((1(0^ *))1)\\ |\\ (11))\\ |\\ \epsilon}$
{{% /notice %}}

### Examples

Nous donnons ci-dessous quelques examples d'expressions régulières toujours sur le vocabulaire $\mathcal{V} = \\{0, 1\\}$.

<!--  <style> -->
<!-- table { -->
<!--     width:100%; -->
<!-- } -->
<!-- </style> -->

| <center>Description</center>                                       | <center>Expression</center>           | <center>Ensemble de mots</center> |
| :----------------:                                                 | :----------------:                    | :----------------:                |
| Les nombres binaires (sans zéro non significatif)                  | $\color{green}{0\\ \| \\ 1(0\\ \| \\ 1)^*}$  | $\\{0, 1, 10, 11, 100, 101, 110, 111, 1000, 1001, 1010, 1011, 1100, \cdots\\}$ |
| Les nombres binaires impairs                                       | $\color{green}{1\\ \| \\ 1(0\\ \| \\ 1)^*1}$ | $\\{1, 11, 101, 111, 1001, 1011, 1101, 1111, 10001, \cdots\\}$                 |
| Les chaînes de bits de longueur paire ne contenant que des zeros et des uns alternés | $\color{green}{(10)^* \\ \| \\ (01)^*}$  | $\\{\epsilon, 10, 01, 1010, 0101, 101010, 010101, \cdots\\}$                              |
| Les chaînes de bits dont la longueur est multiple de 3             | $\color{green}{((0\\ \| \\ 1)(0\\ \| \\ 1)(0\\ \| \\ 1))^*}$ | $\\{\epsilon, 000, 001, 010, 011, 100, \cdots, 111000, 111001, \cdots, 101011110, \cdots \\}$ |
| Les chaînes de bits ne contenant pas la sous-chaîne $11$           | $\color{green}{0^* ( 100^* )^* (1\\ \| \\ \epsilon)}$ | $\\{\epsilon, 0, 1, 00, 01, 10, 000, 001, 010, 100, 101, 0000, 0001, \cdots\\}$ |


{{% notice info %}}
[Vous pouvez vous amuser en utilisant les expressions régulières sur Regex Crossword <i class="far fa-smile-beam"></i>.](https://regexcrossword.com/)
{{% /notice %}}

{{< youtube 5VNKh7aaZ-g >}}

{{< youtube Wl8FXqv6dak >}}

### Questions

On utilisera la notation $\\{a,b\\}^\*$ dans les questions ci-dessous : $\\{a,b\\}^\*$ représente le langage engendré par l'expression
régulière $\color{green}{(a\ |\ b)^*}$.

---

{{%expand "Soit l'alphabet $\{a, b\}$. Donner une expression régulière permettant de décrire le langage : $\{ w \in \{ a, b\}^*\ |\ w$ contient les mots $aa$ ou $bb$ $\}$." %}}

{{% /expand%}}

---

{{%expand "Cette question même si on pourrait penser qu'elle ressemble beaucoup à la précédente n'est pas facile. Vous pouvez revenir sur cette question après avoir vu la section suivante sur les automates. Soit l'alphabet $\{a, b\}$. Donner une expression régulière permettant de décrire le langage : $\{ w \in \{ a, b\}^*\ |\ w$ ne contient pas les mots $aa$ ou $bb$ $\}$." %}}

{{% /expand%}}

---

On veut se déplacer dans la grille ci-dessous en utilisant les deux actions : "aller à droite" et "aller en haut". On part du coin inférieur gauche et
on veut arriver au coin supérieur droit. Un chemin possible est indiqué dans la figure de droite.

{{< figure src="/images/minijava/scanner/scanner_question_grid3.svg" width="600px" height="auto">}}


{{%expand "Écrire une expression régulière permettant de décrire toutes les actions permettant d'aller du coin inférieur gauche au coin supérieur droit." %}}

On ne peut pas écrire succintement cette expression régulière sans utiliser des extensions. On va devoir énumérer les différentes configurations.
Le nombre de possibilités est le nombre de combinaisons de 3 éléments parmis 6 : ${{6}\choose{3}} = 20$. En effet, il faut 6 actions pour aller du départ jusqu'à l'arrivée.
Parmis ces 6 actions, 3 doivent aller vers la droite et 3 vers le haut. On va donc créer une expression régulière avec 20 parties. Nous utilisons `D` pour allez
à droite et `H` pour allez en haut.

$$
\scriptsize
\color{green}{HHHDDD\ |\
HHDHDD\ |\
HHDDHD\ |\
HHDDDH\ |\
HDHHDD\ |\
HDHDHD\ |\
HDHDDH\ |\
HDDHHD\ |\
HDDHDH\ |\
HDDDHH\ |\
DHHHDD\ |\
DHHDHD\ |\
DHHDDH\ |\
DHDHHD\ |\
DHDHDH\ |\
DHDDHH\ |\
DDHHHD\ |\
DDHHDH\ |\
DDHDHH\ |\
DDDHHH
}
$$

Nous avons généré les combinaisons ci-dessus grâce au programme suivant.

{{< highlight cpp>}}
#include <string>
#include <iostream>

using namespace std;

const string HAUT = "H";
const string DROITE = "D";

void combos(int nH, int nD, string res)
{
    if (!nH && !nD) {
        cout << res << "\n";
        return;
    }
    if (nH) {
        combos(nH - 1, nD, res + HAUT);
    }
    if (nD) {
        combos(nH, nD - 1, res + DROITE);
    }
}

int main(int argc, char *argv[])
{
    combos(3, 3, "");
}
{{< /highlight >}}

En utilisant les extensions des expressions régulières on peut obtenir la forme plus concise suivante.

{{< highlight julia>}}
^(?!(.*H.*){4}|(.*D.*){4})(H|D){6}$
{{< /highlight>}}

Dans cette expression, l'opérateur `(?!(.*H.*){4}|(.*D.*){4})` exprime qu'il ne faut pas réussir à trouver quatre `H` ou quatre `D` dans la suite de la ligne.
L'expression `(H|D){6}` exprime qu'il faut reconnaître six caractères parmis `H` et `D`. On exprime donc qu'il faut reconnaître six caractères parmis `H` et `D`,
mais on ne doit pas trouver quatre `H` ou quatre `D`. On doit donc avoir exactement trois `H` et trois `D`.

{{% /expand%}}

---

{{%expand "Cette question n'est pas facile. Vous pouvez revenir sur cette question après avoir vu la section suivante sur les automates. Soit l'alphabet $\{a, b\}$. Donner une expression régulière permettant de décrire le langage : $\{ w \in \{ a, b\}^*\ |\ w$ contient un nombre pair de $a$ et un nombre impair de $b$ $\}$." %}}

{{% /expand%}}

---

{{%expand "Soit l'alphabet $\{0, 1\}$. Quel est le langage décrit par l'expression régulière suivante : $\color{green}{0^*10^*10^*(10^*\ |\ \epsilon)}$ ?" %}}
Le langage contenant deux ou trois `1`.
{{% /expand%}}

## Automates

Dans la section précédente nous avons présenté les expressions régulières qui permettent de décrire les langages dit réguliers.
Cette notation est pratique pour décrire les langages réguliers, et nous l'utiliserons pour décrire les unités lexicales dans l'analyseur lexical de MiniJava.
Par contre, pour la reconnaissance, c'est-à-dire pour savoir si un mot donné appartient bien au langage décrit par une expression régulière, il n'est pas facile
d'utiliser directement une expression régulière.

Nous allons décrire maintenant les automates finis, non-déterministes et déterministes, qui permettent de répondre plus facilement à la question de savoir si un mot
donné appartient bien à un langage régulier donné. Nous nous servirons de ces automates dans la section suivante pour construire un logiciel permettant de tester
efficacement, si un mot donné appartient bien au langage engendré par une expression régulière donnée.

Notons que les langages décrits par les automates finis (non-déterministes ou déterministes) sont les langages réguliers, les expressions régulières et les automates
sont donc deux moyens équivalents permettant de décrire les mêmes langages.

### Automates finis non-déterministes

La figure suivante représente un automate fini non-déterministe, que nous appellerons $A_{fnd}$^[`fnd` pour *fini non déterministe*.], qui décrit les commentaires en C de type `/*...*/`. On suppose, pour simplifier, que notre vocabulaire
est $\mathcal{V} = \\{ a, b, /, * \\}$.
Sur cette figure on peut voir les éléments suivants :

* Des <span style="color:green">**états**</span>, les cercles sur la figure, numérotés de `0` à `7` pour cet exemple.
On peut y voir l'<span style="color:green">**état de départ**</span> (ou état initial), l'état `0`, qui possède une flèche qui arrive sur lui,
mais qui ne part d'aucun autre état. L'état `7` est un <span style="color:green">**état d'acceptation**</span> (ou état final), il est représenté par un double cercle.

* Des <span style="color:green">**transitions**</span> entre états, les flèches sur la figure. Sur les transitions il y a des symboles
appartenant au vocabulaire $\mathcal{V}$ ou bien le symbole $\epsilon$. Notons que sur certaines transitions, par exemple la transition entre l'état `3` et
l'état `2`, nous avons mis plusieurs symboles sur la transition (sur cette transition il y a les deux symboles `a` et  `b`).
Formellement, nous aurions dû écrire deux transitions au lieu d'une, avec chacune un des deux symboles, mais faire comme nous l'avons fait permet d'écrire plus succinctement l'automate.

{{< figure src="/images/minijava/scanner/nfa_comments.svg" width="800px" height="auto">}}

L'automate va nous permettre de savoir si un mot `m` construit à partir du vocabulaire $\mathcal{V}$ appartient au langage décrit par l'automate (on note ce langage $\mathcal{L}(A_{fnd})$).


<!-- #### Test de l'appartenance d'un mot au langage décrit par l'automate -->

Soit `/*/*/` un mot, que nous appellerons `m`, appartenant à $\mathcal{V}^*$.
Comment savoir si ce mot est décrit par l'automate $A_{fnd}$ ?

On va partir de l'état initial, l'état `0`, et on va suivre les transitions,
caractères après caractères, en cherchant un chemin qui nous mène vers l'état d'acceptation `7` après avoir lu tous les caractères du mot `m`.

{{< figure src="/images/minijava/scanner/nfa_comments1.svg" width="600px" height="auto">}}

 * À Partir de l'état `0`, il n'y a qu'une seule transition, il n'y a donc pas le choix. Le mot doit donc forcément commencer par `/`, car c'est le symbole sur cette transition.
 Une fois cette transition passée, on se trouve dans l'état `1` et il nous reste à analyser la partie `*/*/` de `m`.

{{< figure src="/images/minijava/scanner/nfa_comments2.svg" width="600px" height="auto">}}


 * À Partir de l'état `1`, il n'y a aussi qu'une seule transition possible. On doit donc forcément avoir le symbole `*` dans ce qu'il nous reste à analyser `*/*/`,
 car c'est le symbole sur la seule transition partant de l'état `1`.
 Une fois cette transition passée, on se trouve dans l'état `2` et il nous reste à analyser la partie `/*/` de `m`.

{{< figure src="/images/minijava/scanner/nfa_comments3.svg" width="600px" height="auto">}}

 * L'état `2` possède trois transitions sortantes. Elles sont toutes les trois labelées avec le symbole $\epsilon$. Ce symbole signifie que l'on ne modifie pas l'entrée lorsque
 l'on passe par une telle transition. On peut voir maintenant pourquoi l'automate est non déterministe car sur le même symbole, ici $\epsilon$, on a le choix entre plusieurs transitions.
 Comment faire pour s'orienter ? On va supposer pour le moment que l'on a des dons de clairvoyance et que l'on va choisir la bonne transition, qui est celle vers l'état `4`. On verra dans
 les vidéos comment automatiser cela.

{{< figure src="/images/minijava/scanner/nfa_comments4.svg" width="600px" height="auto">}}

 * Dans l'état `4` nous avons encore le choix entre deux transitions : ne pas consommer un caractère de l'entrée en prenant la transition $\epsilon$, ou consommer le caractère `/`
 en bouclant sur l'état `4`. Comme nous sommes devin, nous allons boucler sur l'état `4` et consommer le `/`.

 {{< figure src="/images/minijava/scanner/nfa_comments5.svg" width="600px" height="auto">}}


 * Maintenant, l'entrée qu'il nous reste à consommer est `*/`. Nous allons prendre la transition $\epsilon$ jusqu'à l'état `2`, puis la transition $\epsilon$ de l'état `2` vers l'état `3`. Encore
 une fois on ne se préoccupe pas pour l'instant du comment faire les bons choix de transitions lorsqu'il y a plus d'une possibilité. Nous nous retrouvons dans la configuration ci-dessous, où le curseur sous la chaîne
 d'entrée n'a pas bougé.

 {{< figure src="/images/minijava/scanner/nfa_comments6.svg" width="600px" height="auto">}}

* Dans l'état `5`, nous n'avons qu'une transition sortante sur le caractère `*`. Le curseur sur l'entrée est placé sur le `*`, on peut donc
prendre cette transition et déplacer le curseur vers la droite. Il nous reste maintenant simplement à reconnaître le `/`.

 {{< figure src="/images/minijava/scanner/nfa_comments7.svg" width="600px" height="auto">}}

* Dans l'état `6`, il n'y a là aussi qu'une seule transition sur le symbole `/`. Comme le curseur sur l'entrée pointe sur un caractère `/`, on peut prendre cette transition et se placer
sur l'état final `7`.

 {{< figure src="/images/minijava/scanner/nfa_comments8.svg" width="600px" height="auto">}}

 * Comme la chaîne d'entrée est maintenant vide et que nous sommes dans un état d'acceptation, on peut conclure que le mot `/*/*/` appartient bien au langage $\mathcal{L}(A_{fnd})$.
 Le mot `/*/*/` est donc bien un commentaire.


La chaîne d'entrée `/*/*/` est acceptée par notre automate, mais comment sait-on si une chaîne n'est pas dans le langage $\mathcal{L}(A_{fnd})$, autrement dit
comment sait-on si le mot n'est pas accepté ?
Pour un automate non déterministe, il faut montrer qu'après avoir lu tous les caractères de la chaîne d'entrée, on ne peut pas être dans un état d'acceptation.

{{% notice note %}}
Il nous semble plus aisé de construire l'automate fini non déterministe que nous venons de voir pour décrire le langage des commentaires que l'expression régulière
*$/\*\color{darkgreen}{(}\*^{\color{darkgreen}{+}}\color{darkgreen}{(}a\ \color{darkgreen}{|}\ b\color{darkgreen}{)}\ \color{darkgreen}{|}\ \color{darkgreen}{(}a\ |\ b\ |\ /\color{darkgreen}{)}\color{darkgreen}{)}^{\color{darkgreen}{\*}}\*^{\color{darkgreen}{+}}/$* que nous avions vu dans la section [précedente](#regular_expressions).
Après, vous êtes peut-être des gourous de [Perl](https://fr.wikipedia.org/wiki/Perl_(langage))^[`Perl` signifie *Practical Extraction and Report Language*, ou *Pathologically Eclectic Rubbish Lister* <i class="far fa-smile-wink"></i>.]
et c'est juste trop facile pour vous <i class="far fa-smile-beam"></i>.
{{% /notice %}}

Nous allons détailler dans les deux vidéos suivantes les automates finis non déterministes, et comment détecter si un mot appartient ou non au langage engendré par un automate fini non déterministe.


{{< youtube rZGSM0vvz58 >}}
{{< youtube uJmyT-tE7dY >}}

Dans la vidéo suivante, nous allons montrer comment passer d'une expression régulière à un automate fini non déterministe.

{{< youtube KFqUYGvmAHA >}}


#### Questions

{{%expand "Soit l'alphabet $\{a, b\}$. Construire un automate qui reconnait le langage : $\{ w \in \{ a, b\}^*\ |\ w$ contient le mot $aba$ $\}$. Par example, $aba$ est dans le langage, ainsi que $bbbbbaabaaaabb$, mais pas $babbbaaa$." %}}
 {{< figure src="/images/minijava/scanner/nfa_question1.svg" width="600px" height="auto">}}

Notons que cet automate calque vraiment l'expression régulière $\color{darkgreen}{(}a\ \color{darkgreen}{|}\ b\color{darkgreen}{)}^{\color{darkgreen}{\*}}aba\color{darkgreen}{(}a\ \color{darkgreen}{|}\ b\color{darkgreen}{)}^{\color{darkgreen}{\*}}$.
{{% /expand%}}


{{%expand "Soit l'alphabet $\{a, b\}$. Construire un automate qui reconnait le langage : $\{ w \in \{ a, b\}^*\ |\ w$ ne contient pas le mot $aba$ sauf s'il est précédé par le mot $bbb$ $\}$. Par exemple, $aaabbbaabaa$ est dans le langage, $abba$ aussi, mais pas $bbababbb$." %}}
{{< figure src="/images/minijava/scanner/nfa_question2.svg" width="600px" height="auto">}}

<a name="nfa_question2_states"></a>
La partie haute de l'automate, les états `1`, `2`, `3` et `4`, permet de reconnaître une suite de trois `b` suivie de n'importe quoi. La partie basse s'occupe de reconnaître tout sauf `aba`.
L'état `5` indique que l'on a pas encore vu de `a` ou bien que l'on vient de rencontrer une séquence se terminant par `bb` (on est donc sûr de ne pas avoir vu une séquence se terminant par `ab`).
L'état `6` indique qu'on est en train d'analyser une suite d'au moins un `a`
et l'état `7` qu'on vient de voir `ab`, donc qu'on ne doit pas avoir un `a` maintenant). À partir des états `5`, `6` et `7` on peut rejoindre la partie haute de l'automate car on vient d'analyser un préfixe correcte et on peut vouloir ajouter `aba` dans la suite (en ajoutant `bbb` avant).

Comment être sûr que la partie basse reconnaît bien tout sauf `aba` ? Pour la partie haute, il est assez facile de se convaincre qu'elle reconnaît bien $bbb\color{darkgreen}{(}a\ \color{darkgreen}{|}\ b\color{darkgreen}{)}^{\color{darkgreen}{\*}}$.
Mais ce n'est pas si évident de se convaincre que la partie basse décrit bien tout sauf la chaîne `aba`. Quand on veut vraiment être sûr, il n'y a qu'un moyen,
c'est faire une preuve !^[Vous me direz qu'il faut encore qu'elle soit correcte. C'est pas faux <i class="far fa-smile-beam"></i>, mais dans une preuve il faut juste se convaincre que chaque étape élémentaire est correcte.]

On va faire une preuve par récurrence sur la longueur de la chaîne. Pour une chaîne de longueur 0 ($\epsilon$) de longueur 1 ($a$ et $b$) et de longueur 2 ($aa$, $ab$, $ba$ et $bb$), on peut suivre les transitions
à partir de l'état 0 vers la partie basse et voir qu'on les reconnaît toutes et elles n'ont pas `aba` dedans (car la longueur de la chaîne est inférieure ou égale à 2). Supposons
que la propriété est vraie pour les chaînes de longueur $n \ge 2$, est-ce vraie pour les chaînes de longueur $n + 1$ ? Regardons les deux derniers caractères de la chaîne `m` de longueur $n$.

 * `m` se termine par `aa`. Dans ce cas on doit forcément se trouver dans l'état `6` [comme indiqué ci-dessus](#nfa_question2_states). On peut ajouter un `a` et accepter
 la nouvelle chaîne `ma` car on reste dans l'état `6` qui est un état d'acceptation, et on peut aussi ajouter un `b` et accepter la chaîne `mb` car on se retrouve dans l'état `7` qui est aussi
 un état d'acceptation.

 * `m` se termine par `ab`. Dans ce cas on doit forcément se trouver dans l'état `7` [comme indiqué ci-dessus](#nfa_question2_states). On ne peut pas ajouter de `a` car il n'y a aucune
 transition sur un `a` à partir de l'état `7` et donc on ne reconnaîtra pas une chaîne contenant `aba`. On peut par contre ajouter un `b` et bien reconnaître la chaîne de longueur $n+1$ `mb`.

 * `m` se termine par `ba`. Dans ce cas on doit forcément se trouver dans l'état `6` [comme indiqué ci-dessus](#nfa_question2_states) et on peut ajouter un `a` ou bien un `b` pour obtenir la
 chaîne de longueur $n+1$ `ma` ou `mb`.

 * `m` se termine par `bb`. Dans ce cas on doit forcément se trouver dans l'état `5` [comme indiqué ci-dessus](#nfa_question2_states) et on peut ajouter un `a` ou bien un `b` pour obtenir la
 chaîne de longueur $n+1$ `ma` ou `mb`.

En supposant donc qu'on peut générer tous les mots de longueur $n$ ne contenant pas `aba`, on vient de montrer qu'on peut générer tous les mots de longueur $n+1$ ne contenant pas `aba`.

{{% /expand%}}


### Automates finis déterministes

Les automates finis déterministes sont un sous-ensemble des automates finis non-déterministes. L'intérêt de ces automates, c'est de ne plus avoir besoin
de "deviner" la bonne transition à suivre car, dans un état donné et pour un symbole donné de l'entrée, il n'y a au plus qu'une transition possible. Comme nous l'avons vu
dans la section précédente, on peut en réalité se servir d'un automate non-déterministe sans avoir besoin de deviner. L'algorithme que nous avons vu permet en fait de construire dynamiquement
un automate fini déterministe. L'intérêt de partir directement d'un automate déterministe, c'est que l'on n'a pas besoin de reconstruire à chaque fois ce dernier.
Ce sera d'autant plus intéressant pour un analyseur lexical car les expressions régulières permettant de décrire les unités lexicales ne changeront pas
et on gagnera en efficacité en construisant une fois pour toute les automates correspondants aux expressions régulières.

L'automate suivant est une version
déterministe de l'automate non-déterministe qui reconnaît les commentaires en `C` de la section précédente.


{{< figure src="/images/minijava/scanner/dfa_comments.svg" width="800px" height="auto">}}

Comme les automates finis déterministes sont une restriction des automates finis non-déterministes, on pourrait à juste titre croire qu'ils permettent de décrire moins de langages.
En fait ce n'est pas le cas et ils sont aussi puissants que les automates finis non-déterministes.

La vidéo ci-dessous va décrire les automates finis déterministe et montrer comment transformer un automate non-déterministe en un automate déterministe.

{{< youtube hOAbe3TbdJ0 >}}

Le code utilisé dans la vidéo précédente est accessible [ici](https://gist.github.com/lascar-pacagi/e2ac6243986672d9c85a839f26eadc52).

Dans la vidéo suivante, nous allons montrer comment fonctionne un analyseur lexical et comment obtenir un automate fini déterministe de taille minimale.

Dans la vidéo suivante, nous allons coder en [C++](https://isocpp.org/) un analyseur lexical pour la partie du langage présentée dans la vidéo précédente.
Le code utilisé dans cette vidéo est accessible [ici](https://gist.github.com/lascar-pacagi/e2ac6243986672d9c85a839f26eadc52).


#### Questions

{{%expand "Soit l'alphabet $\{a, b\}$. Construire un automate qui reconnait le langage : $\{ w \in \{ a, b\}^*\ |\ w$ contient un nombre impair de $a$ et un nombre pair de $b \}$. Par example, $abb$ est dans le langage, ainsi que $bbabbaa$ et $aaaaa$, mais pas $b$ ni $aabb$." %}}
 {{< figure src="/images/minijava/scanner/dfa_question1.fr.svg" width="500px" height="auto">}}
Dans l'automate ci-dessus, on a un état par configuration possible de la parité des $a$ et des $b$. Par exemple, l'état d'acceptation $IP$ indique que l'on a rencontré
un nombre impair de $a$ et un nombre pair de $b$. L'état de départ $PP$ indique que l'on a vu un nombre pair de $a$ et de $b$. C'est vrai tout au début aussi, car on a alors rencontré
aucun $a$ et aucun $b$.
{{% /expand%}}

{{%expand "Soit l'expression régulière $\color{darkgreen}{0^*(100^*)^*(1|\epsilon)}$ décrivant les chaînes de bits sur l'alphabet $\{0, 1\}$ ne contenant pas la sous-chaîne $11$. Transformer cette expression régulière en un automate fini non-déterministe, puis transformer ce dernier en un automate fini déterministe et pour terminer, minimiser ce dernier." %}}
TO DO
{{% /expand%}}


### Passage d'un automate à une expression régulière

Nous pouvons construire automatiquement l'expression régulière correspondant à un automate fini (déterministe ou non-déterministe).
Nous montrons ci-dessous une suite de transformations permettant de passer de l'automate fini déterministe correspondant aux commentaires en C vu plus haut,
vers une expression régulière équivalente. Nous détaillerons dans la vidéo ci-dessous cette transformation.

On peut voir sur les transitions apparaître des expressions régulières au fur et à mesure des transformations. Pour ne pas confondre le caractère `*` avec l'opérateur
<span style="color:green">*</span>, nous avons écrit l'opérateur en vert.

<!-- {{< figure src="/images/minijava/scanner/automata_to_regex1.svg" width="800px" height="auto">}} -->

<!-- {{< figure src="/images/minijava/scanner/automata_to_regex2.svg" width="800px" height="auto">}} -->

<!-- {{< figure src="/images/minijava/scanner/automata_to_regex3.svg" width="300px" height="auto">}} -->

{{< figure src="/images/minijava/scanner/dfa_comments.svg" width="800px" height="auto">}}

Tout d'abord, nous allons réécrire l'automate en faisant apparaître clairement les expressions régulières représentant les alternatives sur les transitions.

{{< figure src="/images/minijava/scanner/dfa_comments_to_regex0.svg" width="800px" height="auto">}}

Nous allons maintenant éliminer tour à tour des états pour arriver à un automate ne contenant plus que deux états: un état initial et un état
d'acceptation.

Pour éliminer l'état $q = \\{3,5,6\\}$, il faut regarder pour chaque paire d'états $(q_1, q_2)$ s'il existe
un arc entre $q_1$ et $q$ et entre $q$ et $q_2$. Il faut alors maintenir cette information en modifiant l'arc entre $q_1$ et $q_2$.

Par exemple, ici, on va devoir considérer le chemin $\\{2,3,4,5\\}\rightarrow q \rightarrow \\{7\\}$ et ajouter l'expression régulière
$\*\*^{\color{darkgreen}{\*}}/$
entre les états $\\{2,3,4,5\\}$ et $\\{7\\}$ afin de conserver la même information. On doit aussi considérer le chemin $\\{2,3,4,5\\}\rightarrow q \rightarrow \\{2,3,4,5\\}$
et ajouter l'expression régulière
$\*\*^{\color{darkgreen}{\*}}{\color{darkgreen}{(}}a\mbox{ }{\color{darkgreen}{|}}\mbox{ }b{\color{darkgreen}{)}}$ sur la boucle de l'état $\\{2,3,4,5\\}$.
On obtient alors l'automate suivant.

<!-- $**^{\color{darkgreen}{*}}{\color{darkgreen}{(}}a\mbox{ }{\color{darkgreen}{|}}\mbox{ }b{\color{darkgreen}{)}$ -->

{{< figure src="/images/minijava/scanner/dfa_comments_to_regex1.svg" width="800px" height="auto">}}

En éliminant l'état $\\{2,3,4,5\\}$ on obtient alors l'automate suivant.

{{< figure src="/images/minijava/scanner/dfa_comments_to_regex2.svg" width="800px" height="auto">}}

Et enfin, en éliminant l'état $\\{1\\}$, on obtient l'expression régulière finale qui se trouve sur l'arc reliant l'état
de départ à l'état d'acceptation.

{{< figure src="/images/minijava/scanner/dfa_comments_to_regex3.svg" width="800px" height="auto">}}

La vidéo suivante va détailler cette construction.

#### Questions

## Identification de motifs

## Analyseur lexical avec ocamllex

## Ressources

{{% notice info %}}
[Jouer avec les expressions régulières](https://regexcrossword.com/)\
[Tester des expressions régulières](https://regex101.com/)\
[Transformer des expressions régulières en automates](https://cyberzhg.github.io/toolbox/min_dfa)\
{{% /notice %}}