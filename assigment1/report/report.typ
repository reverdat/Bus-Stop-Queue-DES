
// això és el Latex look, per si canviem d'opinió.
#set page(
    header: context{
        if counter(page).get().first() > 1 [
            _Arnau Pérez, Pau Soler - SIM_ 
            #h(1fr)
            MESIO, UPC
        ]
    },
    paper: "a4",
    numbering: "1",
    margin: 1.25in,
)

#set document(
  title: [Estimació dels paràmetres de la distribució Weibull]
)


#set par(leading: 0.55em, spacing: 0.55em, first-line-indent: 1.8em, justify: true)
#set heading(numbering: "1.")
#show heading: set block(above: 1.4em, below: 1em)

#align(center, text(18pt)[
  *Estimació dels paràmetres de la distribució Weibull* 
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

El DGM defineix com s'utilitza el mostreig pseudoaleatori per crear dades. Aquest estudi contindrà exclusivament simulacions paramètriques de dades distribuïdes seguint una Weibull per a diferents configuracions dels paràmetres $(alpha, beta)$ per tal d'experimentar amb l'estimació en funció de la forma de la distribució, així com de la mida de la mostra.

Fixats valors de $n > 0$ i $alpha, beta >0$, es defineix que el DGM que es realitza en una única simulació consisteix en la generació d'una mostra  d'observacions $T_1, T_2, ..., T_n$ _i.i.d_, amb $T_i ~ "Weibull"(alpha, beta)$. Els factors a variar per l'experimentació del mètode a estudiar seran aleshores $(alpha, beta, n)$, on seguint l'enunciat de la pràctica es defineix la següent matriu de valors basats en tres nivells (_small_, _medium_, _large_):

#set table(
  fill: (x, y) =>
    if x == 0 or y == 0 {
      gray.lighten(40%)
    },
  align: left,
)
\
#figure(
  table(
    columns: (auto, auto, auto, auto, auto),
    inset: 8pt,
    align: center,
    table.header(
      [*Factor*], [*Tipus*], table.cell(colspan: 3)[*Valor*],
      [], [], [_*Small*_], [_*Medium*_], [_*Large*_]
    ),
    $alpha "(Scale)"$,
    "Paràmetre de distribució",
    "2", "10", "50", 
    $beta "(Shape)"$,
    "Paràmetre de distribució",
    "0.8", "1", "3", 
    $n "(Mida de la mostra)"$,
    "Paràmetre de mostreig",
    "10", "50", "200", 
  ),
  
  caption: [
    Matriu de factors a variar a l'estudi
  ],
  
  kind: "table",
  
  supplement:  "Figura",
)
\
Els valors proposats pels tres nivells de la mida de la mostra $n$ són valors estàndards
dintre de la literatura. En el cas dels paràmetres $alpha, beta$, primer es definiran amb detall
a continuació i aquesta proposta de valors quedarà aleshores justificada.

== La distribució de Weibull 
Diem que una variable aleatòria contínua $X$ segueix una distribució de Weibull de paràmetres $alpha$ i $beta$, $X ~ "Weibull"(alpha, beta)$, si té funció de densitat de probabilitat (_pdf_)

$ f_X (x; alpha, beta) = (beta/alpha) (x/alpha)^(beta - 1) exp(-(x/alpha)^beta) bb(1)_({x > 0}), $

on $alpha > 0$ i $beta > 0$ són els paràmetres scale i shape, respectivament. S'observa aleshores que la seva funció de distribució de probabilitat (_cdf_) pren la forma 

$ F_X (x) = 1 - exp(-(x/alpha)^beta). $

La distribució de Weibull, amb els seu suport al nombres reals positius, resulta a la pràctica molt útil per modelitzar el concepte de "temps de vida" en contextos com control de qualitat, epidemiologia, entre d'altres. Els seus paràmetres a més a més es poden, en aquesta idea mateixa idea, caracteritzar i interpretar de la forma següent:

- $alpha$ (Scale): També conegut com vida característica, pren unitats d'acord al context del problema, és a dir, ja sigui perque estem modelitzant segons, minuts, hores, cicles, etc.
- $beta$ (Shape): En el nostre context, $beta$ és un paràmetre adimensional conegut com la proporció de fallada, i que modifica el comportament de la distrbució de Weibull de la següent forma en funció del tres casos:
  + *$beta < 1$:* Proporció de fallada decreixent/"mortalitat infantil". Com major és el temps de supervivència de la unitat, menor és la probabilitat de que mori/falli en el següent instant.
  + *$beta = 1$:* Proporció de fallada constant. Simplifica la distribució de Weibull a una $"Exp"(1/alpha)$, simbolitzant que el temps de supervivència és aleatori i independent de temps transcorregut.
  + *$beta > 1$:* Proporció de fallada creixent. La probabilitat de mort creix a mesura que el temps incrementa. Representa unitats/individus que empitjoren amb el pas del temps.

Com ja s'ha descrit, la distribució de Weibull s'utilitza en el context del temps i en conseqüència manté una relació molt estreta amb altres distribucions utilitzades amb aquesta mateixa idea. Es destaca, en particular:

  - $"Weibull"(alpha, 1) = "Exp"(1/alpha) $
  - $ X ~ "Weibull"(sqrt(2)beta, 2) = "Rayleigh"(beta) $

== Mètode de generació de nombres aleatòries

Per tal de simular valors de la distribució de Weibull, s'utilitzarà el mètode de distribució inversa. En efecte, el mètode empra la composició de dues funcions: la funció de densitat d'una distribució uniforme $U(0,1)$ juntament amb la inversa de la funció de probabilitat $F$ de la distribució que es vulgui generar. Una variable aleatòria $U ~ U(0,1)$ té la densitat $f_U$ següent:

$ f_U (x) = bb(1)_{0 <= x <= 1} (x) $

i està definida en $f_U: RR |-> [0,1]$, i una _cdf_ seguint una variable aleatòria $X$ està definida a $F_X: RR |-> [0,1]$, i la seva inversa per tant a $F^(-1)_X: [0,1] |-> RR$. Aleshores, la seva composició

$ F^(-1)_X compose f_U ~ X $

$ F^(-1)_X compose f_U: RR attach(arrow.r.long.bar, t: f_U) [0,1] attach(arrow.r.long.bar, t: F^(-1)_X) RR $

No només és possible, sinó que és una _cdf_ de la variable $X$. Això és possible ja que $U$ genera els nombres uniformement entre l'interval $[0,1]$, fent que la imatge de la composició es comporti com la distribució de la variable aleatòria caldria esperar. 

En el cas de la distribució de Weibull, és fàcil veure que la funció inversa de la _cdf_ està ben definida per $u in (0,1]$ i pren la forma:

$
  F_(X)^(-1)(u) = alpha (-log(u))^(1/beta).
$

== Implementació computacional
La implementació de les simulacions es realitza en el marc del llenguatge de programació Python utilitzant principalment les llibreries de computació numèrica NumPy @harris2020array i SciPy @2020SciPy-NMeth , les quals proporcionen una API d'alt nivell fàcil d'utilitzar, amb implementacions numèriques eficients testejades per la comunitat. Els objectes numèrics que s'utilitzaran són principalment del tipus `np.array`, permetent operacions vectoritzades que acceleren la realització de simulacions.

Un dels focus d'aquest treball i especialment de l'assignatura és la garantia de reproducibilitat d'un estudi de simulació, és a dir, desenvolupar el codi de la simulació de tal forma que qualsevol usuari interessat en reproduïr (de forma exacta) els fets presentats en aquesta memòria ho pugui fer sense cap inconvenient. Amb aquest fi, el codi annex a la memòria s'estructura fonamentalment en diferents blocs de codi.

En primer lloc, el mòdul `src/dgm.py` conté la classe `WeibullDistribution` la qual inicialitzada amb els paràmetres `alpha` i `beta` adequats encapsula una $"Weibull"(alpha, beta)$ de la qual es pot generar una mostra de mida $n$ mitjançant el mètode `sample(n: int)`, que implementa el mètode descrit a l'apartat anterior. La generació de nombres aleatoris ben definida la proporciona NumPy amb `np.random.default_rng(seed)`, que per darrera implementa l'algoritme de Mersenne-Twister proporcionada una llavor (`seed`). S'observa que, creat un objecte generador de nombres aleatoris de NumPy `rng`, la classe `WeibullDistribution` permet ser inicialitzada amb aquest generador especificament, de forma que si es canvia de paràmetres durant l'estudi de simulació, el fet de compartir el generador garanteix el control total sobre la seqüència de nombres que es van generant a cada punt del programa. 


= Mètodes
*TODO*
== Mètode 1: Maximum Likelihood Estimation (MLE)

*TODO*

== Mètode 2: Median Ranks Regression (MRR)

El mètode de Median Ranks Regression (MRR) per a l'estimació dels paràmetres consisteix en tres passos:

1. Donada la mostra d'observacions de temps de fallada $T_1, ..., T_n$, primer s'ordena la mostra en ordre creixent, obtenint així la mostra $hat(T)_1, ..., hat(T)_n$ on
$
hat(T)_i := T_(\(i\)).
$
Es guarda també la permutació $sigma: {1,..,n} -->  {1,..,n}$ tal que $sigma(T_1, ..., T_n) = (hat(T)_1, ..., hat(T)_n)$.

2.  Es calcula el rang medià $"MR"_j$ de cada fallada $hat(T)_j$ de la mostra mitjançant l'equació
    $
    0.50 = sum_(k=j)^N binom(N, k) "MR"_j^k (1 - "MR"_j)^(N-k)
    $
    i s'utilitza com a estimació de la no-fiabilitat: $Q(hat(T)_j) approx "MR"_j$. 

    Aquesta equació es pot resoldre en primera instància utilitzant algorismes de cerca d'arrels com el mètode de Newton. No obstant,
    es pot veure a @dutka_incomplete_1981[p.~15] que el costat de la dreta coincideix amb el valor $I_("MR"_j)(j, n-j+1)$, que es correspon amb l'anomenada funció beta incompleta regularitzada, definida com
    $
      I_(x)(a, b) = B(x; a,b)/B(a,b),
    $
    on $B$ és la funció Beta incompleta
    $
      B(x; a, b) = integral_0^x t^(a-1) (1-t)^(b-1) d t
    $
    i posem $B(a,b) := B(1; a,b)$. Per tant,

    $
    0.50 = I_("MR"_j)(j, n-j+1)
    $ 
    i el problema es simplifica a treballar amb la inversa (sobre $x$) de $I_(x)(a, b)$, la qual es troba implementada en  paquets 
    de programari estadístic @2020SciPy-NMeth.

    És fàcil observar a més a més que aquest càlcul del $"MR"_j$ depèn només de $n$ i de $j$, i no del valor observat
    de $hat(T)_j$, el qual s'incorporarà més endavant. És per això que una molt bona aproximació al valor real de l'$"MR"_j$ es pot obtenir
    mitjançant

    $
      "MR"_j approx (j-0.3)/(n+0.4).
    $



3.  Es transformen les estimacions de no-fiabilitat mitjançant l'aplicació
    $
    Q mapsto log(-log(1 - Q)).
    $
    Aquesta funció està ben definida, ja que $Q in (0,1)$ i $-log(1 - Q) > 0$. S'observa que la funció transforma la _cdf_ de la Weibull en una recta. En efecte,
    $
    Q := F_(X)(x; alpha, beta) = 1 - exp(-(x/alpha)^beta)  \
     Q - 1 = -exp(-(x/alpha)^beta) \
    -log(1 - Q) = (x/alpha)^beta \
    log(-log(1 - Q)) = beta log(x) - beta log(alpha).
    $

4.  Amb la mostra de parells de temps de fallada i les seves estimacions de no-fiabilitat $(T_(sigma^(-1)(j)), Q_j)$, s'utilitza Mínims Quadrats per ajustar una recta i extreure els coeficients resultants $m$ i $b$. Llavors, la inferència sobre els paràmetres del nostre model de Weibull es pot aconseguir mitjançant
    $
    m equiv beta \
    b equiv -beta log(alpha) => alpha = exp(-b/beta).
    $

== Implementació computacional

Els diferents mètodes d'estimació descrits prèviament s'implementen com a funcions al mòdul 
`src/inference.py`.
1. *Median Ranks Regression (MRR)*: En el cas del MRR, la funció `median_ranks_regression` pren una mostra de simulació arbitrària i implementa el procediment explicat anteriorment. En particular, el paràmetre `method` permet escollir entre `"beta"` i `"bernard"`, per calcular els rangs medians utilitzan la forma explícita de la funció beta incompleta regularitzada (disponible per `from scipy.special import betaincinv`) o bé l'aproximació de Bernard. En ambdós casos s'utilitzen operacions matricials de NumPy, de forma que el procés és vectoritzat i per tant més ràpid. Finalment, els Mínims Quadrats es computen mitjançant `linregress` de `scipy.stats`.
2. *Maximum Likelihood Estimation (MLE)*: *TODO*

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

Resultats: he agrupat en csv per alpha beta. Cadascun conté 3 files, una per a cada n. proposo escriure directament aquestes taules a l'apartat de resultats, partint-ho per MLE, MRR i Betrand
1. files: n 
2. Columnes: Biax, MCSE MSE de MRR i després de MLE
3. Hi haurà 9 taules, una per cada valor diferent de alpha beta.

Grafiques (sempre per parella alpha-beta encara que no es digui el contari):
+ Primera: MSE per alpha beta (y-axis) i tipus (x-axis) MLE MRR Bertanrd i MRR normal code. Amb MCSE.
+ Grafic de linies mse-bias. x: mse, y: bias. tres punts, un per sample size, tres linies, una per mètode.
+ Gràfic de linies. y-axis: mse; x-axis sample-size.

Grafiques sobre bootstrap:
+ boxplot: alph
Les gràfiques mínimes han de ser la regressió lineal amb els mínims quadrats per ajustar una recta.
Gràfiques: per a cada tamany mostral, posem les gràfiques que estan a `plotting.py`:
Taules de resultats:


= Annex

Posar totes les classes a lo copia i enganxa. Més enllà, fer ènfasi al main, i fer un esforç en que imprimieixi els mateixos results exactes que es presenten al report. (EG la taula, s'ha de trobar com fer-ho)

#bibliography("bibliography.bib", style: "ieee", title: "Bibliografia")
