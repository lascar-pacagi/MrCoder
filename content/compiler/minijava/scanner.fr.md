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

## Expressions régulières

Les expressions régulières vont nous permettre de décrire succintement et assez intuitivement
les unités lexicales de MiniJava et seront utilisées dans le générateur d'analyseur lexical `ocamlex` que nous
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
 l'expression régulière $\color{green}{r^*}$ représente l'hypothétique^[Une expression régulière doit être de taille finie.] expression régulière $\color{green}{\epsilon \\ |\\ r\\ |\\ rr\\ |\\ rrr\\ |\\ rrrr\\ |\\ \cdots}$.

        | <center>Expression</center> | <center>Ensemble de mots</center> |
        | :----------------:          | :----------------:                |
        | $\color{green}{0^*}$ | $\\{\epsilon, 0, 00, 000, 0000, \cdots\\}$ |
        | $\color{green}{(0\\ \|\\ 1)^*}$ | $\\{\epsilon, 0, 1, 00, 01, 10, 11, 000, 001, 010, 011, 100, \cdots\\}$ |


{{% notice note %}}
Pour éviter trop de parenthèses, il existe une priorité entre les différents opérateurs : les parenthèses ont la plus grande priorité,
ensuite l'opérateur $\color{green}{*}$, puis l'opérateur de concaténation et enfin l'opérateur $\color{green}{|}$. On a vu aussi ci-dessus que les opérateurs
de concaténation et d'union sont associatifs, ce qui nous permet de supprimer d'avantage de parenthèses.\
Ainsi, l'expression régulière $\color{green}{10^*1\\ |\\ 11\\ |\\ \epsilon}$ se lit
$\color{green}{(((1(0^ *))1)\\ |\\ (11))\\ |\\ \epsilon}$

{{% /notice %}}

### Examples

Nous donnons ci-dessous quelques examples d'expressions régulières toujours sur le vocabulaire $\mathcal{V} = \\{0, 1\\}$.

<!--  <style> -->
<!-- table { -->
<!--     width:100%; -->
<!-- } -->
<!-- </style> -->

| <center>Description</center> | <center>Expression</center> | <center>Ensemble de mots</center> |
| :----------------:           | :----------------:          | :----------------: |
| Les nombres binaires (sans zéro non significatif) | $\color{green}{0\\ \|\\ 1(0\\ \|\\ 1)^*}$ | $\\{0, 1, 10, 11, 100, 101, 110, 111, 1000, 1001, 1010, 1011, 1100, \cdots\\}$ |
| Les nombres binaires impairs | $\color{green}{1\\ \|\\ 1(0\\ \|\\ 1)^*1}$ | $\\{1, 11, 101, 111, 1001, 1011, 1101, 1111, 10001, \cdots\\}$ |
| Les chaînes de bits ne contenant que des zeros et des uns alternés | $\color{green}{10(10)^* \\ \| \\ 01(01)^*}$ | $\\{10, 01, 1010, 0101, 101010, 010101, \cdots\\}$ |
| Les chaînes de bits dont la longueur est multiple de 3 | $\color{green}{((0\\ \|\\ 1)(0\\ \|\\ 1)(0\\ \|\\ 1))^*}$ | $\\{\epsilon, 000, 001, 010, 011, 100, \cdots, 111000, 111001, \cdots, 101011110, \cdots \\}$ |
| Les chaînes de bits ne contenant pas la sous-chaîne $11$ | $\color{green}{0^* ( 100^* )^* (1\\ \|\\ \epsilon)}$ | $\\{\epsilon, 0, 1, 00, 01, 10, 000, 001, 010, 100, 101, 0000, 0001, \cdots\\}$ |


{{% notice info %}}
[Vous pouvez vous amuser en utilisant les expressions régulières sur Regex Crossword <i class="far fa-smile-beam"></i>.](https://regexcrossword.com/)
{{% /notice %}}

{{< youtube 5VNKh7aaZ-g >}}

{{< youtube Wl8FXqv6dak >}}

### Questions

## Automates

<center>
<svg width="800" height="600" version="1.1" xmlns="http://www.w3.org/2000/svg">
	<ellipse stroke="black" stroke-width="1" fill="none" cx="79.5" cy="304.5" rx="30" ry="30"/>
	<text x="73.5" y="310.5" font-family="Times New Roman" font-size="20">0</text>
	<ellipse stroke="black" stroke-width="1" fill="none" cx="203.5" cy="304.5" rx="30" ry="30"/>
	<text x="197.5" y="310.5" font-family="Times New Roman" font-size="20">1</text>
	<ellipse stroke="black" stroke-width="1" fill="none" cx="327.5" cy="304.5" rx="30" ry="30"/>
	<text x="321.5" y="310.5" font-family="Times New Roman" font-size="20">2</text>
	<ellipse stroke="black" stroke-width="1" fill="none" cx="437.5" cy="153.5" rx="30" ry="30"/>
	<text x="431.5" y="159.5" font-family="Times New Roman" font-size="20">3</text>
	<ellipse stroke="black" stroke-width="1" fill="none" cx="437.5" cy="470.5" rx="30" ry="30"/>
	<text x="431.5" y="476.5" font-family="Times New Roman" font-size="20">4</text>
	<ellipse stroke="black" stroke-width="1" fill="none" cx="525.5" cy="304.5" rx="30" ry="30"/>
	<text x="519.5" y="310.5" font-family="Times New Roman" font-size="20">5</text>
	<ellipse stroke="black" stroke-width="1" fill="none" cx="651.5" cy="304.5" rx="30" ry="30"/>
	<text x="645.5" y="310.5" font-family="Times New Roman" font-size="20">6</text>
	<ellipse stroke="black" stroke-width="1" fill="none" cx="762.5" cy="305.5" rx="30" ry="30"/>
	<text x="756.5" y="311.5" font-family="Times New Roman" font-size="20">7</text>
	<ellipse stroke="black" stroke-width="1" fill="none" cx="762.5" cy="305.5" rx="24" ry="24"/>
	<polygon stroke="black" stroke-width="1" points="38.5,227.5 65.4,278.02"/>
	<polygon fill="black" stroke-width="1" points="65.4,278.02 66.054,268.609 57.227,273.309"/>
	<polygon stroke="black" stroke-width="1" points="109.5,304.5 173.5,304.5"/>
	<polygon fill="black" stroke-width="1" points="173.5,304.5 165.5,299.5 165.5,309.5"/>
	<text x="138.5" y="325.5" font-family="Times New Roman" font-size="20">/</text>
	<polygon stroke="black" stroke-width="1" points="233.5,304.5 297.5,304.5"/>
	<polygon fill="black" stroke-width="1" points="297.5,304.5 289.5,299.5 289.5,309.5"/>
	<text x="257.5" y="325.5" font-family="Times New Roman" font-size="20">\*</text>
	<path stroke="black" stroke-width="1" fill="none" d="M 322.442,275.013 A 116.701,116.701 0 0 1 407.883,157.727"/>
	<polygon fill="black" stroke-width="1" points="407.883,157.727 398.838,155.045 401.508,164.682"/>
	<text x="328.5" y="193.5" font-family="Times New Roman" font-size="20">&#949;</text>
	<path stroke="black" stroke-width="1" fill="none" d="M 439.336,123.674 A 22.5,22.5 0 1 1 462.291,136.815"/>
	<text x="475.5" y="85.5" font-family="Times New Roman" font-size="20">\*,a,b</text>
	<polygon fill="black" stroke-width="1" points="462.291,136.815 471.638,138.095 467.537,128.974"/>
	<path stroke="black" stroke-width="1" fill="none" d="M 436.411,183.427 A 145.656,145.656 0 0 1 355.652,294.287"/>
	<polygon fill="black" stroke-width="1" points="355.652,294.287 365.031,295.301 360.673,286.3"/>
	<text x="415.5" y="268.5" font-family="Times New Roman" font-size="20">a,b</text>
	<path stroke="black" stroke-width="1" fill="none" d="M 412.001,454.746 A 205.781,205.781 0 0 1 332.07,334.123"/>
	<polygon fill="black" stroke-width="1" points="412.001,454.746 408.45,446.006 402.588,454.108"/>
	<text x="344.5" y="421.5" font-family="Times New Roman" font-size="20">&#949;</text>
	<path stroke="black" stroke-width="1" fill="none" d="M 354.077,318.341 A 179.196,179.196 0 0 1 435.112,440.63"/>
	<polygon fill="black" stroke-width="1" points="354.077,318.341 358.166,326.843 363.511,318.391"/>
	<text x="413.5" y="363.5" font-family="Times New Roman" font-size="20">&#949;</text>
	<path stroke="black" stroke-width="1" fill="none" d="M 455.724,494.183 A 22.5,22.5 0 1 1 429.787,499.37"/>
	<text x="443.5" y="560.5" font-family="Times New Roman" font-size="20">/,a,b</text>
	<polygon fill="black" stroke-width="1" points="429.787,499.37 421.902,504.551 430.988,508.728"/>
	<polygon stroke="black" stroke-width="1" points="357.5,304.5 495.5,304.5"/>
	<polygon fill="black" stroke-width="1" points="495.5,304.5 487.5,299.5 487.5,309.5"/>
	<text x="421.5" y="325.5" font-family="Times New Roman" font-size="20">&#949;</text>
	<path stroke="black" stroke-width="1" fill="none" d="M 459.975,173.34 A 233.09,233.09 0 0 1 519.317,275.165"/>
	<polygon fill="black" stroke-width="1" points="519.317,275.165 521.983,266.116 512.351,268.803"/>
	<text x="502.5" y="214.5" font-family="Times New Roman" font-size="20">&#949;</text>
	<polygon stroke="black" stroke-width="1" points="555.5,304.5 621.5,304.5"/>
	<polygon fill="black" stroke-width="1" points="621.5,304.5 613.5,299.5 613.5,309.5"/>
	<text x="580.5" y="325.5" font-family="Times New Roman" font-size="20">\*</text>
	<polygon stroke="black" stroke-width="1" points="681.499,304.77 732.501,305.23"/>
	<polygon fill="black" stroke-width="1" points="732.501,305.23 724.547,300.158 724.456,310.157"/>
	<text x="703.5" y="326.5" font-family="Times New Roman" font-size="20">/</text>
</svg>
</center>

<center>
<svg width="800" height="600" version="1.1" xmlns="http://www.w3.org/2000/svg">
	<ellipse stroke="black" stroke-width="1" fill="none" cx="68.5" cy="304.5" rx="30" ry="30"/>
	<text x="62.5" y="310.5" font-family="Times New Roman" font-size="20">0</text>
	<ellipse stroke="black" stroke-width="1" fill="none" cx="207.5" cy="304.5" rx="30" ry="30"/>
	<text x="201.5" y="310.5" font-family="Times New Roman" font-size="20">1</text>
	<ellipse stroke="black" stroke-width="1" fill="none" cx="353.5" cy="304.5" rx="30" ry="30"/>
	<text x="325.5" y="310.5" font-family="Times New Roman" font-size="20">2,3,4,5</text>
	<ellipse stroke="black" stroke-width="1" fill="none" cx="701.5" cy="304.5" rx="30" ry="30"/>
	<text x="695.5" y="310.5" font-family="Times New Roman" font-size="20">7</text>
	<ellipse stroke="black" stroke-width="1" fill="none" cx="701.5" cy="304.5" rx="24" ry="24"/>
	<ellipse stroke="black" stroke-width="1" fill="none" cx="550.5" cy="304.5" rx="30" ry="30"/>
	<text x="530.5" y="310.5" font-family="Times New Roman" font-size="20">3,5,6</text>
	<polygon stroke="black" stroke-width="1" points="27.5,227.5 54.4,278.02"/>
	<polygon fill="black" stroke-width="1" points="54.4,278.02 55.054,268.609 46.227,273.309"/>
	<polygon stroke="black" stroke-width="1" points="98.5,304.5 177.5,304.5"/>
	<polygon fill="black" stroke-width="1" points="177.5,304.5 169.5,299.5 169.5,309.5"/>
	<text x="134.5" y="325.5" font-family="Times New Roman" font-size="20">/</text>
	<polygon stroke="black" stroke-width="1" points="237.5,304.5 323.5,304.5"/>
	<polygon fill="black" stroke-width="1" points="323.5,304.5 315.5,299.5 315.5,309.5"/>
	<text x="272.5" y="325.5" font-family="Times New Roman" font-size="20">\*</text>
	<path stroke="black" stroke-width="1" fill="none" d="M 340.275,277.703 A 22.5,22.5 0 1 1 366.725,277.703"/>
	<text x="331.5" y="228.5" font-family="Times New Roman" font-size="20">/,a,b</text>
	<polygon fill="black" stroke-width="1" points="366.725,277.703 375.473,274.17 367.382,268.292"/>
	<path stroke="black" stroke-width="1" fill="none" d="M 525.411,320.866 A 158.04,158.04 0 0 1 378.589,320.866"/>
	<polygon fill="black" stroke-width="1" points="525.411,320.866 516.004,320.154 520.649,329.01"/>
	<text x="443.5" y="359.5" font-family="Times New Roman" font-size="20">\*</text>
	<path stroke="black" stroke-width="1" fill="none" d="M 380.805,292.136 A 206.245,206.245 0 0 1 523.195,292.136"/>
	<polygon fill="black" stroke-width="1" points="380.805,292.136 390.039,294.068 386.587,284.682"/>
	<text x="436.5" y="270.5" font-family="Times New Roman" font-size="20">a,b</text>
	<polygon stroke="black" stroke-width="1" points="580.5,304.5 671.5,304.5"/>
	<polygon fill="black" stroke-width="1" points="671.5,304.5 663.5,299.5 663.5,309.5"/>
	<text x="622.5" y="325.5" font-family="Times New Roman" font-size="20">/</text>
	<path stroke="black" stroke-width="1" fill="none" d="M 537.275,277.703 A 22.5,22.5 0 1 1 563.725,277.703"/>
	<text x="542.5" y="228.5" font-family="Times New Roman" font-size="20">\*</text>
	<polygon fill="black" stroke-width="1" points="563.725,277.703 572.473,274.17 564.382,268.292"/>
</svg>
</center>

## Identification de motifs

## Analyseur lexical avec ocamlex

## Ressources

{{% notice info %}}
[Jouer avec les expressions régulières](https://regexcrossword.com/)\
[Tester des expressions régulières](https://regex101.com/)\
{{% /notice %}}