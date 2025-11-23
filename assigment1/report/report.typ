
// això és el Latex look, per si canviem d'opinió.
#set page(
    header: context{
        if counter(page).get().first() > 1 [
            _Pau Soler - GDMS_ 
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

= Aims (Objectius)

= Data-generating mechanisms (mechanismes de generació de dades)

Mètode de la funió inversa amb la weibull (simulaició des d'un model paramètric)

= Estimand

Volem estimar quina és la probabilitat de que es trenquin les molles segons els valors d'$alpha$ i $beta$ d'una weibull

= Performance Mesures

Aquí ja estic una miqueta perdut xd

= Results

Som els putos amos i ha anat tot molt bé un petó per nosaltres.

= Annex

Posar tots els codis a lo copia i enganxa, potser explicant de què va. Sobretot jo el que posaria és quelcom estil "final script" on es facin els imports de tot el que necessitem i tota la pesca. on es facin els imports de tot el que necessitem i tota la pesca.
