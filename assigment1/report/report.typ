
// això és el Latex look, per si canviem d'opinió.
#set page(
    header: context{
        if counter(page).get().first() > 1 [
            _Arnau Pérez, Pau Soler - GDMS_ 
            #h(1fr)
            SCA, UPC
        ]
    },
    paper: "a4",
    numbering: "1",
    margin: 1.25in,
)


#set par(leading: 0.55em, spacing: 0.55em, first-line-indent: 1.8em, justify: true)
#set heading(numbering: "1.")
#show heading: set block(above: 1.4em, below: 1em)

#align(center, text(17pt)[
  *Projecte Sobre Weibull de Simulació* 
])

#align(center)[
    #stack(
        spacing: 0.65em,
        [_Arnau Pérez Reverte, Pau Soler Valadés_],
        [_04-12-2025_],
        [_Simulació, MESIO UPC-UB_]
    )
]



= Introducció

#lorem(50)

= Objectiu (Aims)

L'objectiu principal del següent estudi de simulació és l'estudi
de la inferència dels paràmetres d'una distribució de Weibull mitjançant el mètode Median Ranks Regression (MRR). Amb aquesta finalitat, es desenvoluparà la teoria al voltant d'aquesta distribució de probabilitat, es definirà aquest procediment d'inferència en detall i s'avaluarà la qualitat del seus resultats mitjançant una sèrie de mètriques, així com es compararà amb el mètode ordinari de inferència del Maximum Likelihood Estimation (MLE).

= Generació de Dades (Data-generating mechanisms)

== La distribució de Weibull 
Diem que una variable aleatòria contínua $X$ segueix una distribució de Weibull de paràmetres $alpha$ i $beta$, $X ~ "Weibull"(alpha, beta)$, si té funció de densitat de probabilitat (pdf)

$
f_X (x; alpha, beta) = (beta/alpha)(x/alpha)^(beta - 1) exp(-(x/alpha)^(beta))1_(\{x > 0\}),
$

on $alpha > 0$ i $beta > 0$ són els paràmetres scale i shape, respectivament. S'observa aleshores que la seva funció de distribució de probabilitat (cdf) pren la forma 
$
F_X (x) = 1 - exp(-x/alpha)^beta.
$
La distribució de Weibull, amb els seu suport al nombres reals positius, resulta a la pràctica molt útil per modelitzar el concepte de "temps de vida" en contextos com control de qualitat, epidemiologia, entre d'altres. Els seus paràmetres a més a més es poden, en aquesta idea mateixa idea, caracteritzar i interpretar de la forma següent:
\
    - $alpha$ (Scale): També conegut com vida característica, pren unitats d'acord al context del problema, és a dir, ja sigui perque estem modelitzant segons, minuts, hores, cicles, etc.
    - $beta$ (Shape): En el nostre context, $beta$ és un paràmetre adimensional conegut com la proporció de fallada, i que modifica el comportament de la distrbució de Weibull de la següent forma en funció del tres casos:

        1. **$beta < 1$**: Proporció de fallada decreixent/"mortalitat infantil". Com major és el temps de supervivència de la unitat, menor és la probabilitat de que mori/falli en el següent instant.
        2. **$beta = 1$**: Proporció de fallada constant. Simplifica la distribució de Weibull a una $"Exp"(1/alpha)$, simbolitzant que el temps de supervivència és aleatori i independent de temps transcorregut.
        3. $beta > 1$:  Proporció de fallada creixent. La probabilitat de mort creix a mesura que el temps incrementa. Representa unitats/individus que empitjoren amb el pas del temps.

Com ja s'ha descrit, la distribució de Weibull es s'utilitza en el contexte del temps i en conseqüència manté una relació molt estreta amb altres distribucions utilizades amb aquesta mateixa idea. Es destaca, en particular: (TODO REVISAR)

    + $"Weibull"(alpha, 1) = "Exp"(1/alpha)$
    + $X ~ "Weibull"(sqrt(2)beta, 2) = "Rayleigh"(beta)$

== Mètode de generació de nombres aleatòries

Per tal de simular valors de la distribució de Weibull, s'utilitzarà el mètode de distribució inversa. En efecte, el mètode empra la composició de dues funcions: la funció de densitat d'una distribució uniforme $U(0,1)$ juntament amb la inversa de la funció de probabilitat $F$ de la distribució que es vulgui generar. Una variable aleatòria $U ~ U(0,1)$ té la densitat $f_U$ següent:

$ f_U (x) = 1I_{0 <= x <= 1} (x) $

i està definida en $f_U: RR |-> [0,1]$, i una CDF seguint una variable aleatòria $X$ està definida a $F_X: RR |-> [0,1]$, i la seva inversa per tant a $F^(-1)_X: [0,1] |-> RR$. Aleshores, la seva composició

$ F^(-1)_X compose f_U ~ X $

$ F^(-1)_X compose f_U: RR attach(arrow.r.long.bar, t: f_U) [0,1] attach(arrow.r.long.bar, t: F^(-1)_X) RR $

No només és possible, sinó que és una CDF de la variable $X$. Això és possible ja que $U$ genera els nombres uniformement entre l'interval $[0,1]$, fent que la imatge de la composició es comporti com la distribució de la variable aleatòria caldria esperar. 

En el cas de la distribució de Weibull, és fàcil veure que la funció inversa de la CDF està ben definida i pren la forma:

$
  F_(X)^(-1)(u) = alpha (-log(u))^(1/beta).
$

== Implementació computacional
La implementació de les simulacions es realitza en el marc del llenguatge de programació Python utilitzant principalment les llibreries de computació numèrica NumPy i SciPy (TODO citar), les quals proporcionen una API d'alt nivell fàcil d'utilitzar, amb implementacions numèriques eficients testejades per la comunitat. Els objectes numèrics que s'utilitzaran són principalment del tipus `np.array`, permetent operacions vectoritzades que acceleren la realització de simulacions.

Un dels focus d'aquest treball i especialment de l'assignatura és la garantia de reproducibilitat d'un estudi de simulació, és a dir, desenvolupar el codi de la simulació de tal forma que qualsevol usuari interessat en reproduïr (de forma exacta) els fets presentats en aquesta memòria ho pugui fer sense problema.

Amb aquest fi, el codi annex a la memòria s'estructura fonamentalment en els següents blocs de codi:

+ En primer lloc, el mòdul `src/dgm.py` conté la classe `WeibullDistribution` la qual inicialitzada amb els paràmetres `alpha` i `beta` adequats encapsula una $"Weibull"(alpha, beta)$ de la qual es pot generar una mostra de mida $n$ mitjançant el mètode `sample(n: int)`, que implementa el mètode descrit a l'apartat anterior. La generació de nombres aleatoris ben definida la proporciona NumPy amb `np.random.default_rng(seed)`, que per darrera implementa l'algoritme de Mersenne-Twister proporcionada una llavor (`seed`). S'observa que, creat un objecte generador de nombres aleatoris de NumPy, la classe `WeibullDistribution` permet ser inicialitzada amb aquest especificament, de forma que si es canvia de paràmetres durant l'estudi de simulació, el fet de compartir el generador garanteix el control total sobre la seqüència de nombres que es van generant. 

+



= Estimand

Volem estimar els valors d'$alpha, beta$ de la weibull empiricament, donades les dades que hem generat per simulació.

Per a cada combinació dels paràmetres $(n, alpha, beta)$ generarem $m$ repetitions independents. Per a cadascuna d'aquestes, calcularem els estimadors d'$alpha, beta$ tan amb el mètode MLE ($hat(alpha_("MLE")), hat(beta_("MLE"))$) i amb el MLE ($hat(alpha_("MLE")), hat(beta_("MLE"))$) obtenint una distribució empírica dels estimadors per ananlitzar-ne les mètriques llistades a l'apartat dels resultats.


= Performance Mesures

Les mesures que utilitizarem seran:
1. Biaix:  $"Biaix" = frac(1,m) sum_(i=1)^m (hat(theta)_i - theta)$
2. Error estàndard de montecarlo (MCSE): $"MSCE"("Biaix") = sqrt(frac(1, m(m-1)) sum_(i=1)^m hat(theta)_i  -macron(hat(theta)))$
3. MSE: $frac(1, m) (hat(theta)_i - theta)^2$

Per a comprarar-lo amb l'MLE, calcularem les mètriques anteriors també per l'MLE i les contrastarem amb les del MRR.


= Results

Gràfiques: per a cada tamany mostral, posem les gràfiques que estan a `plotting.py`:
Taules de resultats:
TODO: La taula hauria de ser
1. files: n 
2. Columnes: Biax, MCSE MSE de MRR i després de MLE
3. Hi haurà 9 taules, una per cada valor diferent de alpha beta.

= Annex

Posar totes les classes a lo copia i enganxa. Més enllà, fer ènfasi al main, i fer un esforç en que imprimieixi els mateixos results exactes que es presenten al report. (EG la taula, s'ha de trobar com fer-ho)
