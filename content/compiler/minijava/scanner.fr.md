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

{{< figure src="/images/minijava/scanner/nfa_comments.svg" width="800px" height="auto">}}



### Automates finis déterministes

{{< figure src="/images/minijava/scanner/dfa_comments.svg" width="800px" height="auto">}}


### Passage d'un automate à une expression régulière

Nous allons décrire plus en détail les liens entre expressions régulières et automates dans les vidéos ci-dessous, mais nous
pouvons retrouver l'expression régulière permettant de décrire les commentaires en C automatiquement à partir d'un automate fini (déterministe ou non-déterministe).
Nous montrons ci-dessous une suite de transformations permettant de passer de l'automate fini déterministe vu plus haut vers une expression régulière équivalente.
On peut voir sur les transitions apparaître des expressions régulières au fur et à mesure des transformations. Pour ne pas confondre le caractère `*` avec l'opérateur
<span style="color:green">*</span>, nous avons écrit l'opérateur en vert.

{{< figure src="/images/minijava/scanner/automata_to_regex1.svg" width="800px" height="auto">}}

{{< figure src="/images/minijava/scanner/automata_to_regex2.svg" width="800px" height="auto">}}

<!-- {{< figure src="/images/minijava/scanner/automata_to_regex3.svg" width="300px" height="auto">}} -->

{{< figure src="/images/minijava/scanner/dfa_comments.svg" width="800px" height="auto">}}

{{< figure src="/images/minijava/scanner/dfa_comments_to_regex1.svg" width="800px" height="auto">}}

{{< figure src="/images/minijava/scanner/dfa_comments_to_regex2.svg" width="800px" height="auto">}}

{{< figure src="/images/minijava/scanner/dfa_comments_to_regex3.svg" width="800px" height="auto">}}

## Identification de motifs

## Analyseur lexical avec ocamllex

## Ressources

{{% notice info %}}
[Jouer avec les expressions régulières](https://regexcrossword.com/)\
[Tester des expressions régulières](https://regex101.com/)\
{{% /notice %}}