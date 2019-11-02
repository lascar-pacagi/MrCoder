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
de concaténation et d'union sont associatifs, ce qui nous permet de supprimer d'avantage de parenthèses.\
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
| Les chaînes de bits ne contenant que des zeros et des uns alternés | $\color{green}{10(10)^* \\ \| \\ 01(01)^*}$  | $\\{10, 01, 1010, 0101, 101010, 010101, \cdots\\}$                              |
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

<center>
<svg version="1.2" width="281mm" height="154mm" viewBox="0 0 38100 25400" preserveAspectRatio="xMidYMid" fill-rule="evenodd" stroke-width="28.222" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg" xmlns:ooo="http://xml.openoffice.org/svg/export" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:presentation="http://sun.com/xmlns/staroffice/presentation" xmlns:smil="http://www.w3.org/2001/SMIL20/" xmlns:anim="urn:oasis:names:tc:opendocument:xmlns:animation:1.0" xml:space="preserve">
 <defs class="ClipPathGroup">
  <clipPath id="presentation_clip_path" clipPathUnits="userSpaceOnUse">
   <rect x="0" y="0" width="38100" height="25400"/>
  </clipPath>
  <clipPath id="presentation_clip_path_shrink" clipPathUnits="userSpaceOnUse">
   <rect x="38" y="25" width="38024" height="25350"/>
  </clipPath>
 </defs>
 <defs>
  <font id="EmbeddedFont_1" horiz-adv-x="2048">
   <font-face font-family="Liberation Sans embedded" units-per-em="2048" font-weight="bold" font-style="normal" ascent="1852" descent="423"/>
   <missing-glyph horiz-adv-x="2048" d="M 0,0 L 2047,0 2047,2047 0,2047 0,0 Z"/>
   <glyph unicode="é" horiz-adv-x="1007" d="M 586,-20 C 423,-20 298,28 211,125 124,221 80,361 80,546 80,725 124,862 213,958 302,1054 427,1102 590,1102 745,1102 864,1051 946,948 1028,845 1069,694 1069,495 L 1069,487 375,487 C 375,382 395,302 434,249 473,195 528,168 600,168 699,168 762,211 788,297 L 1053,274 C 976,78 821,-20 586,-20 Z M 586,925 C 520,925 469,902 434,856 398,810 379,746 377,663 L 797,663 C 792,750 771,816 734,860 697,903 648,925 586,925 Z M 418,1183 L 418,1214 670,1502 928,1502 928,1459 588,1183 418,1183 Z"/>
   <glyph unicode="v" horiz-adv-x="1139" d="M 731,0 L 395,0 8,1082 305,1082 494,477 C 504,444 528,360 565,227 572,254 585,302 606,371 627,440 703,677 836,1082 L 1130,1082 731,0 Z"/>
   <glyph unicode="t" horiz-adv-x="662" d="M 420,-18 C 337,-18 274,5 229,50 184,95 162,163 162,254 L 162,892 25,892 25,1082 176,1082 264,1336 440,1336 440,1082 645,1082 645,892 440,892 440,330 C 440,277 450,239 470,214 490,189 521,176 563,176 585,176 616,181 657,190 L 657,16 C 588,-7 509,-18 420,-18 Z"/>
   <glyph unicode="s" horiz-adv-x="1006" d="M 1055,316 C 1055,211 1012,129 927,70 841,10 722,-20 571,-20 422,-20 309,4 230,51 151,98 98,171 72,270 L 319,307 C 333,256 357,219 392,198 426,177 486,166 571,166 650,166 707,176 743,196 779,216 797,247 797,290 797,325 783,352 754,373 725,393 675,410 606,424 447,455 340,485 285,512 230,539 188,574 159,617 130,660 115,712 115,775 115,878 155,959 235,1017 314,1074 427,1103 573,1103 702,1103 805,1078 884,1028 962,978 1011,906 1030,811 L 781,785 C 773,829 753,862 722,884 691,905 641,916 573,916 506,916 456,908 423,891 390,874 373,845 373,805 373,774 386,749 412,731 437,712 480,697 541,685 626,668 701,650 767,632 832,613 885,591 925,566 964,541 996,508 1020,469 1043,429 1055,378 1055,316 Z"/>
   <glyph unicode="r" horiz-adv-x="636" d="M 143,0 L 143,828 C 143,887 142,937 141,977 139,1016 137,1051 135,1082 L 403,1082 C 405,1070 408,1034 411,973 414,912 416,871 416,851 L 420,851 C 447,927 472,981 493,1012 514,1043 540,1066 569,1081 598,1096 635,1103 679,1103 715,1103 744,1098 766,1088 L 766,853 C 721,863 681,868 646,868 576,868 522,840 483,783 444,726 424,642 424,531 L 424,0 143,0 Z"/>
   <glyph unicode="p" horiz-adv-x="1033" d="M 1167,546 C 1167,365 1131,226 1059,128 986,29 884,-20 752,-20 676,-20 610,-3 554,30 497,63 454,110 424,172 L 418,172 C 422,152 424,91 424,-10 L 424,-425 143,-425 143,833 C 143,935 140,1018 135,1082 L 408,1082 C 411,1070 414,1046 417,1011 419,976 420,941 420,906 L 424,906 C 487,1039 603,1105 770,1105 896,1105 994,1057 1063,960 1132,863 1167,725 1167,546 Z M 874,546 C 874,789 800,910 651,910 576,910 519,877 480,812 440,747 420,655 420,538 420,421 440,331 480,268 519,204 576,172 649,172 799,172 874,297 874,546 Z"/>
   <glyph unicode="o" horiz-adv-x="1113" d="M 1171,542 C 1171,367 1122,229 1025,130 928,30 793,-20 621,-20 452,-20 320,30 224,130 128,230 80,367 80,542 80,716 128,853 224,953 320,1052 454,1102 627,1102 804,1102 939,1054 1032,958 1125,861 1171,723 1171,542 Z M 877,542 C 877,671 856,764 814,822 772,880 711,909 631,909 460,909 375,787 375,542 375,421 396,330 438,267 479,204 539,172 618,172 791,172 877,295 877,542 Z"/>
   <glyph unicode="n" horiz-adv-x="1007" d="M 844,0 L 844,607 C 844,797 780,892 651,892 583,892 528,863 487,805 445,746 424,671 424,580 L 424,0 143,0 143,840 C 143,898 142,946 141,983 139,1020 137,1053 135,1082 L 403,1082 C 405,1069 408,1036 411,981 414,926 416,888 416,867 L 420,867 C 458,950 506,1010 563,1047 620,1084 689,1103 768,1103 883,1103 971,1068 1032,997 1093,926 1124,823 1124,687 L 1124,0 844,0 Z"/>
   <glyph unicode="i" horiz-adv-x="292" d="M 143,1277 L 143,1484 424,1484 424,1277 143,1277 Z M 143,0 L 143,1082 424,1082 424,0 143,0 Z"/>
   <glyph unicode="e" horiz-adv-x="1007" d="M 586,-20 C 423,-20 298,28 211,125 124,221 80,361 80,546 80,725 124,862 213,958 302,1054 427,1102 590,1102 745,1102 864,1051 946,948 1028,845 1069,694 1069,495 L 1069,487 375,487 C 375,382 395,302 434,249 473,195 528,168 600,168 699,168 762,211 788,297 L 1053,274 C 976,78 821,-20 586,-20 Z M 586,925 C 520,925 469,902 434,856 398,810 379,746 377,663 L 797,663 C 792,750 771,816 734,860 697,903 648,925 586,925 Z"/>
   <glyph unicode="c" horiz-adv-x="1007" d="M 594,-20 C 430,-20 303,29 214,127 125,224 80,360 80,535 80,714 125,853 215,953 305,1052 433,1102 598,1102 725,1102 831,1070 914,1006 997,942 1050,854 1071,741 L 788,727 C 780,782 760,827 728,860 696,893 651,909 592,909 447,909 375,788 375,546 375,297 449,172 596,172 649,172 694,189 730,223 766,256 788,306 797,373 L 1079,360 C 1069,286 1043,220 1000,162 957,104 900,59 830,28 760,-4 681,-20 594,-20 Z"/>
   <glyph unicode="a" horiz-adv-x="1112" d="M 393,-20 C 288,-20 207,9 148,66 89,123 60,203 60,306 60,418 97,503 170,562 243,621 348,651 487,652 L 720,656 720,711 C 720,782 708,834 683,869 658,903 618,920 562,920 510,920 472,908 448,885 423,861 408,822 402,767 L 109,781 C 127,886 175,966 254,1021 332,1075 439,1102 574,1102 711,1102 816,1068 890,1001 964,934 1001,838 1001,714 L 1001,320 C 1001,259 1008,218 1022,195 1035,172 1058,160 1090,160 1111,160 1132,162 1152,166 L 1152,14 C 1135,10 1120,6 1107,3 1094,0 1080,-3 1067,-5 1054,-7 1040,-9 1025,-10 1010,-11 992,-12 972,-12 901,-12 849,5 816,40 782,75 762,126 755,193 L 749,193 C 670,51 552,-20 393,-20 Z M 720,501 L 576,499 C 511,496 464,489 437,478 410,466 389,448 375,424 360,400 353,368 353,328 353,277 365,239 389,214 412,189 444,176 483,176 527,176 567,188 604,212 640,236 668,269 689,312 710,354 720,399 720,446 L 720,501 Z"/>
   <glyph unicode="D" horiz-adv-x="1271" d="M 1393,715 C 1393,570 1365,443 1308,335 1251,226 1170,143 1066,86 961,29 842,0 707,0 L 137,0 137,1409 647,1409 C 884,1409 1068,1349 1198,1230 1328,1110 1393,938 1393,715 Z M 1096,715 C 1096,866 1057,982 978,1062 899,1141 787,1181 641,1181 L 432,1181 432,228 682,228 C 809,228 909,272 984,359 1059,446 1096,565 1096,715 Z"/>
   <glyph unicode="A" horiz-adv-x="1404" d="M 1133,0 L 1008,360 471,360 346,0 51,0 565,1409 913,1409 1425,0 1133,0 Z M 739,1192 L 733,1170 C 726,1146 718,1119 709,1088 700,1057 642,889 537,582 L 942,582 803,987 760,1123 739,1192 Z"/>
   <glyph unicode=":" horiz-adv-x="319" d="M 197,752 L 197,1034 485,1034 485,752 197,752 Z M 197,0 L 197,281 485,281 485,0 197,0 Z"/>
   <glyph unicode=" " horiz-adv-x="556"/>
  </font>
 </defs>
 <defs class="TextShapeIndex">
  <g ooo:slide="id1" ooo:id-list="id3 id4 id5 id6 id7 id8 id9 id10 id11 id12 id13 id14 id15 id16 id17 id18 id19"/>
 </defs>
 <defs class="EmbeddedBulletChars">
  <g id="bullet-char-template-57356" transform="scale(0.00048828125,-0.00048828125)">
   <path d="M 580,1141 L 1163,571 580,0 -4,571 580,1141 Z"/>
  </g>
  <g id="bullet-char-template-57354" transform="scale(0.00048828125,-0.00048828125)">
   <path d="M 8,1128 L 1137,1128 1137,0 8,0 8,1128 Z"/>
  </g>
  <g id="bullet-char-template-10146" transform="scale(0.00048828125,-0.00048828125)">
   <path d="M 174,0 L 602,739 174,1481 1456,739 174,0 Z M 1358,739 L 309,1346 659,739 1358,739 Z"/>
  </g>
  <g id="bullet-char-template-10132" transform="scale(0.00048828125,-0.00048828125)">
   <path d="M 2015,739 L 1276,0 717,0 1260,543 174,543 174,936 1260,936 717,1481 1274,1481 2015,739 Z"/>
  </g>
  <g id="bullet-char-template-10007" transform="scale(0.00048828125,-0.00048828125)">
   <path d="M 0,-2 C -7,14 -16,27 -25,37 L 356,567 C 262,823 215,952 215,954 215,979 228,992 255,992 264,992 276,990 289,987 310,991 331,999 354,1012 L 381,999 492,748 772,1049 836,1024 860,1049 C 881,1039 901,1025 922,1006 886,937 835,863 770,784 769,783 710,716 594,584 L 774,223 C 774,196 753,168 711,139 L 727,119 C 717,90 699,76 672,76 641,76 570,178 457,381 L 164,-76 C 142,-110 111,-127 72,-127 30,-127 9,-110 8,-76 1,-67 -2,-52 -2,-32 -2,-23 -1,-13 0,-2 Z"/>
  </g>
  <g id="bullet-char-template-10004" transform="scale(0.00048828125,-0.00048828125)">
   <path d="M 285,-33 C 182,-33 111,30 74,156 52,228 41,333 41,471 41,549 55,616 82,672 116,743 169,778 240,778 293,778 328,747 346,684 L 369,508 C 377,444 397,411 428,410 L 1163,1116 C 1174,1127 1196,1133 1229,1133 1271,1133 1292,1118 1292,1087 L 1292,965 C 1292,929 1282,901 1262,881 L 442,47 C 390,-6 338,-33 285,-33 Z"/>
  </g>
  <g id="bullet-char-template-9679" transform="scale(0.00048828125,-0.00048828125)">
   <path d="M 813,0 C 632,0 489,54 383,161 276,268 223,411 223,592 223,773 276,916 383,1023 489,1130 632,1184 813,1184 992,1184 1136,1130 1245,1023 1353,916 1407,772 1407,592 1407,412 1353,268 1245,161 1136,54 992,0 813,0 Z"/>
  </g>
  <g id="bullet-char-template-8226" transform="scale(0.00048828125,-0.00048828125)">
   <path d="M 346,457 C 273,457 209,483 155,535 101,586 74,649 74,723 74,796 101,859 155,911 209,963 273,989 346,989 419,989 480,963 531,910 582,859 608,796 608,723 608,648 583,586 532,535 482,483 420,457 346,457 Z"/>
  </g>
  <g id="bullet-char-template-8211" transform="scale(0.00048828125,-0.00048828125)">
   <path d="M -4,459 L 1135,459 1135,606 -4,606 -4,459 Z"/>
  </g>
  <g id="bullet-char-template-61548" transform="scale(0.00048828125,-0.00048828125)">
   <path d="M 173,740 C 173,903 231,1043 346,1159 462,1274 601,1332 765,1332 928,1332 1067,1274 1183,1159 1299,1043 1357,903 1357,740 1357,577 1299,437 1183,322 1067,206 928,148 765,148 601,148 462,206 346,322 231,437 173,577 173,740 Z"/>
  </g>
 </defs>
 <defs class="TextEmbeddedBitmaps"/>
 <g>
  <g id="id2" class="Master_Slide">
   <g id="bg-id2" class="Background"/>
   <g id="bo-id2" class="BackgroundObjects"/>
  </g>
 </g>
 <g class="SlideGroup">
  <g>
   <g id="container-id1">
    <g id="id1" class="Slide" clip-path="url(#presentation_clip_path)">
     <g class="Page">
      <g class="com.sun.star.drawing.TableShape">
       <g>
        <rect class="BoundingBox" stroke="none" fill="none" x="3373" y="10151" width="14312" height="8693"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 3479,10257 L 8178,10257 8178,13082 3479,13082 3479,10257 Z"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 8178,10257 L 12877,10257 12877,13082 8178,13082 8178,10257 Z"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 12877,10257 L 17578,10257 17578,13082 12877,13082 12877,10257 Z"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 3479,13082 L 8178,13082 8178,15907 3479,15907 3479,13082 Z"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 8178,13082 L 12877,13082 12877,15907 8178,15907 8178,13082 Z"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 12877,13082 L 17578,13082 17578,15907 12877,15907 12877,13082 Z"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 3479,15907 L 8178,15907 8178,18737 3479,18737 3479,15907 Z"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 8178,15907 L 12877,15907 12877,18737 8178,18737 8178,15907 Z"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 12877,15907 L 17578,15907 17578,18737 12877,18737 12877,15907 Z"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 3426,10257 L 17631,10257"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 3426,13082 L 17631,13082"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 3426,15907 L 8231,15907"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 3426,18737 L 8231,18737"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 8125,15907 L 12930,15907"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 8125,18737 L 12930,18737"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 12824,15907 L 17631,15907"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 12824,18737 L 17631,18737"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 3479,10204 L 3479,18790"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 8178,10204 L 8178,18790"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 12877,10204 L 12877,13135"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 17578,10204 L 17578,13135"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 12877,13029 L 12877,15960"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 17578,13029 L 17578,15960"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 12877,15854 L 12877,18790"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 17578,15854 L 17578,18790"/>
       </g>
      </g>
      <g class="com.sun.star.drawing.CustomShape">
       <g id="id3">
        <rect class="BoundingBox" stroke="none" fill="none" x="3212" y="18808" width="639" height="1866"/>
        <path fill="rgb(250,166,26)" stroke="none" d="M 3372,20671 L 3372,19274 3213,19274 3531,18809 3849,19274 3690,19274 3690,20671 3372,20671 Z M 3213,18809 L 3213,18809 Z M 3849,20672 L 3849,20672 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 3372,20671 L 3372,19274 3213,19274 3531,18809 3849,19274 3690,19274 3690,20671 3372,20671 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 3213,18809 L 3213,18809 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 3849,20672 L 3849,20672 Z"/>
       </g>
      </g>
      <g class="com.sun.star.drawing.TextShape">
       <g id="id4">
        <rect class="BoundingBox" stroke="none" fill="none" x="2198" y="20679" width="2747" height="1039"/>
        <text class="TextShape"><tspan class="TextParagraph" font-family="Liberation Sans, sans-serif" font-size="706px" font-weight="700"><tspan class="TextPosition" x="2448" y="21443"><tspan fill="rgb(0,0,0)" stroke="none">Départ</tspan></tspan></tspan></text>
       </g>
      </g>
      <g class="com.sun.star.drawing.CustomShape">
       <g id="id5">
        <rect class="BoundingBox" stroke="none" fill="none" x="17194" y="8298" width="671" height="1868"/>
        <path fill="rgb(250,166,26)" stroke="none" d="M 17672,8299 L 17696,9696 17855,9693 17545,10164 17219,9704 17378,9702 17354,8305 17672,8299 Z M 17863,10158 L 17863,10158 Z M 17195,8307 L 17195,8307 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 17672,8299 L 17696,9696 17855,9693 17545,10164 17219,9704 17378,9702 17354,8305 17672,8299 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 17863,10158 L 17863,10158 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 17195,8307 L 17195,8307 Z"/>
       </g>
      </g>
      <g class="com.sun.star.drawing.TextShape">
       <g id="id6">
        <rect class="BoundingBox" stroke="none" fill="none" x="15921" y="7257" width="2941" height="1039"/>
        <text class="TextShape"><tspan class="TextParagraph" font-family="Liberation Sans, sans-serif" font-size="706px" font-weight="700"><tspan class="TextPosition" x="16171" y="8021"><tspan fill="rgb(0,0,0)" stroke="none">Arrivée</tspan></tspan></tspan></text>
       </g>
      </g>
      <g class="com.sun.star.drawing.CustomShape">
       <g id="id7">
        <rect class="BoundingBox" stroke="none" fill="none" x="19843" y="3412" width="2671" height="1020"/>
        <path fill="rgb(0,0,0)" stroke="none" d="M 19844,3667 L 21845,3667 21845,3413 22512,3921 21845,4430 21845,4175 19844,4175 19844,3667 Z M 19844,3413 L 19844,3413 Z M 22512,4430 L 22512,4430 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 19844,3667 L 21845,3667 21845,3413 22512,3921 21845,4430 21845,4175 19844,4175 19844,3667 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 19844,3413 L 19844,3413 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 22512,4430 L 22512,4430 Z"/>
       </g>
      </g>
      <g class="com.sun.star.drawing.CustomShape">
       <g id="id8">
        <rect class="BoundingBox" stroke="none" fill="none" x="23400" y="1760" width="1020" height="2671"/>
        <path fill="rgb(0,0,0)" stroke="none" d="M 23655,4429 L 23655,2428 23401,2428 23909,1761 24418,2428 24163,2428 24163,4429 23655,4429 Z M 23401,4429 L 23401,4429 Z M 24418,1761 L 24418,1761 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 23655,4429 L 23655,2428 23401,2428 23909,1761 24418,2428 24163,2428 24163,4429 23655,4429 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 23401,4429 L 23401,4429 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 24418,1761 L 24418,1761 Z"/>
       </g>
      </g>
      <g class="com.sun.star.drawing.TextShape">
       <g id="id9">
        <rect class="BoundingBox" stroke="none" fill="none" x="15478" y="3361" width="4127" height="1196"/>
        <text class="TextShape"><tspan class="TextParagraph" font-family="Liberation Sans, sans-serif" font-size="847px" font-weight="700"><tspan class="TextPosition" x="15728" y="4252"><tspan fill="rgb(0,0,0)" stroke="none">Actions :</tspan></tspan></tspan></text>
       </g>
      </g>
      <g class="com.sun.star.drawing.TableShape">
       <g>
        <rect class="BoundingBox" stroke="none" fill="none" x="21173" y="10151" width="14312" height="8693"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 21279,10257 L 25978,10257 25978,13082 21279,13082 21279,10257 Z"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 25978,10257 L 30677,10257 30677,13082 25978,13082 25978,10257 Z"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 30677,10257 L 35378,10257 35378,13082 30677,13082 30677,10257 Z"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 21279,13082 L 25978,13082 25978,15907 21279,15907 21279,13082 Z"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 25978,13082 L 30677,13082 30677,15907 25978,15907 25978,13082 Z"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 30677,13082 L 35378,13082 35378,15907 30677,15907 30677,13082 Z"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 21279,15907 L 25978,15907 25978,18737 21279,18737 21279,15907 Z"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 25978,15907 L 30677,15907 30677,18737 25978,18737 25978,15907 Z"/>
        <path fill="rgb(173,213,138)" stroke="none" d="M 30677,15907 L 35378,15907 35378,18737 30677,18737 30677,15907 Z"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 21226,10257 L 35431,10257"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 21226,13082 L 35431,13082"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 21226,15907 L 26031,15907"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 21226,18737 L 26031,18737"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 25925,15907 L 30730,15907"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 25925,18737 L 30730,18737"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 30624,15907 L 35431,15907"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 30624,18737 L 35431,18737"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 21279,10204 L 21279,18790"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 25978,10204 L 25978,18790"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 30677,10204 L 30677,13135"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 35378,10204 L 35378,13135"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 30677,13029 L 30677,15960"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 35378,13029 L 35378,15960"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 30677,15854 L 30677,18790"/>
        <path fill="none" stroke="rgb(0,0,0)" stroke-width="106" stroke-linejoin="round" d="M 35378,15854 L 35378,18790"/>
       </g>
      </g>
      <g class="com.sun.star.drawing.TextShape">
       <g id="id10">
        <rect class="BoundingBox" stroke="none" fill="none" x="19998" y="20679" width="2747" height="1039"/>
        <text class="TextShape"><tspan class="TextParagraph" font-family="Liberation Sans, sans-serif" font-size="706px" font-weight="700"><tspan class="TextPosition" x="20248" y="21443"><tspan fill="rgb(0,0,0)" stroke="none">Départ</tspan></tspan></tspan></text>
       </g>
      </g>
      <g class="com.sun.star.drawing.CustomShape">
       <g id="id11">
        <rect class="BoundingBox" stroke="none" fill="none" x="34994" y="8298" width="671" height="1868"/>
        <path fill="rgb(250,166,26)" stroke="none" d="M 35472,8299 L 35496,9696 35655,9693 35345,10164 35019,9704 35178,9702 35154,8305 35472,8299 Z M 35663,10158 L 35663,10158 Z M 34995,8307 L 34995,8307 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 35472,8299 L 35496,9696 35655,9693 35345,10164 35019,9704 35178,9702 35154,8305 35472,8299 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 35663,10158 L 35663,10158 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 34995,8307 L 34995,8307 Z"/>
       </g>
      </g>
      <g class="com.sun.star.drawing.TextShape">
       <g id="id12">
        <rect class="BoundingBox" stroke="none" fill="none" x="33721" y="7257" width="2941" height="1039"/>
        <text class="TextShape"><tspan class="TextParagraph" font-family="Liberation Sans, sans-serif" font-size="706px" font-weight="700"><tspan class="TextPosition" x="33971" y="8021"><tspan fill="rgb(0,0,0)" stroke="none">Arrivée</tspan></tspan></tspan></text>
       </g>
      </g>
      <g class="com.sun.star.drawing.CustomShape">
       <g id="id13">
        <rect class="BoundingBox" stroke="none" fill="none" x="26041" y="15447" width="4680" height="1020"/>
        <path fill="rgb(0,0,0)" stroke="none" d="M 26042,15702 L 29549,15702 29549,15448 30719,15956 29549,16465 29549,16210 26042,16210 26042,15702 Z M 26042,15448 L 26042,15448 Z M 30719,16465 L 30719,16465 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 26042,15702 L 29549,15702 29549,15448 30719,15956 29549,16465 29549,16210 26042,16210 26042,15702 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 26042,15448 L 26042,15448 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 30719,16465 L 30719,16465 Z"/>
       </g>
      </g>
      <g class="com.sun.star.drawing.CustomShape">
       <g id="id14">
        <rect class="BoundingBox" stroke="none" fill="none" x="34881" y="13063" width="1020" height="2894"/>
        <path fill="rgb(0,0,0)" stroke="none" d="M 35136,15955 L 35136,13787 34882,13787 35390,13064 35899,13787 35644,13787 35644,15955 35136,15955 Z M 34882,15955 L 34882,15955 Z M 35899,13064 L 35899,13064 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 35136,15955 L 35136,13787 34882,13787 35390,13064 35899,13787 35644,13787 35644,15955 35136,15955 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 34882,15955 L 34882,15955 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 35899,13064 L 35899,13064 Z"/>
       </g>
      </g>
      <g class="com.sun.star.drawing.CustomShape">
       <g id="id15">
        <rect class="BoundingBox" stroke="none" fill="none" x="34882" y="10259" width="1020" height="2798"/>
        <path fill="rgb(0,0,0)" stroke="none" d="M 35137,13055 L 35137,10959 34883,10959 35391,10260 35900,10959 35645,10959 35645,13055 35137,13055 Z M 34883,13055 L 34883,13055 Z M 35900,10260 L 35900,10260 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 35137,13055 L 35137,10959 34883,10959 35391,10260 35900,10959 35645,10959 35645,13055 35137,13055 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 34883,13055 L 34883,13055 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 35900,10260 L 35900,10260 Z"/>
       </g>
      </g>
      <g class="com.sun.star.drawing.CustomShape">
       <g id="id16">
        <rect class="BoundingBox" stroke="none" fill="none" x="25480" y="15959" width="1020" height="2798"/>
        <path fill="rgb(0,0,0)" stroke="none" d="M 25735,18755 L 25735,16659 25481,16659 25989,15960 26498,16659 26243,16659 26243,18755 25735,18755 Z M 25481,18755 L 25481,18755 Z M 26498,15960 L 26498,15960 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 25735,18755 L 25735,16659 25481,16659 25989,15960 26498,16659 26243,16659 26243,18755 25735,18755 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 25481,18755 L 25481,18755 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 26498,15960 L 26498,15960 Z"/>
       </g>
      </g>
      <g class="com.sun.star.drawing.CustomShape">
       <g id="id17">
        <rect class="BoundingBox" stroke="none" fill="none" x="30742" y="15448" width="4576" height="1020"/>
        <path fill="rgb(0,0,0)" stroke="none" d="M 30743,15703 L 34172,15703 34172,15449 35316,15957 34172,16466 34172,16211 30743,16211 30743,15703 Z M 30743,15449 L 30743,15449 Z M 35316,16466 L 35316,16466 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 30743,15703 L 34172,15703 34172,15449 35316,15957 34172,16466 34172,16211 30743,16211 30743,15703 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 30743,15449 L 30743,15449 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 35316,16466 L 35316,16466 Z"/>
       </g>
      </g>
      <g class="com.sun.star.drawing.CustomShape">
       <g id="id18">
        <rect class="BoundingBox" stroke="none" fill="none" x="21340" y="18246" width="4576" height="1020"/>
        <path fill="rgb(0,0,0)" stroke="none" d="M 21341,18501 L 24770,18501 24770,18247 25914,18755 24770,19264 24770,19009 21341,19009 21341,18501 Z M 21341,18247 L 21341,18247 Z M 25914,19264 L 25914,19264 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 21341,18501 L 24770,18501 24770,18247 25914,18755 24770,19264 24770,19009 21341,19009 21341,18501 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 21341,18247 L 21341,18247 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 25914,19264 L 25914,19264 Z"/>
       </g>
      </g>
      <g class="com.sun.star.drawing.CustomShape">
       <g id="id19">
        <rect class="BoundingBox" stroke="none" fill="none" x="21012" y="18808" width="639" height="1866"/>
        <path fill="rgb(250,166,26)" stroke="none" d="M 21172,20671 L 21172,19274 21013,19274 21331,18809 21649,19274 21490,19274 21490,20671 21172,20671 Z M 21013,18809 L 21013,18809 Z M 21649,20672 L 21649,20672 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 21172,20671 L 21172,19274 21013,19274 21331,18809 21649,19274 21490,19274 21490,20671 21172,20671 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 21013,18809 L 21013,18809 Z"/>
        <path fill="none" stroke="rgb(52,101,164)" d="M 21649,20672 L 21649,20672 Z"/>
       </g>
      </g>
     </g>
    </g>
   </g>
  </g>
 </g>
</svg>
</center>

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
sont donc deux façons équivalentes permettant de décrire les mêmes langages.

### Automates finis non-déterministes

La figure suivante représente un automate fini non-déterministe qui décrit les commentaires en C de type `/*...*/`. On suppose, pour simplifier, que notre vocabulaire
est $\mathcal{V} = \\{ a, b, /, * \\}$.
Sur cette figure on peut voir les éléments suivants :

* Des <span style="color:green">**états**</span>, les cercles sur la figure, numérotés de `0` à `7` pour cet exemple. On peut y voir l'<span style="color:green">**état de départ**</span>, l'état `0`, qui possède une flèche qui arrive sur l'état `0`
mais qui part d'aucun autre état. L'état `7` est un <span style="color:green">**état d'acceptation**</span>, il est représenté par un double cercle.

* Des <span style="color:green">**transitions**</span> entre états, les flèches sur la figure.




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

### Automates finis déterministes

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


### Passage d'un automate à une expression régulière

Nous allons décrire plus en détail les liens entre expressions régulières et automates dans les vidéos ci-dessous, mais nous
pouvons retrouver l'expression régulière permettant de décrire les commentaires en C automatiquement à partir d'un automate fini (déterministe ou non-déterministe).
Nous montrons ci-dessous une suite de transformations permettant de passer de l'automate fini déterministe vu plus haut vers une expression régulière équivalente.
On peut voir sur les transitions apparaître des expressions régulières au fur et à mesure des transformations. Pour ne pas confondre le caractère `*` avec l'opérateur
<span style="color:green">*</span>, nous avons écrit l'opérateur en vert.

<center>
<svg
   xmlns:dc="http://purl.org/dc/elements/1.1/"
   xmlns:cc="http://creativecommons.org/ns#"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:xlink="http://www.w3.org/1999/xlink"
   id="svg1042"
   version="1.1"
   viewBox="0 0 379.67194 94.835373"
   height="auto"
   width="479.67194pt">
  <metadata
     id="metadata1046">
    <rdf:RDF>
      <cc:Work
         rdf:about="">
        <dc:format>image/svg+xml</dc:format>
        <dc:type
           rdf:resource="http://purl.org/dc/dcmitype/StillImage" />
        <dc:title></dc:title>
      </cc:Work>
    </rdf:RDF>
  </metadata>
  <defs
     id="defs973">
    <g
       id="g971">
      <symbol
         style="overflow:visible"
         id="glyph0-0"
         overflow="visible">
        <path
           id="path941"
           d=""
           style="stroke:none" />
      </symbol>
      <symbol
         style="overflow:visible"
         id="glyph0-1"
         overflow="visible">
        <path
           id="path944"
           d="m 5.265625,-5.15625 c 0,-0.0625 -0.046875,-0.109375 -0.109375,-0.109375 -0.09375,0 -0.546875,0.4375 -0.78125,0.859375 -0.21875,-0.546875 -0.578125,-0.859375 -1.09375,-0.859375 -1.359375,0 -2.8125,1.734375 -2.8125,3.515625 0,1.171875 0.6875,1.875 1.5,1.875 0.640625,0 1.15625,-0.484375 1.40625,-0.765625 L 3.390625,-0.625 2.9375,1.171875 2.828125,1.609375 c -0.109375,0.34375 -0.28125,0.34375 -0.84375,0.359375 -0.125,0 -0.25,0 -0.25,0.234375 0,0.078125 0.078125,0.109375 0.15625,0.109375 0.171875,0 0.375,-0.015625 0.546875,-0.015625 h 1.21875 c 0.1875,0 0.390625,0.015625 0.5625,0.015625 0.078125,0 0.21875,0 0.21875,-0.21875 0,-0.125 -0.09375,-0.125 -0.28125,-0.125 -0.5625,0 -0.59375,-0.078125 -0.59375,-0.171875 0,-0.0625 0.015625,-0.078125 0.046875,-0.234375 z m -1.6875,3.734375 C 3.53125,-1.21875 3.53125,-1.1875 3.359375,-0.96875 3.09375,-0.640625 2.5625,-0.125 2.015625,-0.125 1.515625,-0.125 1.25,-0.5625 1.25,-1.265625 c 0,-0.65625 0.359375,-2 0.59375,-2.5 0.40625,-0.84375 0.96875,-1.265625 1.4375,-1.265625 0.78125,0 0.9375,0.984375 0.9375,1.078125 0,0.015625 -0.03125,0.15625 -0.046875,0.1875 z m 0,0"
           style="stroke:none" />
      </symbol>
      <symbol
         style="overflow:visible"
         id="glyph0-2"
         overflow="visible">
        <path
           id="path947"
           d="m 5.53125,-3.03125 c 0,-1.15625 -0.65625,-2.234375 -1.921875,-2.234375 -1.5625,0 -3.125,1.703125 -3.125,3.40625 0,1.03125 0.640625,1.984375 1.859375,1.984375 0.734375,0 1.625,-0.296875 2.46875,-1.015625 C 4.984375,-0.21875 5.359375,0.125 5.875,0.125 c 0.640625,0 0.96875,-0.671875 0.96875,-0.828125 0,-0.109375 -0.09375,-0.109375 -0.125,-0.109375 -0.09375,0 -0.109375,0.03125 -0.140625,0.125 C 6.46875,-0.375 6.1875,-0.125 5.90625,-0.125 c -0.375,0 -0.375,-0.765625 -0.375,-1.484375 1.21875,-1.46875 1.515625,-2.96875 1.515625,-2.984375 0,-0.109375 -0.109375,-0.109375 -0.140625,-0.109375 -0.109375,0 -0.109375,0.046875 -0.171875,0.25 -0.140625,0.53125 -0.453125,1.46875 -1.203125,2.4375 z m -0.75,1.859375 c -1.046875,0.9375 -2,1.046875 -2.421875,1.046875 -0.84375,0 -1.078125,-0.75 -1.078125,-1.3125 0,-0.515625 0.265625,-1.734375 0.625,-2.390625 0.5,-0.828125 1.171875,-1.203125 1.703125,-1.203125 1.15625,0 1.15625,1.515625 1.15625,2.515625 0,0.296875 -0.015625,0.609375 -0.015625,0.90625 0,0.25 0.015625,0.3125 0.03125,0.4375 z m 0,0"
           style="stroke:none" />
      </symbol>
      <symbol
         style="overflow:visible"
         id="glyph0-3"
         overflow="visible">
        <path
           id="path950"
           d="m 6.765625,-6.953125 c 0,-0.71875 -0.609375,-1.46875 -1.703125,-1.46875 -1.53125,0 -2.515625,1.890625 -2.828125,3.125 l -1.890625,7.5 C 0.328125,2.296875 0.390625,2.3125 0.453125,2.3125 c 0.078125,0 0.140625,0 0.15625,-0.0625 l 0.84375,-3.34375 C 1.5625,-0.4375 2.21875,0.125 2.921875,0.125 4.640625,0.125 6.25,-1.21875 6.25,-3 6.25,-3.453125 6.140625,-3.90625 5.890625,-4.296875 5.75,-4.515625 5.5625,-4.6875 5.375,-4.828125 c 0.859375,-0.453125 1.390625,-1.1875 1.390625,-2.125 z M 4.6875,-4.84375 C 4.5,-4.765625 4.296875,-4.75 4.078125,-4.75 3.90625,-4.75 3.75,-4.734375 3.53125,-4.8125 c 0.125,-0.078125 0.3125,-0.09375 0.5625,-0.09375 0.203125,0 0.421875,0.015625 0.59375,0.0625 z M 6.140625,-7.0625 c 0,0.65625 -0.3125,1.609375 -1.09375,2.046875 C 4.8125,-5.09375 4.5,-5.15625 4.25,-5.15625 4,-5.15625 3.28125,-5.171875 3.28125,-4.796875 3.28125,-4.46875 3.9375,-4.5 4.140625,-4.5 c 0.3125,0 0.578125,-0.078125 0.875,-0.15625 0.375,0.3125 0.546875,0.71875 0.546875,1.3125 0,0.6875 -0.203125,1.25 -0.421875,1.765625 C 4.75,-0.6875 3.8125,-0.125 2.984375,-0.125 c -0.875,0 -1.328125,-0.6875 -1.328125,-1.5 0,-0.109375 0,-0.265625 0.046875,-0.4375 l 0.78125,-3.15625 c 0.390625,-1.5625 1.40625,-2.96875 2.5625,-2.96875 0.859375,0 1.09375,0.59375 1.09375,1.125 z m 0,0"
           style="stroke:none" />
      </symbol>
      <symbol
         style="overflow:visible"
         id="glyph0-4"
         overflow="visible">
        <path
           id="path953"
           d="M 4.515625,-1.453125 C 4.5,-2.046875 4.46875,-2.96875 4.015625,-4.046875 3.78125,-4.640625 3.375,-5.265625 2.5,-5.265625 c -1.46875,0 -2.265625,1.875 -2.265625,2.1875 0,0.109375 0.078125,0.109375 0.109375,0.109375 0.109375,0 0.109375,-0.03125 0.171875,-0.1875 0.25,-0.734375 1.015625,-1.328125 1.84375,-1.328125 1.65625,0 1.890625,1.859375 1.890625,3.03125 0,0.765625 -0.078125,1.015625 -0.15625,1.25 -0.21875,0.734375 -0.609375,2.21875 -0.609375,2.5625 0,0.09375 0.03125,0.203125 0.125,0.203125 0.1875,0 0.28125,-0.40625 0.421875,-0.875 0.28125,-1.046875 0.359375,-1.578125 0.421875,-2.0625 0.03125,-0.28125 0.703125,-2.25 1.65625,-4.125 0.078125,-0.203125 0.25,-0.515625 0.25,-0.5625 0,0 -0.015625,-0.09375 -0.125,-0.09375 -0.015625,0 -0.078125,0 -0.109375,0.046875 -0.015625,0.03125 -0.4375,0.84375 -0.796875,1.65625 -0.171875,0.40625 -0.421875,0.9375 -0.8125,2 z m 0,0"
           style="stroke:none" />
      </symbol>
      <symbol
         style="overflow:visible"
         id="glyph0-5"
         overflow="visible">
        <path
           id="path956"
           d="m 3.109375,-5.21875 c -1.53125,0.375 -2.625,1.96875 -2.625,3.359375 0,1.28125 0.859375,2 1.8125,2 1.40625,0 2.359375,-1.9375 2.359375,-3.515625 0,-1.078125 -0.5,-1.734375 -0.796875,-2.140625 C 3.421875,-6.078125 2.703125,-7 2.703125,-7.5625 c 0,-0.203125 0.15625,-0.5625 0.671875,-0.5625 0.375,0 0.609375,0.125 0.96875,0.328125 0.109375,0.078125 0.375,0.234375 0.53125,0.234375 0.25,0 0.4375,-0.25 0.4375,-0.453125 0,-0.21875 -0.1875,-0.25 -0.609375,-0.34375 -0.5625,-0.125 -0.71875,-0.125 -0.921875,-0.125 -0.203125,0 -1.375,0 -1.375,1.21875 0,0.578125 0.296875,1.265625 0.703125,2.046875 z m 0.125,0.234375 C 3.6875,-4.046875 3.875,-3.6875 3.875,-2.90625 c 0,0.9375 -0.5,2.8125 -1.5625,2.8125 -0.46875,0 -1.140625,-0.3125 -1.140625,-1.421875 0,-0.78125 0.4375,-3.03125 2.0625,-3.46875 z m 0,0"
           style="stroke:none" />
      </symbol>
      <symbol
         style="overflow:visible"
         id="glyph0-6"
         overflow="visible">
        <path
           id="path959"
           d="m 5.296875,-6.015625 c 0,-1.21875 -0.390625,-2.40625 -1.359375,-2.40625 -1.671875,0 -3.453125,3.515625 -3.453125,6.140625 0,0.546875 0.109375,2.40625 1.375,2.40625 1.625,0 3.4375,-3.421875 3.4375,-6.140625 z m -3.625,1.6875 c 0.1875,-0.703125 0.4375,-1.703125 0.90625,-2.5625 0.390625,-0.71875 0.8125,-1.28125 1.34375,-1.28125 0.390625,0 0.65625,0.328125 0.65625,1.484375 0,0.421875 -0.03125,1.015625 -0.375,2.359375 z m 2.4375,0.359375 C 3.8125,-2.796875 3.5625,-2.046875 3.125,-1.296875 2.78125,-0.6875 2.359375,-0.125 1.859375,-0.125 1.5,-0.125 1.1875,-0.40625 1.1875,-1.59375 c 0,-0.765625 0.203125,-1.578125 0.390625,-2.375 z m 0,0"
           style="stroke:none" />
      </symbol>
      <symbol
         style="overflow:visible"
         id="glyph1-0"
         overflow="visible">
        <path
           id="path962"
           d=""
           style="stroke:none" />
      </symbol>
      <symbol
         style="overflow:visible"
         id="glyph1-1"
         overflow="visible">
        <path
           id="path965"
           d="m 2.375,-4.96875 c 0,-0.171875 -0.125,-0.3125 -0.3125,-0.3125 -0.203125,0 -0.4375,0.203125 -0.4375,0.4375 0,0.171875 0.125,0.296875 0.3125,0.296875 0.203125,0 0.4375,-0.1875 0.4375,-0.421875 z m -1.15625,2.921875 -0.4375,1.09375 c -0.046875,0.125 -0.078125,0.21875 -0.078125,0.359375 0,0.390625 0.296875,0.671875 0.71875,0.671875 0.78125,0 1.109375,-1.109375 1.109375,-1.21875 0,-0.078125 -0.0625,-0.109375 -0.125,-0.109375 -0.09375,0 -0.109375,0.0625 -0.140625,0.140625 -0.171875,0.640625 -0.5,0.96875 -0.828125,0.96875 -0.09375,0 -0.1875,-0.046875 -0.1875,-0.25 0,-0.203125 0.0625,-0.34375 0.15625,-0.59375 C 1.484375,-1.1875 1.5625,-1.40625 1.65625,-1.625 l 0.25,-0.640625 c 0.0625,-0.1875 0.171875,-0.4375 0.171875,-0.578125 0,-0.390625 -0.328125,-0.671875 -0.734375,-0.671875 -0.765625,0 -1.109375,1.109375 -1.109375,1.21875 0,0.078125 0.0625,0.109375 0.125,0.109375 0.109375,0 0.109375,-0.046875 0.140625,-0.125 0.21875,-0.765625 0.578125,-0.984375 0.828125,-0.984375 0.109375,0 0.1875,0.046875 0.1875,0.265625 0,0.078125 -0.015625,0.1875 -0.09375,0.4375 z m 0,0"
           style="stroke:none" />
      </symbol>
      <symbol
         style="overflow:visible"
         id="glyph1-2"
         overflow="visible">
        <path
           id="path968"
           d="m 3.296875,-4.96875 c 0,-0.15625 -0.125,-0.3125 -0.3125,-0.3125 -0.25,0 -0.453125,0.234375 -0.453125,0.4375 0,0.15625 0.125,0.296875 0.3125,0.296875 0.234375,0 0.453125,-0.21875 0.453125,-0.421875 z M 1.625,0.390625 c -0.125,0.5 -0.515625,1.015625 -1,1.015625 -0.125,0 -0.25,-0.03125 -0.265625,-0.046875 0.25,-0.109375 0.28125,-0.328125 0.28125,-0.40625 0,-0.1875 -0.140625,-0.296875 -0.3125,-0.296875 -0.21875,0 -0.4375,0.203125 -0.4375,0.46875 0,0.296875 0.296875,0.5 0.75,0.5 C 1.125,1.625 2,1.328125 2.234375,0.359375 l 0.71875,-2.84375 C 2.984375,-2.578125 3,-2.640625 3,-2.765625 c 0,-0.4375 -0.359375,-0.75 -0.8125,-0.75 -0.84375,0 -1.34375,1.109375 -1.34375,1.21875 0,0.078125 0.0625,0.109375 0.125,0.109375 0.078125,0 0.09375,-0.03125 0.140625,-0.140625 0.25,-0.5625 0.65625,-0.96875 1.046875,-0.96875 0.171875,0 0.265625,0.125 0.265625,0.375 0,0.109375 -0.015625,0.234375 -0.046875,0.34375 z m 0,0"
           style="stroke:none" />
      </symbol>
    </g>
  </defs>
  <g
     transform="translate(-75.386688,-66.222122)"
     id="surface1">
    <path
       id="path975"
       transform="matrix(1,0,0,-1,48.373,-42.792)"
       d="m 61.228563,-158.74122 c 0,9.39453 -7.613282,17.00781 -17.007813,17.00781 -9.394531,0 -17.007812,-7.61328 -17.007812,-17.00781 0,-9.39062 7.613281,-17.00781 17.007812,-17.00781 9.394531,0 17.007813,7.61719 17.007813,17.00781 z m 0,0"
       style="fill:none;stroke:#000000;stroke-width:0.3985;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:10;stroke-opacity:1" />
    <g
       id="g979"
       style="fill:#000000;fill-opacity:1">
      <use
         height="100%"
         width="100%"
         id="use977"
         y="117.357"
         x="88.306999"
         xlink:href="#glyph0-1" />
    </g>
    <g
       id="g983"
       style="fill:#000000;fill-opacity:1">
      <use
         height="100%"
         width="100%"
         id="use981"
         y="119.15"
         x="93.497002"
         xlink:href="#glyph1-1" />
    </g>
    <path
       id="path985"
       transform="matrix(1,0,0,-1,48.373,-42.792)"
       d="m 406.48637,-158.74122 c 0,9.39453 -7.61328,17.00781 -17.00781,17.00781 -9.39453,0 -17.00781,-7.61328 -17.00781,-17.00781 0,-9.39062 7.61328,-17.00781 17.00781,-17.00781 9.39453,0 17.00781,7.61719 17.00781,17.00781 z m 0,0"
       style="fill:none;stroke:#000000;stroke-width:0.3985;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:10;stroke-opacity:1" />
    <g
       id="g989"
       style="fill:#000000;fill-opacity:1">
      <use
         height="100%"
         width="100%"
         id="use987"
         y="116.847"
         x="433.061"
         xlink:href="#glyph0-1" />
    </g>
    <g
       id="g993"
       style="fill:#000000;fill-opacity:1">
      <use
         height="100%"
         width="100%"
         id="use991"
         y="118.641"
         x="438.25101"
         xlink:href="#glyph1-2" />
    </g>
    <path
       id="path995"
       transform="matrix(1,0,0,-1,48.373,-42.792)"
       d="m 225.06841,-158.74122 c 0,9.39453 -7.61329,17.00781 -17.00782,17.00781 -9.39062,0 -17.00781,-7.61328 -17.00781,-17.00781 0,-9.39062 7.61719,-17.00781 17.00781,-17.00781 9.39453,0 17.00782,7.61719 17.00782,17.00781 z m 0,0"
       style="fill:none;stroke:#000000;stroke-width:0.3985;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:10;stroke-opacity:1" />
    <g
       id="g999"
       style="fill:#000000;fill-opacity:1">
      <use
         height="100%"
         width="100%"
         id="use997"
         y="117.357"
         x="253.623"
         xlink:href="#glyph0-1" />
    </g>
    <path
       id="path1001"
       transform="matrix(1,0,0,-1,48.373,-42.792)"
       d="m 59.259813,-150.81934 c 42.433597,19.53515 91.316407,19.53515 133.749997,0"
       style="fill:none;stroke:#000000;stroke-width:0.3985;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:10;stroke-opacity:1" />
    <path
       id="path1003"
       d="m 241.41016,108.01172 -2.94532,-4.48047 -2.38281,5.16016"
       style="fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none" />
    <g
       id="g1007"
       style="fill:#000000;fill-opacity:1">
      <use
         height="100%"
         width="100%"
         id="use1005"
         y="90.348"
         x="170.752"
         xlink:href="#glyph0-2" />
    </g>
    <path
       id="path1009"
       transform="matrix(1,0,0,-1,48.373,-42.792)"
       d="m 194.68169,-169.21778 c -41.39844,-27.99609 -95.671877,-27.99609 -137.070315,0"
       style="fill:none;stroke:#000000;stroke-width:0.3985;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:10;stroke-opacity:1" />
    <path
       id="path1011"
       d="m 105.97266,126.4375 2.15625,4.875 3.17187,-4.70703"
       style="fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none" />
    <g
       id="g1015"
       style="fill:#000000;fill-opacity:1">
      <use
         height="100%"
         width="100%"
         id="use1013"
         y="158.745"
         x="170.877"
         xlink:href="#glyph0-3" />
    </g>
    <path
       id="path1017"
       transform="matrix(1,0,0,-1,48.373,-42.792)"
       d="m 223.72466,-152.12794 c 48.35937,18.16016 101.71093,18.16016 150.07031,0"
       style="fill:none;stroke:#000000;stroke-width:0.3985;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:10;stroke-opacity:1" />
    <path
       id="path1019"
       d="m 422.20312,109.31641 -3.28515,-4.25391 -1.98438,5.32813"
       style="fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none" />
    <g
       id="g1023"
       style="fill:#000000;fill-opacity:1">
      <use
         height="100%"
         width="100%"
         id="use1021"
         y="90.348"
         x="343.77899"
         xlink:href="#glyph0-4" />
    </g>
    <path
       id="path1025"
       transform="matrix(1,0,0,-1,48.373,-42.792)"
       d="m 374.77934,-167.28419 c -47.6875,-24.54297 -104.32422,-24.54297 -152.01172,0"
       style="fill:none;stroke:#000000;stroke-width:0.3985;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:10;stroke-opacity:1" />
    <path
       id="path1027"
       d="m 271.11719,124.50781 2.78125,4.59375 2.55078,-5.04687"
       style="fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none" />
    <g
       id="g1031"
       style="fill:#000000;fill-opacity:1">
      <use
         height="100%"
         width="100%"
         id="use1029"
         y="154.21001"
         x="344.323"
         xlink:href="#glyph0-5" />
    </g>
    <path
       id="path1033"
       transform="matrix(1,0,0,-1,48.373,-42.792)"
       d="m 200.56059,-143.54591 c -5.69922,4.14063 -6.96093,12.11719 -2.82031,17.81641 4.14063,5.69922 12.11719,6.96484 17.81641,2.82422 3.6875,-2.67969 5.66406,-7.12109 5.1875,-11.65625 -0.375,-3.59375 -2.26172,-6.85938 -5.1875,-8.98438"
       style="fill:none;stroke:#000000;stroke-width:0.3985;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:10;stroke-opacity:1" />
    <g
       id="g1037"
       style="fill:#000000;fill-opacity:1">
      <use
         height="100%"
         width="100%"
         id="use1035"
         y="74.643997"
         x="253.54201"
         xlink:href="#glyph0-6" />
    </g>
    <path
       id="path1039"
       d="m 263.91797,100.75391 4.98828,-1.984379 -4.58984,-3.34375"
       style="fill:#000000;fill-opacity:1;fill-rule:nonzero;stroke:none" />
  </g>
</svg>
</center>

<center>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="394.944pt" height="128.827pt" viewBox="0 0 394.944 128.827" version="1.1">
<defs>
<g>
<symbol overflow="visible" id="glyph0-0">
<path style="stroke:none;" d=""/>
</symbol>
<symbol overflow="visible" id="glyph0-1">
<path style="stroke:none;" d="M 4.5 -4.296875 C 4.5 -4.34375 4.46875 -4.390625 4.40625 -4.390625 C 4.296875 -4.390625 3.890625 -4 3.734375 -3.703125 C 3.515625 -4.25 3.125 -4.40625 2.796875 -4.40625 C 1.625 -4.40625 0.40625 -2.9375 0.40625 -1.484375 C 0.40625 -0.515625 0.984375 0.109375 1.71875 0.109375 C 2.140625 0.109375 2.53125 -0.125 2.890625 -0.484375 C 2.796875 -0.140625 2.46875 1.203125 2.4375 1.296875 C 2.359375 1.578125 2.28125 1.609375 1.71875 1.625 C 1.59375 1.625 1.5 1.625 1.5 1.828125 C 1.5 1.828125 1.5 1.9375 1.625 1.9375 C 1.9375 1.9375 2.296875 1.90625 2.625 1.90625 C 2.953125 1.90625 3.3125 1.9375 3.65625 1.9375 C 3.703125 1.9375 3.828125 1.9375 3.828125 1.734375 C 3.828125 1.625 3.734375 1.625 3.5625 1.625 C 3.09375 1.625 3.09375 1.5625 3.09375 1.46875 C 3.09375 1.390625 3.109375 1.328125 3.125 1.25 Z M 1.75 -0.109375 C 1.140625 -0.109375 1.109375 -0.875 1.109375 -1.046875 C 1.109375 -1.53125 1.390625 -2.609375 1.5625 -3.03125 C 1.875 -3.765625 2.390625 -4.1875 2.796875 -4.1875 C 3.453125 -4.1875 3.59375 -3.375 3.59375 -3.3125 C 3.59375 -3.25 3.046875 -1.0625 3.015625 -1.03125 C 2.859375 -0.75 2.296875 -0.109375 1.75 -0.109375 Z M 1.75 -0.109375 "/>
</symbol>
<symbol overflow="visible" id="glyph0-2">
<path style="stroke:none;" d="M 4.75 -2.359375 C 4.75 -3.921875 3.828125 -4.40625 3.09375 -4.40625 C 1.71875 -4.40625 0.40625 -2.984375 0.40625 -1.578125 C 0.40625 -0.640625 1 0.109375 2.03125 0.109375 C 2.65625 0.109375 3.375 -0.125 4.125 -0.734375 C 4.25 -0.203125 4.578125 0.109375 5.03125 0.109375 C 5.5625 0.109375 5.875 -0.4375 5.875 -0.59375 C 5.875 -0.671875 5.8125 -0.703125 5.75 -0.703125 C 5.6875 -0.703125 5.65625 -0.671875 5.625 -0.59375 C 5.4375 -0.109375 5.078125 -0.109375 5.0625 -0.109375 C 4.75 -0.109375 4.75 -0.890625 4.75 -1.125 C 4.75 -1.328125 4.75 -1.359375 4.859375 -1.46875 C 5.796875 -2.65625 6 -3.8125 6 -3.8125 C 6 -3.84375 5.984375 -3.921875 5.875 -3.921875 C 5.78125 -3.921875 5.78125 -3.890625 5.734375 -3.703125 C 5.546875 -3.078125 5.21875 -2.328125 4.75 -1.734375 Z M 4.09375 -0.984375 C 3.203125 -0.21875 2.4375 -0.109375 2.046875 -0.109375 C 1.453125 -0.109375 1.140625 -0.5625 1.140625 -1.203125 C 1.140625 -1.6875 1.40625 -2.765625 1.71875 -3.265625 C 2.1875 -4 2.734375 -4.1875 3.078125 -4.1875 C 4.0625 -4.1875 4.0625 -2.875 4.0625 -2.109375 C 4.0625 -1.734375 4.0625 -1.15625 4.09375 -0.984375 Z M 4.09375 -0.984375 "/>
</symbol>
<symbol overflow="visible" id="glyph0-3">
<path style="stroke:none;" d="M 4.53125 -4.984375 C 4.53125 -5.640625 4.359375 -7.03125 3.34375 -7.03125 C 1.953125 -7.03125 0.421875 -4.21875 0.421875 -1.9375 C 0.421875 -1 0.703125 0.109375 1.609375 0.109375 C 3.015625 0.109375 4.53125 -2.75 4.53125 -4.984375 Z M 1.46875 -3.625 C 1.640625 -4.25 1.84375 -5.046875 2.25 -5.765625 C 2.515625 -6.25 2.875 -6.8125 3.328125 -6.8125 C 3.8125 -6.8125 3.875 -6.171875 3.875 -5.609375 C 3.875 -5.109375 3.796875 -4.609375 3.5625 -3.625 Z M 3.46875 -3.296875 C 3.359375 -2.84375 3.15625 -2 2.765625 -1.28125 C 2.421875 -0.59375 2.046875 -0.109375 1.609375 -0.109375 C 1.28125 -0.109375 1.078125 -0.40625 1.078125 -1.328125 C 1.078125 -1.75 1.140625 -2.328125 1.390625 -3.296875 Z M 3.46875 -3.296875 "/>
</symbol>
<symbol overflow="visible" id="glyph0-4">
<path style="stroke:none;" d="M 0.40625 -2.53125 C 0.796875 -3.671875 1.890625 -3.6875 2 -3.6875 C 3.5 -3.6875 3.609375 -1.9375 3.609375 -1.15625 C 3.609375 -0.546875 3.5625 -0.375 3.484375 -0.171875 C 3.265625 0.546875 2.96875 1.703125 2.96875 1.96875 C 2.96875 2.078125 3.015625 2.140625 3.09375 2.140625 C 3.234375 2.140625 3.3125 1.921875 3.421875 1.546875 C 3.65625 0.703125 3.75 0.140625 3.78125 -0.171875 C 3.8125 -0.296875 3.828125 -0.421875 3.875 -0.5625 C 4.1875 -1.546875 4.828125 -3.03125 5.21875 -3.8125 C 5.296875 -3.9375 5.40625 -4.15625 5.40625 -4.203125 C 5.40625 -4.296875 5.3125 -4.296875 5.296875 -4.296875 C 5.265625 -4.296875 5.203125 -4.296875 5.171875 -4.234375 C 4.65625 -3.28125 4.25 -2.28125 3.859375 -1.28125 C 3.84375 -1.578125 3.84375 -2.34375 3.453125 -3.3125 C 3.203125 -3.921875 2.8125 -4.40625 2.125 -4.40625 C 0.875 -4.40625 0.171875 -2.890625 0.171875 -2.578125 C 0.171875 -2.484375 0.265625 -2.484375 0.375 -2.484375 Z M 0.40625 -2.53125 "/>
</symbol>
<symbol overflow="visible" id="glyph0-5">
<path style="stroke:none;" d="M 2.625 -4.359375 C 1.390625 -4.0625 0.421875 -2.765625 0.421875 -1.5625 C 0.421875 -0.59375 1.0625 0.125 2 0.125 C 3.15625 0.125 3.984375 -1.453125 3.984375 -2.828125 C 3.984375 -3.734375 3.59375 -4.234375 3.25 -4.671875 C 2.890625 -5.125 2.296875 -5.875 2.296875 -6.3125 C 2.296875 -6.53125 2.5 -6.765625 2.84375 -6.765625 C 3.15625 -6.765625 3.34375 -6.640625 3.5625 -6.5 C 3.765625 -6.375 3.953125 -6.25 4.109375 -6.25 C 4.359375 -6.25 4.5 -6.484375 4.5 -6.65625 C 4.5 -6.875 4.34375 -6.890625 3.984375 -6.984375 C 3.46875 -7.09375 3.328125 -7.09375 3.171875 -7.09375 C 2.390625 -7.09375 2.03125 -6.65625 2.03125 -6.0625 C 2.03125 -5.515625 2.328125 -4.96875 2.625 -4.359375 Z M 2.75 -4.140625 C 3 -3.671875 3.296875 -3.140625 3.296875 -2.421875 C 3.296875 -1.765625 2.921875 -0.09375 2 -0.09375 C 1.453125 -0.09375 1.03125 -0.515625 1.03125 -1.28125 C 1.03125 -1.90625 1.40625 -3.78125 2.75 -4.140625 Z M 2.75 -4.140625 "/>
</symbol>
<symbol overflow="visible" id="glyph0-6">
<path style="stroke:none;" d="M 5.734375 -5.671875 C 5.734375 -6.421875 5.1875 -7.03125 4.375 -7.03125 C 3.796875 -7.03125 3.515625 -6.875 3.171875 -6.625 C 2.625 -6.21875 2.078125 -5.25 1.890625 -4.5 L 0.296875 1.828125 C 0.296875 1.875 0.34375 1.9375 0.421875 1.9375 C 0.5 1.9375 0.53125 1.90625 0.53125 1.890625 L 1.234375 -0.875 C 1.421875 -0.265625 1.859375 0.09375 2.59375 0.09375 C 3.3125 0.09375 4.0625 -0.25 4.515625 -0.6875 C 5 -1.140625 5.3125 -1.78125 5.3125 -2.515625 C 5.3125 -3.234375 4.9375 -3.765625 4.578125 -4 C 5.15625 -4.34375 5.734375 -4.953125 5.734375 -5.671875 Z M 3.9375 -4.015625 C 3.8125 -3.96875 3.703125 -3.953125 3.453125 -3.953125 C 3.3125 -3.953125 3.125 -3.9375 3.015625 -3.984375 C 3.046875 -4.09375 3.40625 -4.0625 3.515625 -4.0625 C 3.71875 -4.0625 3.8125 -4.0625 3.9375 -4.015625 Z M 5.171875 -5.90625 C 5.171875 -5.203125 4.796875 -4.484375 4.28125 -4.171875 C 4 -4.28125 3.8125 -4.296875 3.515625 -4.296875 C 3.296875 -4.296875 2.734375 -4.3125 2.734375 -3.984375 C 2.734375 -3.703125 3.25 -3.734375 3.421875 -3.734375 C 3.796875 -3.734375 3.953125 -3.734375 4.25 -3.859375 C 4.625 -3.5 4.671875 -3.1875 4.6875 -2.734375 C 4.703125 -2.15625 4.46875 -1.40625 4.1875 -1.015625 C 3.796875 -0.484375 3.125 -0.125 2.5625 -0.125 C 1.796875 -0.125 1.421875 -0.703125 1.421875 -1.40625 C 1.421875 -1.5 1.421875 -1.65625 1.46875 -1.84375 L 2.109375 -4.359375 C 2.328125 -5.21875 3.046875 -6.8125 4.25 -6.8125 C 4.828125 -6.8125 5.171875 -6.5 5.171875 -5.90625 Z M 5.171875 -5.90625 "/>
</symbol>
<symbol overflow="visible" id="glyph1-0">
<path style="stroke:none;" d=""/>
</symbol>
<symbol overflow="visible" id="glyph1-1">
<path style="stroke:none;" d="M 2.265625 -4.359375 C 2.265625 -4.46875 2.171875 -4.625 1.984375 -4.625 C 1.796875 -4.625 1.59375 -4.4375 1.59375 -4.234375 C 1.59375 -4.125 1.671875 -3.96875 1.875 -3.96875 C 2.0625 -3.96875 2.265625 -4.171875 2.265625 -4.359375 Z M 0.84375 -0.8125 C 0.8125 -0.71875 0.78125 -0.640625 0.78125 -0.515625 C 0.78125 -0.1875 1.046875 0.0625 1.4375 0.0625 C 2.125 0.0625 2.4375 -0.890625 2.4375 -1 C 2.4375 -1.09375 2.34375 -1.09375 2.328125 -1.09375 C 2.234375 -1.09375 2.21875 -1.046875 2.1875 -0.96875 C 2.03125 -0.40625 1.734375 -0.125 1.453125 -0.125 C 1.3125 -0.125 1.28125 -0.21875 1.28125 -0.375 C 1.28125 -0.53125 1.328125 -0.65625 1.390625 -0.8125 C 1.46875 -1 1.546875 -1.1875 1.609375 -1.375 C 1.671875 -1.546875 1.9375 -2.171875 1.953125 -2.265625 C 1.984375 -2.328125 2 -2.40625 2 -2.484375 C 2 -2.8125 1.71875 -3.078125 1.34375 -3.078125 C 0.640625 -3.078125 0.328125 -2.125 0.328125 -2 C 0.328125 -1.921875 0.421875 -1.921875 0.453125 -1.921875 C 0.546875 -1.921875 0.546875 -1.953125 0.578125 -2.03125 C 0.75 -2.625 1.0625 -2.875 1.3125 -2.875 C 1.421875 -2.875 1.484375 -2.828125 1.484375 -2.640625 C 1.484375 -2.46875 1.453125 -2.375 1.28125 -1.9375 Z M 0.84375 -0.8125 "/>
</symbol>
<symbol overflow="visible" id="glyph1-2">
<path style="stroke:none;" d="M 3.0625 -4.359375 C 3.0625 -4.46875 2.96875 -4.625 2.78125 -4.625 C 2.578125 -4.625 2.390625 -4.421875 2.390625 -4.234375 C 2.390625 -4.125 2.46875 -3.96875 2.671875 -3.96875 C 2.859375 -3.96875 3.0625 -4.15625 3.0625 -4.359375 Z M 1.578125 0.34375 C 1.46875 0.828125 1.09375 1.21875 0.6875 1.21875 C 0.59375 1.21875 0.515625 1.21875 0.4375 1.1875 C 0.609375 1.09375 0.671875 0.9375 0.671875 0.828125 C 0.671875 0.65625 0.53125 0.578125 0.390625 0.578125 C 0.1875 0.578125 0 0.765625 0 0.984375 C 0 1.25 0.265625 1.421875 0.6875 1.421875 C 1.109375 1.421875 1.921875 1.171875 2.140625 0.328125 L 2.765625 -2.171875 C 2.78125 -2.25 2.796875 -2.3125 2.796875 -2.421875 C 2.796875 -2.796875 2.46875 -3.078125 2.0625 -3.078125 C 1.28125 -3.078125 0.84375 -2.109375 0.84375 -2 C 0.84375 -1.921875 0.9375 -1.921875 0.953125 -1.921875 C 1.03125 -1.921875 1.046875 -1.9375 1.09375 -2.046875 C 1.265625 -2.453125 1.625 -2.875 2.03125 -2.875 C 2.203125 -2.875 2.265625 -2.765625 2.265625 -2.53125 C 2.265625 -2.453125 2.265625 -2.359375 2.25 -2.328125 Z M 1.578125 0.34375 "/>
</symbol>
<symbol overflow="visible" id="glyph2-0">
<path style="stroke:none;" d=""/>
</symbol>
<symbol overflow="visible" id="glyph2-1">
<path style="stroke:none;" d="M 2.25 -1.734375 C 2.828125 -1.984375 3.078125 -2.078125 3.25 -2.171875 C 3.390625 -2.21875 3.453125 -2.25 3.453125 -2.390625 C 3.453125 -2.5 3.359375 -2.609375 3.234375 -2.609375 C 3.1875 -2.609375 3.171875 -2.609375 3.09375 -2.546875 L 2.140625 -1.90625 L 2.25 -2.9375 C 2.265625 -3.0625 2.25 -3.234375 2.03125 -3.234375 C 1.953125 -3.234375 1.8125 -3.1875 1.8125 -3.03125 C 1.8125 -2.96875 1.84375 -2.765625 1.859375 -2.6875 C 1.875 -2.578125 1.921875 -2.0625 1.9375 -1.90625 L 0.984375 -2.546875 C 0.921875 -2.578125 0.90625 -2.609375 0.84375 -2.609375 C 0.703125 -2.609375 0.625 -2.5 0.625 -2.390625 C 0.625 -2.25 0.703125 -2.203125 0.765625 -2.1875 L 1.8125 -1.734375 C 1.25 -1.484375 0.984375 -1.390625 0.8125 -1.3125 C 0.6875 -1.25 0.625 -1.21875 0.625 -1.09375 C 0.625 -0.96875 0.703125 -0.875 0.84375 -0.875 C 0.890625 -0.875 0.90625 -0.875 0.984375 -0.9375 L 1.9375 -1.5625 L 1.8125 -0.453125 C 1.8125 -0.296875 1.953125 -0.234375 2.03125 -0.234375 C 2.125 -0.234375 2.25 -0.296875 2.25 -0.453125 C 2.25 -0.515625 2.21875 -0.71875 2.21875 -0.78125 C 2.203125 -0.90625 2.15625 -1.40625 2.140625 -1.5625 L 2.96875 -1.015625 C 3.15625 -0.875 3.171875 -0.875 3.234375 -0.875 C 3.359375 -0.875 3.453125 -0.96875 3.453125 -1.09375 C 3.453125 -1.234375 3.359375 -1.265625 3.296875 -1.296875 Z M 2.25 -1.734375 "/>
</symbol>
</g>
<clipPath id="clip1">
<path d="M 349 39 L 394.945312 39 L 394.945312 85 L 349 85 Z M 349 39 "/>
</clipPath>
</defs>
<g id="surface1">
<path style="fill:none;stroke-width:0.3985;stroke-linecap:butt;stroke-linejoin:miter;stroke:rgb(0%,0%,0%);stroke-opacity:1;stroke-miterlimit:10;" d="M 61.229625 -158.739281 C 61.229625 -149.34475 53.612437 -141.731469 44.221812 -141.731469 C 34.827281 -141.731469 27.214 -149.34475 27.214 -158.739281 C 27.214 -168.133812 34.827281 -175.747094 44.221812 -175.747094 C 53.612437 -175.747094 61.229625 -168.133812 61.229625 -158.739281 Z M 61.229625 -158.739281 " transform="matrix(1,0,0,-1,-17.714,-96.626)"/>
<g style="fill:rgb(0%,0%,0%);fill-opacity:1;">
<use xlink:href="#glyph0-1" x="22.623" y="63.288"/>
</g>
<g style="fill:rgb(0%,0%,0%);fill-opacity:1;">
<use xlink:href="#glyph1-1" x="27.071" y="64.782"/>
</g>
<g clip-path="url(#clip1)" clip-rule="nonzero">
<path style="fill:none;stroke-width:0.3985;stroke-linecap:butt;stroke-linejoin:miter;stroke:rgb(0%,0%,0%);stroke-opacity:1;stroke-miterlimit:10;" d="M 406.487437 -158.739281 C 406.487437 -149.34475 398.874156 -141.731469 389.479625 -141.731469 C 380.085094 -141.731469 372.471812 -149.34475 372.471812 -158.739281 C 372.471812 -168.133812 380.085094 -175.747094 389.479625 -175.747094 C 398.874156 -175.747094 406.487437 -168.133812 406.487437 -158.739281 Z M 406.487437 -158.739281 " transform="matrix(1,0,0,-1,-17.714,-96.626)"/>
</g>
<g style="fill:rgb(0%,0%,0%);fill-opacity:1;">
<use xlink:href="#glyph0-1" x="367.437" y="62.831"/>
</g>
<g style="fill:rgb(0%,0%,0%);fill-opacity:1;">
<use xlink:href="#glyph1-2" x="371.885" y="64.325"/>
</g>
<path style="fill:none;stroke-width:0.3985;stroke-linecap:butt;stroke-linejoin:miter;stroke:rgb(0%,0%,0%);stroke-opacity:1;stroke-miterlimit:10;" d="M 60.206187 -152.9385 C 161.706187 -118.145531 271.979625 -118.145531 373.475719 -152.9385 " transform="matrix(1,0,0,-1,-17.714,-96.626)"/>
<path style=" stroke:none;fill-rule:nonzero;fill:rgb(0%,0%,0%);fill-opacity:1;" d="M 355.777344 56.332031 L 352.433594 52.136719 L 350.5625 57.523438 "/>
<g style="fill:rgb(0%,0%,0%);fill-opacity:1;">
<use xlink:href="#glyph0-2" x="188.305" y="25.223"/>
</g>
<g style="fill:rgb(0%,0%,0%);fill-opacity:1;">
<use xlink:href="#glyph0-3" x="194.717926" y="25.223"/>
</g>
<g style="fill:rgb(0%,59.999084%,0%);fill-opacity:1;">
<use xlink:href="#glyph2-1" x="199.669" y="21.607"/>
</g>
<g style="fill:rgb(0%,0%,0%);fill-opacity:1;">
<use xlink:href="#glyph0-4" x="204.249" y="25.223"/>
</g>
<path style="fill:none;stroke-width:0.3985;stroke-linecap:butt;stroke-linejoin:miter;stroke:rgb(0%,0%,0%);stroke-opacity:1;stroke-miterlimit:10;" d="M 374.811656 -167.352562 C 276.530406 -221.668969 157.178844 -221.668969 58.893687 -167.352562 " transform="matrix(1,0,0,-1,-17.714,-96.626)"/>
<path style=" stroke:none;fill-rule:nonzero;fill:rgb(0%,0%,0%);fill-opacity:1;" d="M 41.191406 70.730469 L 43.796875 75.378906 L 46.519531 70.449219 "/>
<g style="fill:rgb(0%,0%,0%);fill-opacity:1;">
<use xlink:href="#glyph0-5" x="188.883" y="121.443"/>
</g>
<g style="fill:rgb(0%,0%,0%);fill-opacity:1;">
<use xlink:href="#glyph0-3" x="193.688958" y="121.443"/>
</g>
<g style="fill:rgb(0%,59.999084%,0%);fill-opacity:1;">
<use xlink:href="#glyph2-1" x="198.641" y="117.827"/>
</g>
<g style="fill:rgb(0%,0%,0%);fill-opacity:1;">
<use xlink:href="#glyph0-6" x="203.221" y="121.443"/>
</g>
<path style="fill:none;stroke-width:0.3985;stroke-linecap:butt;stroke-linejoin:miter;stroke:rgb(0%,0%,0%);stroke-opacity:1;stroke-miterlimit:10;" d="M 36.721812 -143.547875 C 31.018688 -139.40725 29.756969 -131.426781 33.897594 -125.727562 C 38.038219 -120.028344 46.014781 -118.766625 51.714 -122.90725 C 55.4015 -125.583031 57.378062 -130.028344 56.905406 -134.559594 C 56.5265 -138.153344 54.639781 -141.422875 51.714 -143.547875 " transform="matrix(1,0,0,-1,-17.714,-96.626)"/>
<g style="fill:rgb(0%,0%,0%);fill-opacity:1;">
<use xlink:href="#glyph0-2" x="15.453" y="18.873"/>
</g>
<g style="fill:rgb(0%,0%,0%);fill-opacity:1;">
<use xlink:href="#glyph0-3" x="21.865926" y="18.873"/>
</g>
<g style="fill:rgb(0%,59.999084%,0%);fill-opacity:1;">
<use xlink:href="#glyph2-1" x="26.817" y="15.258"/>
</g>
<g style="fill:rgb(0%,0%,0%);fill-opacity:1;">
<use xlink:href="#glyph0-6" x="31.397" y="18.873"/>
</g>
<path style=" stroke:none;fill-rule:nonzero;fill:rgb(0%,0%,0%);fill-opacity:1;" d="M 33.988281 46.921875 L 38.980469 44.9375 L 34.386719 41.589844 "/>
<path style="fill:none;stroke-width:0.3985;stroke-linecap:butt;stroke-linejoin:miter;stroke:rgb(0%,0%,0%);stroke-opacity:1;stroke-miterlimit:10;" d="M 381.979625 -143.547875 C 376.280406 -139.40725 375.014781 -131.426781 379.155406 -125.727562 C 383.296031 -120.028344 391.2765 -118.766625 396.975719 -122.90725 C 400.659312 -125.583031 402.639781 -130.028344 402.163219 -134.559594 C 401.784312 -138.153344 399.897594 -141.422875 396.975719 -143.547875 " transform="matrix(1,0,0,-1,-17.714,-96.626)"/>
<g style="fill:rgb(0%,0%,0%);fill-opacity:1;">
<use xlink:href="#glyph0-5" x="361.735" y="18.873"/>
</g>
<g style="fill:rgb(0%,0%,0%);fill-opacity:1;">
<use xlink:href="#glyph0-3" x="366.540958" y="18.873"/>
</g>
<g style="fill:rgb(0%,59.999084%,0%);fill-opacity:1;">
<use xlink:href="#glyph2-1" x="371.493" y="15.258"/>
</g>
<g style="fill:rgb(0%,0%,0%);fill-opacity:1;">
<use xlink:href="#glyph0-4" x="376.073" y="18.873"/>
</g>
<path style=" stroke:none;fill-rule:nonzero;fill:rgb(0%,0%,0%);fill-opacity:1;" d="M 379.25 46.921875 L 384.238281 44.9375 L 379.644531 41.589844 "/>
</g>
</svg>
</center>

## Identification de motifs

## Analyseur lexical avec ocamllex

## Ressources

{{% notice info %}}
[Jouer avec les expressions régulières](https://regexcrossword.com/)\
[Tester des expressions régulières](https://regex101.com/)\
{{% /notice %}}