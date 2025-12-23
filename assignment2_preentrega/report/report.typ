#import "@preview/lovelace:0.3.0": *
#import "@preview/cetz:0.3.1"
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

//#set math.equation(numbering: "1.")
#set par(leading: 0.55em, spacing: 0.55em, first-line-indent: 1.8em, justify: true)
#set heading(numbering: "1.")
#show heading: set block(above: 1.4em, below: 1em)

#align(center, text(18pt)[
  *Simulació del sistema d'espera d'una parada d'autobús com a cua $M\/M^([X])\/1\/K$* 
])
#align(center, text(16pt)[
  _Preentrega_ 
])



#align(center)[
    #stack(
        spacing: 0.65em,
        [_Arnau Pérez Reverte, Pau Soler Valadés_],
        [_27-12-2025_],
        [_Simulació, MESIO UPC-UB_]
    )
]

= Introducció

Aquí diem de què va la preentrega i com de feliços som pujant abans d'hora a l'autobús


= Definició del Sistema
_Aquí definim el comportament del sistema d'espera en detall de forma que justifiquem les decisions i assumpcions preses en la seva programació._


== Comportament
El sistema d'espera es tracta d'una parada d'autobús on arriben usuaris que esperen a que arribi un autobús per tal de pujar-hi i eventualment marxar. Es poden definir dos principals components: la marquesina i l'autobús (quan aquest hi arriba).
\
1. *Marquesina*: Es tracta d'una plataforma de capacitat finita $K$ on els usuaris arriben en un temps aleatori $tau_i$ i esperen a ser servits per un autobús. S'assumeix que els usuaris són respectuossos i s'ordenen en una cua per ordre d'arribada per tal de pujar a l'autobús seguint la doctrina FIFO (First-In First-Out). Si en un determinat moment la cua conté $K$ usuaris i arriba un de nou, aquest és descartat.
2. *Autobús*: És l'únic servidor del sistema d'espera. Arriba en un temps aleatori a la parada i amb una capacitat aleatòria $X$. Permet començar l'embarcament dels usuaris esperant a la marquesina, els quals triguen a pujar a l'autobús un temps aleatori. El bus marxa de la parada només quan exhaureix la seva capacitat o bé quan no queden usuaris esperant a la marquesina.

== Modelització en cua
Afirmem que el sistema d'espera descrit anteriorment es pot identificar amb una cua $M$/$M^([X])$/$1$/$K$ mitjançant una serie de hipòtesis *vàlides per aquesta preentregra*. En efecte,
suposem el següent:
1. El temps entre dues arribades d'usuaris consecutives a la marquesina $tau_(i+1) - tau_i$ és una v.a. que segueix una llei exponencial de paràmetre fix $lambda$.  
2. El temps d'arribada d'un nou bus a la parada un cop ha marxat l'últim és una v.a. que segueix una llei exponencial de paràmetre fix $mu$.  
3. El temps que triga un usuari a pujar de la marquesina cap al bus és una v.a. degenerada i de valor constant $nu approx 0$. 
Sigui $(n, c) in bb(Z)_(+)^(2)$ l'estat del sistema d'espera en un determinat instant de temps, on $n$ és el nombre d'usuaris a la marquesina i $c$ és la capacitat restant del bus.
- Si $c = 0$, aleshores pel definit assumim que no hi ha un autobús a la parada. Per tant, només pot succeïr que el se

- $M$: Arribades markovianes.
- $M^([X])$: Temps de servei exponencial amb taxa per _batches_ (lots).
- $1$: Un servidor.
- $K$: Capacitat del sistema (finita).
// \
// #figure(
//   image("img/diagrama_transicions.jpg", width: 100%),
//   caption: [
//     Diagrama de transicions del S.E. de la parada d'autobús
//   ],
//   supplement: [Figura],
// )
// \
//

== Resolució del Sistema Manualment

Això està escrit tot en brut a sota, entenc que la preentrega diu que això ho hem de posar, oi?


= Implementació

Hem simulat el sistema $M\/M^([X])\/1\/K$ mitjançant l'algorisme _Event-Scheduling_, que consisteix en que cada vegada que un esdeveniment d'un tipus concret succeeix, en generem un del mateix tipus per mantenir l'algorisme funcionant, fins que un dels esdeveniments superi l'horitzó temporal no sent atès mai.

// TODO: posem el pseudocodi ben escrit o sudant?

Hem escollit Zig @zig com el llenguatge per a implementar l'algorisme. Zig és un llenguatge de sistemes amb gestió de memòria manual i control de flux i memòria explícit, i tot i no tenir una _release_ estable, és absolutament funcional per a la gran majoria de casos d'ús. Hem escollit aquest llenguatge ja que al ser una simulació una tasca relativament exigent per a horitzons llargs o per a múltiples repeticions, ens voliem allunyar de llenguatges interpretats com Python o R, que haguessin donat resultats penosos a nivell de temps i rendiment. També hem escollit usar Zig sobre C, ja que la filosofia de Zig és extremadament semblant a la de C (gestió de memòria manual i simplicitat) però amb sensibilitats modernes que prevenen molts dels problemes comuns que té C: violacions de segment, indeterminacions en codi i l'ús de `make` per a compilar el projecte.

Sobre la implementació, la primera consideració és descartar l'ús d'una array o `ArrayList` per a mantenir els esdeveniments a memòria, ja que només es necessita l'esdeveniment amb el temps més petit. L'ús de qualsevol tipus d'estructura de dades estil llista implicaria una inserció a la llista de cost $O(n)$, ja que s'haurien de desplaçar tots els elements de la llista una posició per a fer lloc al nou. L'avantatge de l'ús d'una llista ordenada és que té un accés molt ràpid, $O(log_2(n))$ ja que només hem de cercar la llista un cop.

En el cas de l'_Event-Scheduling_ no hem d'accedir a un element qualsevol, sinó que només hem d'accedir al primer element. Per tant, hem emprat una implementació de l'estructura Heap @heap, que guarda els elements sense ordre, però garanteix que el primer element de la estructura sempre serà el de menor temps, donant-nos un accés de $O(1)$. En comparació amb la llista, també guanyem en inserció, ja que un heap té un cost d'accés de $O(log_2(n))$ al usar una estructura d'arbre binari per emmagatzemar les dades. El heap és la millor estructura per aquest problema, ja que els requeriments que tenim són als d'accedir al mínim element el més ràpid possible, sense necessitat de en un moment qualsevol cercar un element qualsevol.


= Conclusions

Aquí diem tot el que hem aconseguit.

= Appendix: Ús i Execució del Codi

Com executem això

= Appendix: Implementacions Extres

Per entendre millor l'algorisme de l'_Event-Scheduling_, el nostre flux de treball ha necessitat de dues implementacions més primerenques a mode de prototip i de prova de concepte.

El primer pas va ser reimplementar el codi d'exemple d'una cua $M\/M\/1$ en python, i comprovar que els resultats eren exactament els mateixos. Curiosament, la nostra implementació ha resultat ser bastant diferent de la original, així que l'adjuntem al codi de la pràctica al fitxer `mm1.py`.

Seguidament, per confirmar que erem capaços d'implementar Zig amb prou soltura, varem traduïr la implementació del `mm1.py` a Zig. Aquest fitxer també es pot trobar a `mm1.zig`.

Com a detall extra, vàrem comentar de paraula que entregariem una llibreria de python amb l'algorisme compilat. Malauradament, això no ha estat possible per problemes tècnics que van més enllà de l'abast de la pràctica i dels nostres coneixements. Per poder empaquetar el binari de Zig en una llibreria de Python, s'ha intentat usar `Ziggy-Pydust`, una llibreria que genera totes les dependències extres per a poder cridar el binari des de Python. Amb poc intents i seguint la documentació, hem aconseguit que funcioni perfectament per a Linux, però la llibreria és massa jove com per a tenir support per a Windows, per això vam haver de desestimar la iniciativa i entregar un binari directament.

= Notes sobre la resolució del sistema M/M^[X]/1/K
L'enunciat de la preentrega diu que s'han de posar aquests nombres a mà, els deixo al final intentant posar-ho a lloc.

*Estat estacionari:* Les probabilitats no canvien durant segons el temps $t$, ergo $P_n$ és fix.

== Equacions d'equilibri

$ Q^T P = 0 quad sum_(i=0)^K P_i = 1 quad P_i >= 0 $

Les usarem per resoldre el sistema. Volem calcular $L$, que és la longitud mitjana del sistema.

$ L = lambda W = sum_(n=0)^infinity n P_n $
#text(size: 0.9em, style: "italic")[Little's Law i definició d'esperança.]


---

= Tasques

== 1. Escull els paràmetres per testar el codi

*Requisits:*
- $X$ constant.
- $floor(K/X) = 3$ (la capacitat del sistema ha de ser 3 cops el tamany del lot del servei).

*Selecció:*
Posem $X = 3$, per tant $K >= 9$.
Diem #rect(inset: 2pt)[$K = 9$].

== 2. Escolliu la taxa d'arribades i de servei

- *Arribades:* $lambda = 3$ clients/hora.
- *Serveis:* $mu = 2$ lots/hora.

Ja tenim el problema ben determinat.

*Diagrama d'estats (Transicions):*
- Arribades ($lambda$): $0 -> 1 -> 2 -> ... -> 9$
- Serveis ($mu$): El servei processa lots de 3.
  - Transicions de retorn: $3 -> 0, 4 -> 1, ..., 9 -> 6$.

*Nota sobre el procés:*
$A = 3 "clients/hora" ->$ Procés Poisson? Temps entre arribades és exponencial, aprox 20 min entre clients.

---

= Matriu i Resolució

$mu = "lot/hora" ->$ Faig $mu$ serveis complets per hora. Temps mitjà $1/2 = 30$ min a atendre.

== Definició de la Matriu $Q$

Definim la matriu de transició (Generador Infinitesimal) per als estats $0$ a $9$.
_Nota: On posa $-5$ és equivalent a $-mu - lambda$._

$
Q = mat(
  -lambda, lambda, 0, 0, 0, 0, 0, 0, 0, 0;
  mu, -mu -lambda, lambda, 0, 0, 0, 0, 0, 0, 0;
  mu, 0, -mu -lambda, lambda, 0, 0, 0, 0, 0, 0;
  mu, 0, 0, -mu -lambda, lambda, 0, 0, 0, 0, 0;
  0, mu, 0, 0, -mu -lambda, lambda, 0, 0, 0, 0;
  0, 0, mu, 0, 0, -mu -lambda, lambda, 0, 0, 0;
  0, 0, 0, mu, 0, 0, -mu -lambda, lambda, 0, 0;
  0, 0, 0, 0, mu, 0, 0, -mu -lambda, lambda, 0;
  0, 0, 0, 0, 0, mu, 0, 0, -mu -lambda, lambda;
  0, 0, 0, 0, 0, 0, mu, 0, 0, -mu;
)
$

Hem de resoldre el sistema lineal següent:

$
cases(
  Q^T P = 0,
  sum_(i=1)^K P_i = 1,
  P_i >= 0
)
$

I ho hem fet a `solver/main.py`


#bibliography("works.yml")
