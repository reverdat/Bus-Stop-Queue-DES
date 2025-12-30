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

L'objectiu principal d'aquesta pràctica és el disseny, implementació i anàlisi d'un motor de simulació d'esdeveniments discrets (Discrete Event Simulation) aplicat a un sistema d'espera d'una parada d'autobús. En aquest sistema interaccionen dues entitats principals, els usuaris (clients) i els autobusos (servidors), sota condicions d'incertesa en els temps d'arribada i capacitats.

Aquest document constitueix és la preentrega del treball. La finalitat d'aquesta fase inicial no és encara simular el sistema amb tota la seva complexitat estocàstica final, sinó establir una base sòlida de programari i validar-ne la correcció (verificació del model). Per aconseguir-ho, s'assumeix un conjunt d'hipòtesis simplificadores, com ara temps de servei nuls i taxes exponencials, que permeten modelitzar la parada teòricament com una cua markoviana $M\/M^([X])\/1\/K$. Aquesta reducció és crucial en aquesta etapa, ja que ens permet obtenir solucions analítiques exactes de l'estat estacionari i utilitzar-les com a referència per auditar la precisió del nostre simulador.

La metodologia de treball s'ha basat en la implementació de l'algorisme de programació d'esdeveniments (_Event-Scheduling_) utilitzant el llenguatge de sistemes Zig, prioritzant l'eficiència computacional i la gestió robusta de memòria per a la generació de trajectòries llargues.

A continuació, es presenta primer la definició formal del sistema i la seva justificació teòrica. Seguidament, es detallen les decisions d'arquitectura preses durant la implementació en Zig. Finalment, es comparen els resultats estadístics de la simulació (concretament l'ocupació mitjana del sistema segons la Llei de Little) amb els valors teòrics esperats per demostrar la validesa del simulador desenvolupat. Als appendix s'hi troba un manual d'ajuda per a l'execució del codi i compilació, a més a més de diversos extres que han sorgit durant la entrega.

= Definició del Sistema
En aquesta secció formalitzem el funcionament de la parada d'autobús. El sistema es modelitza com un procés estocàstic de temps continu on interactuen dues entitats: els usuaris (que arriben i fan cua) i el servidor (l'autobús que arriba, carrega usuaris i marxa). Detallarem certes hipòtesis que justifiquem les decisions que hem pres a l'hora d'implementar el model.

Per a aquesta preentrega, l'objectiu és validar el motor de simulació contrastant-lo amb resultats analítics coneguts. Per aquest motiu, apliquem simplificacions que permeten tractar el sistema com una cua caracteritzada com a cadena de Màrkov de temps continu (CTMC).

== Dinàmica i Components
El sistema d'espera es tracta d'una parada d'autobús on arriben usuaris que esperen a que arribi un autobús per tal de pujar-hi i eventualment marxar. Es poden definir dos principals components: la marquesina (arribades) i l'autobús (serveis).
\
1. *Marquesina*: Es tracta d'una plataforma de capacitat finita $K$ on els usuaris arriben de forma individual en un temps aleatori $tau_i$ i esperen a ser servits per un autobús. S'assumeix que els usuaris són respectuossos i s'ordenen en una cua per ordre d'arribada per tal de pujar a l'autobús seguint la doctrina FIFO (First-In First-Out). Si en un determinat moment la cua conté $K$ usuaris i arriba un de nou, aquest no es posa a la cua, sinó que és descartat.
2. *Autobús*: És l'únic servidor del sistema d'espera. Arriba en un temps aleatori a la parada i amb una capacitat $X$. Permet començar l'embarcament dels usuaris esperant a la marquesina, els quals triguen a pujar a l'autobús un temps aleatori. El bus marxa de la parada només quan exhaureix la seva capacitat o bé quan no queden usuaris esperant a la marquesina.

== Modelització en cua
El sistema d'espera descrit anteriorment es pot identificar amb una cua $M\/\M^([X])\/1\/K$ mitjançant una serie de hipòtesis vàlides per aquesta preentregra. A continuació es proporcion a una simple demostració d'aquesta afirmació que no busca ser rigorosa:
1. El temps entre dues arribades d'usuaris consecutives a la marquesina $tau_(i+1) - tau_i$ és una v.a. que segueix una llei exponencial de paràmetre fix $lambda$.
2. El temps d'arribada d'un nou bus a la parada un cop ha marxat l'últim és una v.a. que segueix una llei exponencial de paràmetre fix $mu$.
3. El temps que triga un usuari a pujar de la marquesina al bus és una v.a. degenerada i de valor constant $nu approx 0$.
Sigui $(n, c) in bb(Z)_(+)^(2)$ l'estat del sistema d'espera en un determinat instant de temps, on $n$ és el nombre d'usuaris a la marquesina i $c$ és la capacitat restant del bus.
- Si $c = 0$, aleshores pel definit assumim que no hi ha un autobús a la parada. Per tant, només pot succeïr que arribi un altre usuari a la cua definida per la marquesina, o bé que arribi un autobús a la parada amb una determinada capacitat $c^prime$, i per tant es correspon amb transicions a l'estat $(n+1, 0)$ només si $n+1 <= K$ o bé a $(n, c^prime)$, respectivament.
- Si $c > 0$, aleshores en aquest instant es troben $n$ usuaris a la marquesina i un bus amb capacitat restant $c$ estacionat a la parada. Per tant, només pot succeïr que un usuari pugi a l'autobús o bé que arribi un altre usuari a la marquesina, transicionant als estats $(n-1, c-1)$ o $(n+1, c)$ només si $n+1 <= K$, respectivament. Les transicions del primer tipus triguen un temps $nu$ que suposem aproximadament nul.

\
#figure(
  image("img/diagrama_transicions.jpg", width: 90%),
  caption: [
    Diagrama de transicions del S.E. de la parada d'autobús (exemple per $c=3$)
  ],
  supplement: [Figura],
)<fig:markov_bus>
\

Observem que el fet que el temps de pujada a l'autobús sigui aproximadament nul implica que, un cop arriba un autobús i el sistema es troba en l'estat $(n, c)$, aleshores la pròxima transició és $(n, c) -> (n-1, c-1)$ amb probabilitat aproximadament 1, i aquesta transició succeeix casi immediatament. Aquest comportament es repeteix indefinidament fins que el sistema arriba a l'estat $(n^prime, 0)$ per algun $n^prime >= 0$. 

Per tant, aquesta cadena de transicions immediates provoca que els $c$ serveis individuals s'agrupin en essencialment un únic servei en lot de $c$ usuaris, i permet ignorar la capacitat de l'autobús com a part de l'estat del sistema per considerar únicament el nombre d'usuaris a la marquesina $n$. D'aquesta forma, el sistema d'espera es simplifica a únicament les següents transicions:
- Si $n = 0$, aleshores no hi han usuaris esperant a la marquesina, i només pot succeïr que arribi un nou usuari, i per tant $0 -> 1$.
- Si $0 < n < K$, aleshores hi ha un determinat nombre d'usuaris esperant a la marquesina. Per tant pot arribar un usuari nou, $n -> n+1$, o bé pot arribar un autobús amb capacitat $c$ que recull immediatament a tants  usuaris com pot i marxa, $n -> max(0, n-c)$.
- Altrament, si $n = K$, la marquesina no té més capacitat i per tant no admet més usuaris. Només pot passar $K-> max(0, K-c)$ al arribar un autobús amb capacitat $c$.

Finalment, observem que l'esquema de transicions definit, juntament amb els temps entre arribades exponencials tan d'usuaris com d'autobusos a la parada, impliquen que la parada d'autobús sota aquestes hipòtesis es comporta com una cua $M$/$M^([X])$/$1$/$K$, és a dir, una cua on:

- $M$: Temps entre arrivades exponencial.
- $M^([X])$: Temps de servei exponencial amb taxa per _batches_ (lots) de capacitat aleatòria.
- $1$: Un únic servidor.
- $K$: Capacitat del sistema (finita). \u{25A1}

\
#figure(
  image("img/mmx1k.jpg", width: 90%),
  caption: [
    Diagrama de transicions d'una cua $M\/M^([3])\/1\/K$ (exemple)
  ],
  supplement: [Figura],
)<fig:mmx1k>
\

És important insistir en que aquesta demostració es fonamenta en una sèrie de hipòtesis fetes per la preentrega d'aquest treball, i que no seran vàlides per a la entrega final. Una representació general del diagrama de transicions de la parada d'autobús és donada per la #ref(<fig:markov_bus>), i per la seva simplificació #ref(<fig:mmx1k>).


== Estat estacionari i la Llei de Little

El fet que el comportament teòric del sistema d'espera de la parada d'autobús sigui equivalent a una cua $M$/$M^([X])$/$1$/$K$ ens permet resoldre les equacions del seu estat estacionari de la cadena de Màrkov asssociada.

Per calcular les probabilitats d'estat estacionari $P_n$, plantegem les equacions d'equilibri global de la cadena de Markov contínua. L'estructura de transicions dona lloc al sistema lineal $Q^T P = 0$ juntament amb la normalització $sum_(n=0)^K P_n = 1$ i $P_n >= 0$. D'acord amb l'enunciat de la preentrega, a partir d'ara fixem la capacitat de l'autobús com a una v.a. constant $X equiv c = 3$ i la marquesina $K = 9$. Formalment, hem de resoldre el sistema d'equacions:


\
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

$ Q^T P = 0 quad sum_(n=0)^K P_n = 1 quad P_n >= 0 $
\
Un cop obtingudes les probabilitats estacionàries $P_n$, podem calcular mesures de rendiment del sistema d'espera aplicant la Llei de Little. En particular, ens fixem en l'ocupació mitjana del sistema d'espera al llarg del temps,
$ L = lambda W = sum_(n=0)^infinity n P_n. $
Prendrem aquest valor teòric com a mètrica de referència per verificar la correcta implementació de la simulació.
Referir-se a l'@app:implementacions_extres per veure com resoldre el sistema computacionalment i calcular $L$ com a funció de $(lambda, mu, X, K)$.


= Implementació

Hem simulat el sistema $M\/M^([X])\/1\/K$ mitjançant l'algorisme _Event-Scheduling_, que consisteix en que cada vegada que un esdeveniment d'un tipus concret succeeix, en generem un del mateix tipus per mantenir l'algorisme funcionant, fins que un dels esdeveniments superi l'horitzó temporal no sent atès mai.


Hem escollit Zig @zig com el llenguatge per a implementar l'algorisme. Zig és un llenguatge de sistemes amb gestió de memòria manual i control de flux i memòria explícit, i tot i no tenir una _release_ estable, és absolutament funcional per a la gran majoria de casos d'ús. Hem escollit aquest llenguatge ja que al ser una simulació una tasca relativament exigent per a horitzons llargs o per a múltiples repeticions, ens voliem allunyar de llenguatges interpretats com Python o R, que haguessin donat resultats molt llunys a l'òptim a nivell de temps i rendiment. També hem escollit usar Zig sobre C, ja que la filosofia de Zig és extremadament semblant a la de C (gestió de memòria manual i simplicitat) però amb sensibilitats modernes que prevenen molts dels problemes comuns que té C: violacions de segment, indeterminacions en codi i l'ús de `make` per a compilar el projecte.

L'algorisme _Event-Scheduling_ es basa en mantenir una llista ordenada dels esdeveniments generats segons el temps, i processar sempre el de menor temps. Per continuar l'algorisme, sempre que es processi un esdevieniment de tipus A, se'n genera un altre al futur i es guarda a la llista, de manera que en algun moment es traurà de la llista i serà processat, mantenint el bucle. Sobre la implementació d'aquesta llista - part més troncal de l'algorisme- la primera consideració és descartar l'ús d'una array o `ArrayList` per a mantenir els esdeveniments a memòria, ja que només es necessita l'esdeveniment amb el temps més petit. L'ús de qualsevol tipus d'estructura de dades estil llista implicaria una inserció a la llista de cost $O(n)$, ja que s'haurien de desplaçar tots els elements de la llista una posició per a fer lloc al nou. L'avantatge de l'ús d'una llista ordenada és que té un accés molt ràpid, $O(log_2(n))$ ja que només hem de cercar la llista un cop.

En el cas de l'_Event-Scheduling_ no hem d'accedir a un element qualsevol, sinó que només hem d'accedir al primer element - el més pròxim al temps actual. Per tant, hem emprat una implementació de l'estructura Heap @heap, que guarda els elements sense ordre, però garanteix que el primer element de la estructura sempre serà el de menor temps, donant-nos un accés de $O(1)$. En comparació amb la llista, també guanyem en inserció, ja que un heap té un cost d'accés de $O(log_2(n))$ al usar una estructura d'arbre binari per emmagatzemar les dades. El heap és la millor estructura per aquest problema, ja que els requeriments que tenim són als d'accedir al mínim element el més ràpid possible, sense necessitat d'accedir o eliminar un esdeveniment qualsevol. Això sí, si que hem emprat una `ArrayList` per a guardar-nos la traça del problema.

Tornant al cas concret del problema que ens ocupa, el problema té tres tipus d'esdeveniments (Arribada, Servei, Embarcament, però té quatre paràmetres aleatòris: rati d'arribades ($lambda$), rati de serveis ($mu$), capacitat del bus $X$ i temps d'embarcament. Tot i tenir les assumpcions d'una cua $M$/$M^([X])$/$1$/$K$ en aquesta entrega, hem creat estructures per a fer generals aqustes quatre magnituds aleatories per qualsevol tipus de distribució, i no haver de tocar la lògica de l'algorisme. És a dir, la lògica i les distribucions dels paràmetres estan completament desacoplades al codi. Això ho hem aconseguit mitjançant les dues estructures següents:

```zig
pub const Distribution = union(enum) {
    constant: f64,
    exponential: f64,
    uniform: struct { min: f64, max: f64 },

    pub fn sample(self: Distribution, rng: Random) !f64 {
        switch (self) {
            .constant => |val| return val,
            .exponential => |lambda| return sampling.rexp(f64, lambda, rng),
            .uniform => |p| return try sampling.runif(f64, p.min, p.max, rng),
        }
    }

pub const SimConfig = struct {
    passenger_interarrival: Distribution,
    bus_interarrival: Distribution,
    bus_capacity: Distribution,
    boarding_time: Distribution,
    system_capacity: u64,
    horizon: f64,
};
```

`Distribution` és una unió, és a dir, que quan s'instacii serà un dels tipus definits `constant, exponential, uniform`. La funció sample, implementa en cadascun d'aquests casos la generació d'un nombre aleatòri d'una de les distribucions ja dites. `sampling` concretament és el fitxer `rng.zig`, on hem implementat l'exponencial mitjançant el mètode de la inversa. Aleshores, la funció que implementa l'algorisme al fitxer `main.zig` rep d'entrada un `SimConfig`, amb tots els paràmetres com a distribució, especificant exactament quina s'ha d'executar, tal com es mostra a continuació:

```zig
const config = SimConfig{
    .horizon = horizon,
    .passenger_interarrival = Distribution{ .exponential = lambda }, // lambda
    .bus_interarrival = Distribution{ .exponential = mu }, // mu
    .bus_capacity = Distribution{ .constant = x }, // X
    .boarding_time = Distribution{ .constant = 1e-16 }, // negligible 
    .system_capacity = k, // K
};
```

Per tant, per l'entrega final només caldrà modificar la estructura `Distribution` i afegir-hi qualsevol distribució que sigui demanada. Més enllà d'aquests detalls, el codi s'assembla molt al pseudocodi entregat a classe, i es pot trobar al fitxer `main.zig` de l'entrega.


= Resultats i conclusions
A continuació presentem els resultats de la simulació implementada i els comparem als valors teòrics. Fixem els paràmetres 
#align(center, table(
  columns: 5,
  stroke: none,
  column-gutter: 2em, // Space between items
  [$lambda = 5$], [$mu = 4$], [$K = 9$], [$X = 3$], [$T = 10000,$]
))
on $T$ és l'horitzó temporal de la simulació en unitats de temps. Resolent numèricament el sistema d'equacions globals de l'estat estacionari trobem que el valor teòric de $L$ és, aproximadament, $L approx 1.5770.$ Executem la nostra implementació amb aquests mateixos paràmetres, i generem $B=10000$ trajectòries, de forma que podem estimar $L$ amb alta precisió proporcionant un interval de confiança al nivell $95\%$:
$
  hat(L) = 1.5767 plus.minus 0.000372.
$

El resultat ens permet aleshores afirmar que la implementació de la simulació és correcta.

Cal destacar que la decisió d'implementar la simulació en Zig ha facilitat molt l'obtenció d'aquests resultats, ja que ha permès la simulació de $B=10000$ trajectòries en un temps més que factible, ja que el temps d'execució d'una única simulació s'ha estimat com a $0.0058 plus.minus 0.000012$. 

Concloem que aquesta primera entrega ha satisfet el seu objectiu de definir una base sòlida en quant a teoria i codi per a la posterior realització d'una simulació de la parada d'autobús amb paràmetres més complexos, com ara la capacitat d'autobús i temps d'embarcament aleatoris.

#counter(heading).update(0)
#set heading(numbering: (..nums) => {
  let vals = nums.pos()
  if vals.len() == 1 {
    return "Annex " + numbering("A", ..vals)
  } else {
    return numbering("A.1", ..vals)
  }
}, supplement: none)

#pagebreak()

= Ús i Execució del Codi

A l'entrega s'hi poden trobar els binaris per a les tres plataformes i arquitectures principals (MacOS (aarch64), Windows (x86) i GNU-Linux (x86)) per executar el codi. Per tant, per a executar-lo és tan senzill com obrir una terminal, navegar fins a la carpeta on es troba el binari i executar-lo. El programa necessita 6 arguments per terminal, que són els següents en l'ordre ensenyat:
+ $lambda$: rati d'arribada entre passatges
+ $mu$: rati d'arribada dels autobusos
+ $X$: Capacitat de l'autobús.
+ $K$: Capacitat màxima del sistema.
+ horizon: duració de la simulació
+ $B$: nombre de rèpliques de la simulació.

Ara bé, si el lector és desconfiat a executar un binari trobat a internet - fet no només comprensible sinó respectable - aquí donem informació tècnica per tal de compilar el programa.

Primer, la versió de Zig emprada ha estat la 0.15.2, i és la única dependència. Aleshores, s'ha de descarregar zig pel seu sistema operatiu i arqutectura seguint les instruccions a la pàgina de Zig @zig. Es pot comprovar que la instal·lació ha estat exitosa corrent a una terminal `zig version`, on hauria d'apareixer la versió actual.

Per a compilar el programa, col·loquis sobre l'arrel del projecte, que és un hi hauria d'haver-hi dos fitxers: `build.zig` i `build.zig.zon`. Zig és ell mateix el compilador de Zig (és l'equivalent a make en C i C++) i per tant nosaltres hem definit quines opcions hi ha al compilar el programa.
- `zig build`: compila el programa i no l'executa. El programa es troba a `/zig-out/`, i des d'allà es pot executar.
- `zig build run`: compila i executa el programa. Per passar-li arguments, s'ha d'usar dos guions de la següent manera `zig build run -- help`, sinó el build system l'entendrà com un argument. La compilació en aquest i en l'anterior és en mode debug, per tant no tindrà un rendiment molt alt.
- `zig build release`: compila el programa per a les tres plataformes i aquitectures ja nombrades, amb mode `ReleaseSafe`, on se salta diverses comprovacions i accelera substancialment el temps d'execució del programa.

En cas d'errors, sempre es pot utilitzar directament `zig run src/main.zig` i també funcionaria, tot i que la compilació serà en mode debug.

Qualsevol problema en la compilació o execució no es dubti a contactar amb els autors.


#pagebreak()
= Implementacions Extres <app:implementacions_extres>

Per entendre millor l'algorisme de l'_Event-Scheduling_, el nostre flux de treball ha necessitat de dues implementacions més primerenques a mode de prototip i de prova de concepte.

El primer pas va ser reimplementar el codi d'exemple d'una cua $M\/M\/1$ en Python, i comprovar que els resultats eren exactament els mateixos. Curiosament, la nostra implementació ha resultat ser bastant diferent de la original, així que l'adjuntem al codi de la pràctica al fitxer `mm1.py`.

Seguidament, per confirmar que erem capaços d'implementar Zig amb prou soltura, varem traduïr la implementació del `mm1.py` a Zig. Aquest fitxer també es pot trobar a `mm1.zig`.

Com a detall extra, vàrem comentar de paraula que entregariem una llibreria de python amb l'algorisme compilat. Malauradament, això no ha estat possible per problemes tècnics que van més enllà de l'abast de la pràctica i dels nostres coneixements. Per poder empaquetar el binari de Zig en una llibreria de Python, s'ha intentat usar `Ziggy-Pydust`, una llibreria que genera totes les dependències extres per a poder cridar el binari des de Python. Amb poc intents i seguint la documentació, hem aconseguit que funcioni perfectament per a Linux, però la llibreria és massa jove com per a tenir support per a Windows, per això vam haver de desestimar la iniciativa i entregar un binari directament.


#bibliography("works.yml")
