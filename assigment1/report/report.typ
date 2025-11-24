
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
#set text(font: "New Computer Modern")
#set heading(numbering: "1.")
#show raw: set text(font: "New Computer Modern")
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

Determinar l'efectivitat del mètode MRR (Median Ranks Regression) per a estimar els paràmetres d'una distribució Weibull.

A més a més el comparem amb el valor obtingut pel mètode de referència, estimació amb MLE.


= Generació de Dades (Data-generating mechanisms)

Simulació: Utilitzem el mètode de la funció inversa vist a les classes per generar les dades amb els valors $alpha, beta$ que volguem des del seu model paramètric.

TODO: explicar breument què és el mètode de la funció inversa per generar (copiar del que el pau té fet ja al report de generació de nombres aleatoris)

Els factors que variarem seran els següents:

$alpha in {1,2,3}, beta in {0.5, 1, 1.8}, n in {10, 50, 250}$.

A més a més, farem un nombre de repeticions de cada simulació $m = n_("sim")=1000$ i les analitzarem adequadament. Escollim el valor de $m$ per garantir que l'error estàndard de montecarlo serà suficientment reduït.


= Estimand

Volem estimar els valors d'$alpha, beta$ de la weibull empiricament, donades les dades que hem generat per simulació.

Per a cada combinació dels paràmetres $(n, alpha, beta)$ generarem $m$ repetitions independents. Per a cadascuna d'aquestes, calcularem els estimadors d'$alpha, beta$ tan amb el mètode MLE ($hat(alpha_(MLE)), hat(beta_(MLE))$) i amb el MLE ($hat(alpha_(MLE)), hat(beta_(MLE))$) obtenint una distribució empírica dels estimadors per ananlitzar-ne les mètriques llistades a l'apartat dels resultats.


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
