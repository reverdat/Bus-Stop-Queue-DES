#import "@preview/lovelace:0.3.0": *

#set page(
  paper: "a4",
  margin: (x: 2cm, y: 2cm),
)
#set text(font: "New Computer Modern", lang: "ca")
#set par(justify: true)

// Title
#align(center)[
  #text(size: 17pt, weight: "bold")[Preentrega Simulació]
]

= Definició del Sistema

Tenim una cua de tipus $M$/$M^([x])$/$1$/$K$:

- $M$: Arribades markovianes.
- $M^([x])$: Temps de servei exponencial amb taxa per _batches_ (lots).
- $1$: Un servidor.
- $K$: Capacitat del sistema (finita).

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

= Algorisme Event-Scheduling

Com que em lio llegint les diapos del power em dedico a preescriure la memòria per a poder avançar, i saber què collons hem de programar.

Tenim les variables d'estat del sistema:
- Nombre de clients
- Estat de cada servidor
- Instant d'arribada de la següent arribada.
- Instant de la propera sortida del sistema.

L'algorisme _per se_ és molt senzill:

#pseudocode-list[
  + $N$,$lambda$, $mu$
  + $T$ = duració simulació
  + $e_0$, $t_0$ = first event, time of first event
  + $t = t_0$
  + *while* (t < T) {

  }
]
