
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
  *Estudi de simluació del mètode d'estimació paramètric de Regressió per Rangs a la Mediana (MRR) d'una distribució Weibull* 
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

Aquest document és la memòria de l'entrega avaluable de la primera part de l'assignatura _Simulació_ del màster MESIO, feta per Arnau Pérez Reverte i Pau Soler Valadés. El document segueix el procediment ADMEP (Aims, Data-Generation, Methods, Estimands, Performance) [TODO CITAR AIXÔ ARNAU] i contesta els punts proposats a l'enunciat de l'entrega. A diferencia d'un artícle acadèmic, en certs punts de la pràctica ens dediquem a explicar conceptes que s'haurien de donar per sabuts, però degut a la naturalesa avaluada de l'entrega, hem preferit explicar en el benentès de la màxima claredat.

*Sobre l'ús d'Intel·ligència Artificial Generativa*: Els continguts d'aquesta memòria han estat íntegrament escrits per humans, els seus dos autors, així com tota la seva estructura i raonaments. Tanmateix, s'ha emprat la Intel·ligència Artifical Generativa (models PerplexiyAI [TODO CITAR ARNAU] i Google Gemini 3 [TODO CITAR ARNAU]) en la recerca de fonts, explicacions sobre conceptes i pel codi de les taules que apareixen en aquest document.

= Objectiu (Aims)

// NOTA: Arnau, em sap greu però encara no em convenç això haha, què et sembla aquest paràgraf! Tria-ho tu mateix, sorry <3
//
// L'objectiu de l'estudi de simualació és avaluar el mètode de Regressió per Rangs Medians (Median Rank Regression o MRR) per a estimar els paràmetres d'una distribució Weibull. Per a fer-ho, el compararem amb el mètode habitual que estima els paràmetres com a estimadors de màxima versemblança (Maximum Likelihood Estimator o MLE) i una estimació del mateix MRR mitjançant una sèrie de mètriques adequades. 
L'objectiu principal del següent estudi de simulació és l'estudi de la inferència dels paràmetres d'una distribució de Weibull mitjançant el mètode de Regressió per Rangs Medians (Median Ranks Regression o MRR). Amb aquesta finalitat, es desenvoluparà la teoria al voltant d'aquesta distribució de probabilitat, es definirà aquest procediment d'inferència en detall i s'avaluarà la qualitat del seus resultats mitjançant una sèrie de mètriques, així com es compararà amb el mètode ordinari de inferència per estimadors de màxima versemblança (Maximum Likelihood Estimation o MLE).

= Generació de Dades (Data-Generating Mechanisms)

El DGM defineix com s'utilitza el mostreig pseudoaleatori per crear dades. Aquest estudi contindrà exclusivament simulacions paramètriques de dades distribuïdes seguint una Weibull per a diferents configuracions dels paràmetres d'escala $alpha$ i de forma $beta$ per tal de verificar que l'estimació s'adapta a la forma de la distribució, així com amb diferents mides de tamany mostral.

El mecanisme de generació de dades consisteix en, per a cada tamany mostral diferent $n$, generar una mostra $T_1,...,T_n$ _i.i.d_, on $T_i ~ "Weibull"(alpha, beta)$ per a totes les 9 parelles de valors possibles $(alpha, beta)$. La taula @tab-valors-param mostra els valors escollits per a les simulacions.


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
    "1", "10", "50", 
    $beta "(Shape)"$,
    "Paràmetre de distribució",
    "0.5", "1", "3", 
    $n "(Mida de la mostra)"$,
    "Paràmetre de mostreig",
    "10", "50", "200", 
  ),
  
  caption: [
    Matriu de factors a variar a l'estudi
  ],
  
  kind: "table",
  
  supplement:  "Taula",
) <tab-valors-param>
\


Els valors proposats pels tres nivells de la mida de la mostra $n$ són valors estàndards en la literatura [TODO: EL PAU TÉ ELS ARTÍCLES]. En el cas dels paràmetres $alpha, beta$, primer es definiran amb detall a continuació i aquesta proposta de valors quedarà aleshores justificada.

== La Distribució de Weibull 

Diem que una variable aleatòria contínua $X$ segueix una distribució de Weibull de paràmetres $alpha$ i $beta$, $X ~ "Weibull"(alpha, beta)$, si té funció de densitat de probabilitat (pdf)

$ f_X (x; alpha, beta) = (beta/alpha) (x/alpha)^(beta - 1) exp(-(x/alpha)^beta) bb(1)_({x > 0}), $

on $alpha > 0$ i $beta > 0$ són els paràmetres d'escala (scale) i forma (shape) respectivament. S'observa aleshores que la seva funció de distribució de probabilitat (cdf) pren la forma 

$ F_X (x) = 1 - exp(-(x/alpha)^beta). $

La distribució de Weibull, amb els seu suport als nombres reals positius $RR^+$, és molt útil per modelitzar el concepte de "temps de vida" en contextos com control de qualitat, epidemiologia, o el cas de l'exemple de l'enunciat, temps fins a fallada en enginyeria, entre molts altres. Els seus paràmetres es poden, a més a més, caracteritzar i interpretar de la manera següent:

- $alpha$ (Scale): També conegut com vida característica, pren unitats d'acord al context del problema, és a dir, ja sigui perque estem modelitzant segons, minuts, hores, cicles, etc.
- $beta$ (Shape): En el nostre context, $beta$ és un paràmetre adimensional conegut com la proporció de fallada, i que modifica el comportament de la distrbució de Weibull de la següent forma en funció del tres casos:
  + *$beta < 1$:* Proporció de fallada decreixent/"mortalitat infantil". Com major és el temps de supervivència de la unitat, menor és la probabilitat de que mori/falli en el següent instant.
  + *$beta = 1$:* Proporció de fallada constant. Simplifica la distribució de Weibull a una $"Exp"(1/alpha)$, simbolitzant que el temps de supervivència és aleatori i independent de temps transcorregut.
  + *$beta > 1$:* Proporció de fallada creixent. La probabilitat de mort creix a mesura que el temps incrementa. Representa unitats/individus que empitjoren amb el pas del temps.

[TODO: POTSER POSAR UNES GRAFIQUITES SOBRE BETA?]

Com ja s'ha descrit, la distribució de Weibull s'utilitza en el contextos on les dades són temporals, i en conseqüència manté una relació molt estreta amb altres distribucions utilitzades amb aquesta mateixa finalitat. Es destaquen en particular les següents relacions:
- $"Weibull"(alpha, 1) = "Exp"(1/alpha) $
- $ X ~ "Weibull"(sqrt(2)beta, 2) = "Rayleigh"(beta) $


== Mètode de generació de nombres aleatòries

Per tal de simular valors de la distribució de Weibull, s'ha emprat el mètode de la distribució inversa; el mètode empra la composició de dues funcions: la funció de densitat d'una distribució uniforme $U(0,1)$ juntament amb la inversa de la funció de probabilitat $F$ de la distribució que es vulgui generar. Una variable aleatòria $U ~ U(0,1)$ té la densitat $f_U$ següent:

$ f_U (x) = bb(1)_{0 <= x <= 1} (x) $

i està definida en $f_U: RR |-> [0,1]$, i una _cdf_ seguint una variable aleatòria $X$ està definida a $F_X: RR |-> [0,1]$, i la seva inversa per tant a $F^(-1)_X: [0,1] |-> RR$. Aleshores, la seva composició

$ F^(-1)_X compose f_U ~ X $

$ F^(-1)_X compose f_U: RR attach(arrow.r.long.bar, t: f_U) [0,1] attach(arrow.r.long.bar, t: F^(-1)_X) RR $

no només és possible, sinó que és una CDF de la variable $X$. Això és possible ja que $U$ genera els nombres uniformement entre l'interval $[0,1]$, fent que la imatge de la composició es comporti com la distribució de la variable aleatòria que es vol generar. 

En el cas de la distribució de Weibull, és fàcil veure que la funció inversa de la CDF està ben definida per $u in [0,1]$ i té la forma:

$
  F_(X)^(-1)(u) = alpha (-log(u))^(1/beta).
$

== Implementació computacional
La implementació de les simulacions es realitza en el marc del llenguatge de programació Python utilitzant principalment les llibreries de computació numèrica NumPy @harris2020array i SciPy @2020SciPy-NMeth , les quals proporcionen una API d'alt nivell fàcil d'utilitzar, amb implementacions numèriques eficients testejades per la comunitat. Els objectes numèrics que s'utilitzaran són principalment del tipus `np.array`, permetent operacions vectoritzades que acceleren la realització de simulacions.

Un dels focus d'aquest treball i especialment de l'assignatura és la garantia de reproducibilitat d'un estudi de simulació, és a dir, desenvolupar el codi de la simulació de tal forma que qualsevol usuari interessat en reproduïr (de forma exacta) els fets presentats en aquesta memòria ho pugui fer sense cap inconvenient. Amb aquest fi, el codi annex a la memòria s'estructura fonamentalment en diferents blocs de codi.

En primer lloc, el mòdul `src/dgm.py` conté la classe `WeibullDistribution` la qual inicialitzada amb els paràmetres `alpha` i `beta` adequats encapsula una $"Weibull"(alpha, beta)$ de la qual es pot generar una mostra de mida $n$ mitjançant el mètode `sample(n: int)`, que implementa el mètode descrit a l'apartat anterior. La generació de nombres aleatoris ben definida la proporciona NumPy amb `np.random.default_rng(seed)`, que per darrera implementa l'algoritme de Mersenne-Twister proporcionada una llavor (`seed`). S'observa que, creat un objecte generador de nombres aleatoris de NumPy `rng`, la classe `WeibullDistribution` permet ser inicialitzada amb aquest generador especificament, de forma que si es canvia de paràmetres durant l'estudi de simulació, el fet de compartir el generador garanteix el control total sobre la seqüència de nombres que es van generant a cada punt del programa. 


= Mètodes

Aquest apartat descriu teòricament el mètodes avaluats en aquest estudi, que són estimació dels paràmtres per MLE, per MRR i l'aproximació de Betrand de l'MRR.

== Estimadors de Màxima Versemblança (MLE)

L'estimació mitjançant MLE és el mètode tradicional per l'estimació de paràmetres. Consiteix a trobar l'estimador de màxima versemblança, que no és més que

$ hat(theta)_"ML" = "argmax"_(theta in Theta) L(theta|bold(x)) $

On $L(theta|bold(x))$ és la funció de versemblança associada a la mostra $bold(x)$. Pel cas de la Weibull, aquesta pren la forma següent:

$ L(alpha, beta|bold(x)) = product_(i=1)^n f(x_i|alpha, beta) = product_(i=1)^n [frac(alpha, beta) (frac(x_i, beta))^(alpha - 1) e^(-(x_i / beta)^alpha)] $

Com que $ln$ és una funció monòtona creixent, és equivalent minitmizar $ell(alpha, beta) = ln L(alpha, beta)$ sent els càlculs molt més senzills:

$ ell(alpha, beta) &= sum_(i=1)^n [ln alpha - ln beta + (alpha - 1)(ln x_i - ln beta) - (frac(x_i, beta))^alpha] \
&= n ln alpha - n ln beta + (alpha - 1) sum_(i=1)^n ln x_i - n(alpha - 1) ln beta - sum_(i=1)^n (frac(x_i, beta))^alpha \
&= n ln alpha - n alpha ln beta + (alpha - 1) sum_(i=1)^n ln x_i - beta^(-alpha) sum_(i=1)^n x_i^alpha $

Ara hem d'obtenir les derivades $frac(partial ell, partial beta)$ $frac(partial ell, partial alpha)$ per a trobar el màxim de la funció. Aquest càlcul és feixuc i no contribueix als resultats que es volen ensenyar, així que es deixa a l'Annex 1. Els valors de les expressions són:


$ frac(partial ell, partial alpha) = frac(1, hat(alpha)) + frac(1, n) sum_(i=1)^n ln x_i - frac(sum_(i=1)^n x_i^hat(alpha) ln x_i, sum_(i=1)^n x_i^hat(alpha)) = 0 $

$ frac(partial ell, partial beta) = hat(beta) = (frac(1, n) sum_(i=1)^n x_i^hat(alpha))^(1 / hat(alpha)) $

Per tant, trobant el mínim del paràmetre $alpha$ trobem el de $beta$. El paràmetre s'acostuma a trobar computacionalment amb mètode de Newton-Rhapson. En el cas del nostre codi, emprem la llibreria `scipy` per a obtenir els estimadors mitjançant MLE.

== Regressió per Rangs a la Mediana (MRR)

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

Per a cada combinació dels paràmetres $(n, alpha, beta)$ generarem $m=1000$ repetitions independents. Per a cadascuna d'aquestes, calcularem els estimadors d'$alpha, beta$ per a els tres mètodes que estem avaluant: MLE ($hat(alpha)_("ML"), hat(beta)_"ML"$), MRR ($hat(alpha)_("MRR"), hat(beta)_"MRR"$)  i l'aproximació de Bertrand de MRR ($hat(alpha)_("B"), hat(beta)_"B"$).

Un cop trobats tots els estimands, utilitzarem les mesures de l'apartat següent per inferir-ne la qualitat.


= Avaluació del Rendiment

Per tal d'avaluar el mètode de Regressió per Rangs de Mediana (MRR), realitzarem una comparativa directa amb l'Estimació de Màxima Versemblança (MLE). Aquesta avaluació es durà a terme mitjançant una simulació de Monte Carlo amb $m$ iteracions.

En aquest context, denotem $theta$ com el valor real del paràmetre i $hat(theta)_i$ com el valor estimat en la $i$-èssima iteració. Les mètriques de rendiment seleccionades per a l'anàlisi es presenten a la taula @tbl-result-metrics:


#figure(
  table(
    columns: (auto, auto, 1fr, 1fr),
    inset: (x, y) => if x == 0 { 8pt } else { 10pt },
    align: (col, row) => (left, center, center, center).at(col) + horizon,
    fill: (col, row) => if row == 0 { luma(240) } else { none },
    stroke: (x, y) => (
      top: if y == 1 { 1pt } else { 0pt },
      bottom: 1pt + luma(200),
    ),
    
    // Headers
    [*Mètrica*], [*Definició*], [*Estimació*], [*MCSE de l'Estimació*],

    // Row 1: Bias
    [Biaix],
    $ EE[hat(theta)] - theta $,
    $ 1/m sum_(i=1)^m (hat(theta)_i - theta) $,
    $ sqrt(frac(1, m(m-1)) sum_(i=1)^m (hat(theta)_i - macron(hat(theta)))^2) $,

    // Row 2: EmpSE
    [EmpSE],
    $ sqrt("Var"(hat(theta))) $,
    $ sqrt(frac(1, m-1) sum_(i=1)^m (hat(theta)_i - macron(hat(theta)))^2) $,
    $ "EmpSE" / sqrt(2(m-1)) $,

    // Row 3: MSE
    [MSE],
    $ EE[(hat(theta) - theta)^2] $,
    $ 1/m sum_(i=1)^m (hat(theta)_i - theta)^2 $,
    $ sqrt((sum_(i=1)^m [(hat(theta)_i - theta)^2 - "MSE"]^2) / (m(m-1))) $
  ),
  caption: [Definicions, estimadors i errors estàndard de Monte Carlo per a les mètriques de rendiment.],
  supplement: "Taula",
) <tbl-result-metrics>


= Resultats

#figure(
  text(size: 9pt)[
    #table(
      columns: (auto, auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
      inset: 6pt,
      align: (col, row) => (center + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon).at(col),
      fill: (col, row) => if row < 2 { luma(240) } else { none },
      stroke: (x, y) => (
        top: if y == 2 { 1pt } else { 0pt },
        bottom: 1pt + luma(200),
      ),
      
      table.cell(rowspan: 2)[$m$], table.cell(rowspan: 2)[*Mètode*], 
      table.cell(colspan: 3)[$hat(alpha)$ (Paràmetre de forma)], table.cell(colspan: 3)[$hat(beta)$ (Paràmetre d'escala)],
      
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],

    table.cell(rowspan: 3)[10], [MLE], [0.1480 (0.0238)], [0.7510 (0.0168)], [0.5860 (0.0472)], [0.0804 (0.0053)], [0.1670 (0.0037)], [0.0343 (0.0024)],
[MRR (Bernard)], [0.3100 (0.0284)], [0.8980 (0.0201)], [0.9020 (0.0902)], [-0.0187 (0.0049)], [0.1550 (0.0035)], [0.0244 (0.0013)],
[MRR (Beta)], [0.3080 (0.0284)], [0.8970 (0.0201)], [0.8990 (0.0898)], [-0.0171 (0.0049)], [0.1560 (0.0035)], [0.0245 (0.0013)],
    table.cell(rowspan: 3)[50], [MLE], [0.0212 (0.0098)], [0.3110 (0.0070)], [0.0971 (0.0057)], [0.0140 (0.0018)], [0.0575 (0.0013)], [0.0035 (0.0002)],
[MRR (Bernard)], [0.0749 (0.0116)], [0.3660 (0.0082)], [0.1400 (0.0203)], [-0.0162 (0.0022)], [0.0702 (0.0016)], [0.0052 (0.0002)],
[MRR (Beta)], [0.0737 (0.0116)], [0.3660 (0.0082)], [0.1390 (0.0202)], [-0.0151 (0.0022)], [0.0703 (0.0016)], [0.0052 (0.0002)],
    table.cell(rowspan: 3)[200], [MLE], [-0.0013 (0.0047)], [0.1480 (0.0033)], [0.0218 (0.0011)], [0.0029 (0.0009)], [0.0274 (0.0006)], [0.0008 (0.0000)],
[MRR (Bernard)], [0.0191 (0.0049)], [0.1540 (0.0034)], [0.0242 (0.0012)], [-0.0099 (0.0011)], [0.0359 (0.0008)], [0.0014 (0.0001)],
[MRR (Beta)], [0.0185 (0.0049)], [0.1540 (0.0034)], [0.0241 (0.0012)], [-0.0094 (0.0011)], [0.0359 (0.0008)], [0.0014 (0.0001)]
    )
  ],
  caption: [Resultats de la simulació per a $alpha=1.0, beta=0.5.$. Els valors es mostren com a Estimació (MCSE).]
) <tbl-results-alpha10-beta05>
#figure(
  text(size: 9pt)[
    #table(
      columns: (auto, auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
      inset: 6pt,
      align: (col, row) => (center + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon).at(col),
      fill: (col, row) => if row < 2 { luma(240) } else { none },
      stroke: (x, y) => (
        top: if y == 2 { 1pt } else { 0pt },
        bottom: 1pt + luma(200),
      ),
      
      table.cell(rowspan: 2)[$m$], table.cell(rowspan: 2)[*Mètode*], 
      table.cell(colspan: 3)[$hat(alpha)$ (Paràmetre de forma)], table.cell(colspan: 3)[$hat(beta)$ (Paràmetre d'escala)],
      
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],

    table.cell(rowspan: 3)[10], [MLE], [0.0257 (0.0104)], [0.3290 (0.0074)], [0.1090 (0.0055)], [0.1990 (0.0121)], [0.3840 (0.0086)], [0.1870 (0.0163)],
[MRR (Bernard)], [0.0897 (0.0114)], [0.3600 (0.0080)], [0.1370 (0.0080)], [-0.0125 (0.0105)], [0.3320 (0.0074)], [0.1100 (0.0073)],
[MRR (Beta)], [0.0889 (0.0114)], [0.3600 (0.0080)], [0.1370 (0.0080)], [-0.0093 (0.0105)], [0.3330 (0.0075)], [0.1110 (0.0074)],
    table.cell(rowspan: 3)[50], [MLE], [0.0039 (0.0046)], [0.1460 (0.0033)], [0.0213 (0.0010)], [0.0254 (0.0037)], [0.1190 (0.0027)], [0.0147 (0.0008)],
[MRR (Bernard)], [0.0266 (0.0049)], [0.1560 (0.0035)], [0.0251 (0.0013)], [-0.0316 (0.0046)], [0.1440 (0.0032)], [0.0218 (0.0010)],
[MRR (Beta)], [0.0260 (0.0049)], [0.1560 (0.0035)], [0.0251 (0.0013)], [-0.0293 (0.0046)], [0.1450 (0.0032)], [0.0218 (0.0010)],
    table.cell(rowspan: 3)[200], [MLE], [0.0004 (0.0024)], [0.0760 (0.0017)], [0.0058 (0.0003)], [0.0058 (0.0018)], [0.0564 (0.0013)], [0.0032 (0.0001)],
[MRR (Bernard)], [0.0097 (0.0025)], [0.0787 (0.0018)], [0.0063 (0.0003)], [-0.0168 (0.0023)], [0.0737 (0.0016)], [0.0057 (0.0002)],
[MRR (Beta)], [0.0094 (0.0025)], [0.0787 (0.0018)], [0.0063 (0.0003)], [-0.0157 (0.0023)], [0.0737 (0.0016)], [0.0057 (0.0002)]
    )
  ],
  caption: [Resultats de la simulació per a $alpha=1.0, beta=1.0.$. Els valors es mostren com a Estimació (MCSE).]
) <tbl-results-alpha10-beta10>
#figure(
  text(size: 9pt)[
    #table(
      columns: (auto, auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
      inset: 6pt,
      align: (col, row) => (center + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon).at(col),
      fill: (col, row) => if row < 2 { luma(240) } else { none },
      stroke: (x, y) => (
        top: if y == 2 { 1pt } else { 0pt },
        bottom: 1pt + luma(200),
      ),
      
      table.cell(rowspan: 2)[$m$], table.cell(rowspan: 2)[*Mètode*], 
      table.cell(colspan: 3)[$hat(alpha)$ (Paràmetre de forma)], table.cell(colspan: 3)[$hat(beta)$ (Paràmetre d'escala)],
      
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],

    table.cell(rowspan: 3)[10], [MLE], [-0.0139 (0.0036)], [0.1130 (0.0025)], [0.0130 (0.0006)], [0.5130 (0.0333)], [1.0500 (0.0235)], [1.3700 (0.1070)],
[MRR (Bernard)], [0.0060 (0.0037)], [0.1160 (0.0026)], [0.0134 (0.0006)], [-0.0964 (0.0308)], [0.9740 (0.0218)], [0.9570 (0.0637)],
[MRR (Beta)], [0.0057 (0.0037)], [0.1160 (0.0026)], [0.0134 (0.0006)], [-0.0871 (0.0309)], [0.9770 (0.0219)], [0.9610 (0.0644)],
    table.cell(rowspan: 3)[50], [MLE], [-0.0011 (0.0015)], [0.0491 (0.0011)], [0.0024 (0.0001)], [0.0833 (0.0108)], [0.3420 (0.0076)], [0.1240 (0.0061)],
[MRR (Bernard)], [0.0064 (0.0016)], [0.0506 (0.0011)], [0.0026 (0.0001)], [-0.0975 (0.0134)], [0.4230 (0.0095)], [0.1880 (0.0081)],
[MRR (Beta)], [0.0062 (0.0016)], [0.0506 (0.0011)], [0.0026 (0.0001)], [-0.0907 (0.0134)], [0.4240 (0.0095)], [0.1880 (0.0081)],
    table.cell(rowspan: 3)[200], [MLE], [-0.0002 (0.0008)], [0.0254 (0.0006)], [0.0006 (0.0000)], [0.0220 (0.0053)], [0.1680 (0.0037)], [0.0285 (0.0013)],
[MRR (Bernard)], [0.0028 (0.0008)], [0.0263 (0.0006)], [0.0007 (0.0000)], [-0.0454 (0.0069)], [0.2200 (0.0049)], [0.0502 (0.0022)],
[MRR (Beta)], [0.0027 (0.0008)], [0.0263 (0.0006)], [0.0007 (0.0000)], [-0.0421 (0.0069)], [0.2200 (0.0049)], [0.0500 (0.0022)]
    )
  ],
  caption: [Resultats de la simulació per a $alpha=1.0, beta=3.0.$. Els valors es mostren com a Estimació (MCSE).]
) <tbl-results-alpha10-beta30>
#figure(
  text(size: 9pt)[
    #table(
      columns: (auto, auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
      inset: 6pt,
      align: (col, row) => (center + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon).at(col),
      fill: (col, row) => if row < 2 { luma(240) } else { none },
      stroke: (x, y) => (
        top: if y == 2 { 1pt } else { 0pt },
        bottom: 1pt + luma(200),
      ),
      
      table.cell(rowspan: 2)[$m$], table.cell(rowspan: 2)[*Mètode*], 
      table.cell(colspan: 3)[$hat(alpha)$ (Paràmetre de forma)], table.cell(colspan: 3)[$hat(beta)$ (Paràmetre d'escala)],
      
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],

    table.cell(rowspan: 3)[10], [MLE], [0.2540 (0.0471)], [1.4900 (0.0333)], [2.2800 (0.1800)], [0.0791 (0.0055)], [0.1750 (0.0039)], [0.0367 (0.0035)],
[MRR (Bernard)], [0.5620 (0.0563)], [1.7800 (0.0399)], [3.4900 (0.3740)], [-0.0194 (0.0051)], [0.1600 (0.0036)], [0.0260 (0.0021)],
[MRR (Beta)], [0.5580 (0.0563)], [1.7800 (0.0398)], [3.4700 (0.3720)], [-0.0179 (0.0051)], [0.1610 (0.0036)], [0.0261 (0.0021)],
    table.cell(rowspan: 3)[50], [MLE], [0.0647 (0.0193)], [0.6120 (0.0137)], [0.3780 (0.0244)], [0.0141 (0.0019)], [0.0606 (0.0014)], [0.0039 (0.0002)],
[MRR (Bernard)], [0.1640 (0.0209)], [0.6600 (0.0148)], [0.4620 (0.0309)], [-0.0164 (0.0022)], [0.0708 (0.0016)], [0.0053 (0.0002)],
[MRR (Beta)], [0.1620 (0.0209)], [0.6590 (0.0148)], [0.4610 (0.0308)], [-0.0153 (0.0022)], [0.0710 (0.0016)], [0.0053 (0.0002)],
    table.cell(rowspan: 3)[200], [MLE], [0.0267 (0.0091)], [0.2870 (0.0064)], [0.0832 (0.0039)], [0.0035 (0.0009)], [0.0276 (0.0006)], [0.0008 (0.0000)],
[MRR (Bernard)], [0.0650 (0.0097)], [0.3080 (0.0069)], [0.0989 (0.0050)], [-0.0077 (0.0011)], [0.0350 (0.0008)], [0.0013 (0.0001)],
[MRR (Beta)], [0.0638 (0.0097)], [0.3080 (0.0069)], [0.0986 (0.0050)], [-0.0072 (0.0011)], [0.0351 (0.0008)], [0.0013 (0.0001)]
    )
  ],
  caption: [Resultats de la simulació per a $alpha=2.0, beta=0.5.$. Els valors es mostren com a Estimació (MCSE).]
) <tbl-results-alpha20-beta05>
#figure(
  text(size: 9pt)[
    #table(
      columns: (auto, auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
      inset: 6pt,
      align: (col, row) => (center + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon).at(col),
      fill: (col, row) => if row < 2 { luma(240) } else { none },
      stroke: (x, y) => (
        top: if y == 2 { 1pt } else { 0pt },
        bottom: 1pt + luma(200),
      ),
      
      table.cell(rowspan: 2)[$m$], table.cell(rowspan: 2)[*Mètode*], 
      table.cell(colspan: 3)[$hat(alpha)$ (Paràmetre de forma)], table.cell(colspan: 3)[$hat(beta)$ (Paràmetre d'escala)],
      
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],

    table.cell(rowspan: 3)[10], [MLE], [0.0250 (0.0216)], [0.6820 (0.0153)], [0.4650 (0.0212)], [0.1570 (0.0105)], [0.3330 (0.0075)], [0.1360 (0.0104)],
[MRR (Bernard)], [0.1550 (0.0233)], [0.7380 (0.0165)], [0.5680 (0.0310)], [-0.0482 (0.0099)], [0.3120 (0.0070)], [0.0996 (0.0069)],
[MRR (Beta)], [0.1530 (0.0233)], [0.7370 (0.0165)], [0.5670 (0.0309)], [-0.0452 (0.0099)], [0.3130 (0.0070)], [0.1000 (0.0070)],
    table.cell(rowspan: 3)[50], [MLE], [0.0056 (0.0093)], [0.2940 (0.0066)], [0.0862 (0.0037)], [0.0281 (0.0038)], [0.1200 (0.0027)], [0.0151 (0.0008)],
[MRR (Bernard)], [0.0525 (0.0098)], [0.3100 (0.0069)], [0.0987 (0.0043)], [-0.0326 (0.0045)], [0.1410 (0.0032)], [0.0210 (0.0009)],
[MRR (Beta)], [0.0514 (0.0098)], [0.3100 (0.0069)], [0.0985 (0.0043)], [-0.0304 (0.0045)], [0.1410 (0.0032)], [0.0209 (0.0009)],
    table.cell(rowspan: 3)[200], [MLE], [0.0037 (0.0047)], [0.1490 (0.0033)], [0.0222 (0.0010)], [0.0047 (0.0018)], [0.0555 (0.0012)], [0.0031 (0.0001)],
[MRR (Bernard)], [0.0231 (0.0049)], [0.1540 (0.0034)], [0.0242 (0.0011)], [-0.0199 (0.0022)], [0.0705 (0.0016)], [0.0054 (0.0002)],
[MRR (Beta)], [0.0225 (0.0049)], [0.1540 (0.0034)], [0.0242 (0.0011)], [-0.0187 (0.0022)], [0.0705 (0.0016)], [0.0053 (0.0002)]
    )
  ],
  caption: [Resultats de la simulació per a $alpha=2.0, beta=1.0.$. Els valors es mostren com a Estimació (MCSE).]
) <tbl-results-alpha20-beta10>
#figure(
  text(size: 9pt)[
    #table(
      columns: (auto, auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
      inset: 6pt,
      align: (col, row) => (center + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon).at(col),
      fill: (col, row) => if row < 2 { luma(240) } else { none },
      stroke: (x, y) => (
        top: if y == 2 { 1pt } else { 0pt },
        bottom: 1pt + luma(200),
      ),
      
      table.cell(rowspan: 2)[$m$], table.cell(rowspan: 2)[*Mètode*], 
      table.cell(colspan: 3)[$hat(alpha)$ (Paràmetre de forma)], table.cell(colspan: 3)[$hat(beta)$ (Paràmetre d'escala)],
      
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],

    table.cell(rowspan: 3)[10], [MLE], [-0.0058 (0.0069)], [0.2180 (0.0049)], [0.0474 (0.0021)], [0.4620 (0.0324)], [1.0300 (0.0229)], [1.2600 (0.0985)],
[MRR (Bernard)], [0.0341 (0.0072)], [0.2280 (0.0051)], [0.0533 (0.0025)], [-0.1340 (0.0290)], [0.9160 (0.0205)], [0.8560 (0.0560)],
[MRR (Beta)], [0.0335 (0.0072)], [0.2280 (0.0051)], [0.0533 (0.0025)], [-0.1250 (0.0291)], [0.9190 (0.0206)], [0.8590 (0.0566)],
    table.cell(rowspan: 3)[50], [MLE], [-0.0013 (0.0032)], [0.1030 (0.0023)], [0.0105 (0.0005)], [0.0898 (0.0110)], [0.3480 (0.0078)], [0.1290 (0.0067)],
[MRR (Bernard)], [0.0135 (0.0034)], [0.1060 (0.0024)], [0.0114 (0.0005)], [-0.0920 (0.0134)], [0.4240 (0.0095)], [0.1880 (0.0083)],
[MRR (Beta)], [0.0132 (0.0034)], [0.1060 (0.0024)], [0.0114 (0.0005)], [-0.0852 (0.0134)], [0.4250 (0.0095)], [0.1870 (0.0083)],
    table.cell(rowspan: 3)[200], [MLE], [-0.0016 (0.0016)], [0.0502 (0.0011)], [0.0025 (0.0001)], [0.0221 (0.0051)], [0.1600 (0.0036)], [0.0262 (0.0011)],
[MRR (Bernard)], [0.0041 (0.0016)], [0.0516 (0.0012)], [0.0027 (0.0001)], [-0.0432 (0.0067)], [0.2110 (0.0047)], [0.0463 (0.0020)],
[MRR (Beta)], [0.0039 (0.0016)], [0.0516 (0.0011)], [0.0027 (0.0001)], [-0.0398 (0.0067)], [0.2110 (0.0047)], [0.0461 (0.0020)]
    )
  ],
  caption: [Resultats de la simulació per a $alpha=2.0, beta=3.0.$. Els valors es mostren com a Estimació (MCSE).]
) <tbl-results-alpha20-beta30>
#figure(
  text(size: 9pt)[
    #table(
      columns: (auto, auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
      inset: 6pt,
      align: (col, row) => (center + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon).at(col),
      fill: (col, row) => if row < 2 { luma(240) } else { none },
      stroke: (x, y) => (
        top: if y == 2 { 1pt } else { 0pt },
        bottom: 1pt + luma(200),
      ),
      
      table.cell(rowspan: 2)[$m$], table.cell(rowspan: 2)[*Mètode*], 
      table.cell(colspan: 3)[$hat(alpha)$ (Paràmetre de forma)], table.cell(colspan: 3)[$hat(beta)$ (Paràmetre d'escala)],
      
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],

    table.cell(rowspan: 3)[10], [MLE], [0.4520 (0.0739)], [2.3400 (0.0523)], [5.6600 (0.4780)], [0.0862 (0.0053)], [0.1680 (0.0037)], [0.0355 (0.0030)],
[MRR (Bernard)], [0.8740 (0.0834)], [2.6400 (0.0590)], [7.7100 (0.6580)], [-0.0134 (0.0049)], [0.1550 (0.0035)], [0.0243 (0.0014)],
[MRR (Beta)], [0.8690 (0.0833)], [2.6300 (0.0589)], [7.6800 (0.6560)], [-0.0118 (0.0049)], [0.1560 (0.0035)], [0.0244 (0.0015)],
    table.cell(rowspan: 3)[50], [MLE], [0.0830 (0.0283)], [0.8950 (0.0200)], [0.8070 (0.0410)], [0.0151 (0.0019)], [0.0595 (0.0013)], [0.0038 (0.0002)],
[MRR (Bernard)], [0.2360 (0.0311)], [0.9820 (0.0220)], [1.0200 (0.0657)], [-0.0162 (0.0022)], [0.0712 (0.0016)], [0.0053 (0.0002)],
[MRR (Beta)], [0.2330 (0.0310)], [0.9810 (0.0219)], [1.0100 (0.0654)], [-0.0151 (0.0023)], [0.0714 (0.0016)], [0.0053 (0.0002)],
    table.cell(rowspan: 3)[200], [MLE], [0.0172 (0.0148)], [0.4680 (0.0105)], [0.2190 (0.0108)], [0.0017 (0.0009)], [0.0273 (0.0006)], [0.0007 (0.0000)],
[MRR (Bernard)], [0.0799 (0.0155)], [0.4900 (0.0110)], [0.2470 (0.0126)], [-0.0108 (0.0011)], [0.0360 (0.0008)], [0.0014 (0.0001)],
[MRR (Beta)], [0.0781 (0.0155)], [0.4900 (0.0110)], [0.2460 (0.0126)], [-0.0103 (0.0011)], [0.0361 (0.0008)], [0.0014 (0.0001)]
    )
  ],
  caption: [Resultats de la simulació per a $alpha=3.0, beta=0.5.$. Els valors es mostren com a Estimació (MCSE).]
) <tbl-results-alpha30-beta05>
#figure(
  text(size: 9pt)[
    #table(
      columns: (auto, auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
      inset: 6pt,
      align: (col, row) => (center + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon).at(col),
      fill: (col, row) => if row < 2 { luma(240) } else { none },
      stroke: (x, y) => (
        top: if y == 2 { 1pt } else { 0pt },
        bottom: 1pt + luma(200),
      ),
      
      table.cell(rowspan: 2)[$m$], table.cell(rowspan: 2)[*Mètode*], 
      table.cell(colspan: 3)[$hat(alpha)$ (Paràmetre de forma)], table.cell(colspan: 3)[$hat(beta)$ (Paràmetre d'escala)],
      
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],

    table.cell(rowspan: 3)[10], [MLE], [0.0197 (0.0323)], [1.0200 (0.0229)], [1.0400 (0.0498)], [0.1810 (0.0116)], [0.3680 (0.0082)], [0.1680 (0.0157)],
[MRR (Bernard)], [0.2070 (0.0344)], [1.0900 (0.0243)], [1.2300 (0.0653)], [-0.0194 (0.0110)], [0.3490 (0.0078)], [0.1220 (0.0128)],
[MRR (Beta)], [0.2040 (0.0344)], [1.0900 (0.0243)], [1.2200 (0.0651)], [-0.0162 (0.0111)], [0.3500 (0.0078)], [0.1230 (0.0129)],
    table.cell(rowspan: 3)[50], [MLE], [0.0097 (0.0137)], [0.4330 (0.0097)], [0.1870 (0.0082)], [0.0283 (0.0037)], [0.1160 (0.0026)], [0.0143 (0.0008)],
[MRR (Bernard)], [0.0798 (0.0145)], [0.4570 (0.0102)], [0.2150 (0.0105)], [-0.0319 (0.0044)], [0.1400 (0.0031)], [0.0207 (0.0009)],
[MRR (Beta)], [0.0781 (0.0145)], [0.4570 (0.0102)], [0.2150 (0.0105)], [-0.0296 (0.0044)], [0.1410 (0.0031)], [0.0206 (0.0009)],
    table.cell(rowspan: 3)[200], [MLE], [-0.0192 (0.0068)], [0.2160 (0.0048)], [0.0468 (0.0020)], [0.0040 (0.0018)], [0.0557 (0.0013)], [0.0031 (0.0001)],
[MRR (Bernard)], [0.0058 (0.0071)], [0.2250 (0.0050)], [0.0507 (0.0022)], [-0.0169 (0.0023)], [0.0723 (0.0016)], [0.0055 (0.0002)],
[MRR (Beta)], [0.0049 (0.0071)], [0.2250 (0.0050)], [0.0506 (0.0022)], [-0.0158 (0.0023)], [0.0723 (0.0016)], [0.0055 (0.0002)]
    )
  ],
  caption: [Resultats de la simulació per a $alpha=3.0, beta=1.0.$. Els valors es mostren com a Estimació (MCSE).]
) <tbl-results-alpha30-beta10>
#figure(
  text(size: 9pt)[
    #table(
      columns: (auto, auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
      inset: 6pt,
      align: (col, row) => (center + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon).at(col),
      fill: (col, row) => if row < 2 { luma(240) } else { none },
      stroke: (x, y) => (
        top: if y == 2 { 1pt } else { 0pt },
        bottom: 1pt + luma(200),
      ),
      
      table.cell(rowspan: 2)[$m$], table.cell(rowspan: 2)[*Mètode*], 
      table.cell(colspan: 3)[$hat(alpha)$ (Paràmetre de forma)], table.cell(colspan: 3)[$hat(beta)$ (Paràmetre d'escala)],
      
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],

    table.cell(rowspan: 3)[10], [MLE], [-0.0190 (0.0103)], [0.3260 (0.0073)], [0.1070 (0.0047)], [0.4710 (0.0323)], [1.0200 (0.0228)], [1.2600 (0.1020)],
[MRR (Bernard)], [0.0438 (0.0107)], [0.3390 (0.0076)], [0.1170 (0.0057)], [-0.1350 (0.0308)], [0.9750 (0.0218)], [0.9670 (0.0685)],
[MRR (Beta)], [0.0430 (0.0107)], [0.3390 (0.0076)], [0.1170 (0.0057)], [-0.1250 (0.0309)], [0.9780 (0.0219)], [0.9710 (0.0692)],
    table.cell(rowspan: 3)[50], [MLE], [-0.0054 (0.0048)], [0.1510 (0.0034)], [0.0228 (0.0010)], [0.0913 (0.0113)], [0.3580 (0.0080)], [0.1360 (0.0074)],
[MRR (Bernard)], [0.0184 (0.0050)], [0.1580 (0.0035)], [0.0253 (0.0013)], [-0.0953 (0.0136)], [0.4290 (0.0096)], [0.1930 (0.0096)],
[MRR (Beta)], [0.0178 (0.0050)], [0.1580 (0.0035)], [0.0253 (0.0013)], [-0.0885 (0.0136)], [0.4300 (0.0096)], [0.1920 (0.0097)],
    table.cell(rowspan: 3)[200], [MLE], [0.0021 (0.0024)], [0.0765 (0.0017)], [0.0059 (0.0003)], [0.0211 (0.0053)], [0.1690 (0.0038)], [0.0289 (0.0014)],
[MRR (Bernard)], [0.0114 (0.0025)], [0.0793 (0.0018)], [0.0064 (0.0003)], [-0.0482 (0.0070)], [0.2200 (0.0049)], [0.0508 (0.0023)],
[MRR (Beta)], [0.0111 (0.0025)], [0.0793 (0.0018)], [0.0064 (0.0003)], [-0.0448 (0.0070)], [0.2200 (0.0049)], [0.0505 (0.0023)]
    )
  ],
  caption: [Resultats de la simulació per a $alpha=3.0, beta=3.0.$. Els valors es mostren com a Estimació (MCSE).]
) <tbl-results-alpha30-beta30>

= Results

Resultats: he agrupat en csv per alpha beta. Cadascun conté 3 files, una per a cada n. proposo escriure directament aquestes taules a l'apartat de resultats, partint-ho per MLE, MRR i Betrand
1. files: n 
2. Columnes: Biax, MCSE MSE de MRR i després de MLE
3. Hi haurà 9 taules, una per cada valor diferent de alpha beta.


#pagebreak()
= Annex 1 

Derivada respecte $beta$:

$ frac(partial ell, partial beta) = -frac(n alpha, beta) - (sum_(i=1)^n x_i^alpha) (frac(partial, partial beta) beta^(-alpha)) $
$ frac(partial ell, partial beta) = -frac(n alpha, beta) - (sum_(i=1)^n x_i^alpha) (-alpha beta^(-alpha - 1)) $
$ -frac(n alpha, beta) + alpha beta^(-alpha - 1) sum_(i=1)^n x_i^alpha = 0 $

Multipliquem per $beta / alpha$ ($alpha, beta != 0$):
$ -n + beta^(-alpha) sum_(i=1)^n x_i^alpha = 0 $
$ beta^alpha = frac(1, n) sum_(i=1)^n x_i^alpha $

Aïllant $beta$, obtenim $hat(beta)$ com una funció respecte $hat(alpha)$:

$ hat(beta) = (frac(1, n) sum_(i=1)^n x_i^hat(alpha))^(1 / hat(alpha)) $

Derivada parcial respecte $alpha$:

$ frac(partial ell, partial alpha) = frac(n, alpha) - n ln beta + sum_(i=1)^n ln x_i - sum_(i=1)^n frac(partial, partial alpha) (frac(x_i, beta))^alpha $

Si en adonem que $frac(partial, partial alpha) z^alpha = z^alpha ln z$, podem posar $z_i = x_i / beta$:

$ frac(partial ell, partial alpha) = frac(n, alpha) - n ln beta + sum_(i=1)^n ln x_i - sum_(i=1)^n (frac(x_i, beta))^alpha ln(frac(x_i, beta)) = 0 $

Substituïnt $ln(x_i / beta) = ln x_i - ln beta$:

$ frac(n, alpha) - n ln beta + sum_(i=1)^n ln x_i - sum_(i=1)^n (frac(x_i, beta))^alpha (ln x_i - ln beta) = 0 $

Usant l'expressió de $beta$, sabem que $sum (x_i / beta)^alpha = n$. I ho expandim a l'últim terme:

$ frac(n, alpha) - n ln beta + sum_(i=1)^n ln x_i - sum_(i=1)^n (frac(x_i, beta))^alpha ln x_i + ln beta underbrace(sum_(i=1)^n (frac(x_i, beta))^alpha, = n) = 0 $


$ frac(n, alpha) + sum_(i=1)^n ln x_i - sum_(i=1)^n (frac(x_i, beta))^alpha ln x_i = 0 $

Substituïm $beta^alpha = frac(1, n) sum x_i^alpha$ a l'equació i dividim per $n$

$ frac(n, alpha) + sum_(i=1)^n ln x_i - frac(sum_(i=1)^n x_i^alpha ln x_i, frac(1, n) sum_(i=1)^n x_i^alpha) = 0 $


$ frac(1, hat(alpha)) + frac(1, n) sum_(i=1)^n ln x_i - frac(sum_(i=1)^n x_i^hat(alpha) ln x_i, sum_(i=1)^n x_i^hat(alpha)) = 0 $

Obtenint l'equació que hem de minimitzar.

= Annex

Posar totes les classes a lo copia i enganxa. Més enllà, fer ènfasi al main, i fer un esforç en que imprimieixi els mateixos results exactes que es presenten al report. (EG la taula, s'ha de trobar com fer-ho)

#bibliography("bibliography.bib", style: "ieee", title: "Bibliografia")
