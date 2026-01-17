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
  title: [Simulaació Marquesina Autobús - Arnau Pérez, Pau Soler]
)

//#set math.equation(numbering: "1.")
#set par(leading: 0.55em, spacing: 0.55em, first-line-indent: 1.8em, justify: true)
#set heading(numbering: "1.")
#show heading: set block(above: 1.4em, below: 1em)

#align(center, text(18pt)[
  *Simulació del sistema d'espera d'una parada d'autobús mitjançant _Event-Scheduling_* 
])
#align(center, text(16pt)[
  _Entrega Final Simulació_ 
])



#align(center)[
    #stack(
        spacing: 0.65em,
        [_Arnau Pérez Reverte, Pau Soler Valadés_],
        [_18-01-2026_],
        [_Simulació, MESIO UPC-UB_]
    )
]

= Introducció

L'objectiu principal d'aquesta pràctica és el disseny, implementació i anàlisi d'un motor de simulació d'esdeveniments discrets (Discrete Event Simulation) aplicat a un sistema d'espera d'una parada d'autobús. En aquest sistema interaccionen dues entitats principals, els usuaris (clients) i els autobusos (servidors), sota condicions d'incertesa en els temps d'arribada i capacitats.

#text(blue)[
Aquest document constitueix és la preentrega del treball. La finalitat d'aquesta fase inicial no és encara simular el sistema amb tota la seva complexitat estocàstica final, sinó establir una base sòlida de programari i validar-ne la correcció (verificació del model). Per aconseguir-ho, s'assumeix un conjunt d'hipòtesis simplificadores, com ara temps de servei nuls i taxes exponencials, que permeten modelitzar la parada teòricament com una cua markoviana $M\/M^([X])\/1\/K$. Aquesta reducció és crucial en aquesta etapa, ja que ens permet obtenir solucions analítiques exactes de l'estat estacionari i utilitzar-les com a referència per auditar la precisió del nostre simulador.
]

La metodologia de treball s'ha basat en la implementació de l'algorisme de programació d'esdeveniments (_Event-Scheduling_) utilitzant el llenguatge de sistemes Zig, prioritzant l'eficiència computacional i la gestió robusta de memòria per a la generació de trajectòries llargues.

#text(blue)[
A continuació, es presenta primer la definició formal del sistema i la seva justificació teòrica. Seguidament, es detallen les decisions d'arquitectura preses durant la implementació en Zig. Finalment, es comparen els resultats estadístics de la simulació (concretament l'ocupació mitjana del sistema segons la Llei de Little) amb els valors teòrics esperats per demostrar la validesa del simulador desenvolupat. Als appendix s'hi troba un manual d'ajuda per a l'execució del codi i compilació, a més a més de diversos extres que han sorgit durant la entrega.]

= Definició del Sistema
En aquesta secció formalitzem el funcionament de la parada d'autobús. El sistema es modelitza com un procés estocàstic de temps continu on interactuen dues entitats: els usuaris (que arriben i fan cua) i el servidor (l'autobús que arriba, carrega usuaris i marxa). Detallarem certes hipòtesis que justifiquem les decisions que hem pres a l'hora d'implementar el model. 

Aquesta secció a més a més manté la base teòrica presentada com a preentrega, que ens ha servit per fonamentar el motor de simulació mitjançant la simplificació del problema com a una cua $M\/\M^([X])\/1\/K$, ja que permet assolir un estat estacionari on la distribució estacionària es pot resoldre analíticament, obtenint així una _ground-truth_ referent davant de la complexitat que suposa el problema.

== Dinàmica i Components
El sistema d'espera es tracta d'una parada d'autobús on arriben usuaris que esperen a que arribi un autobús per tal de pujar-hi i marxar. Es poden definir dues components principals: la marquesina (arribades) i l'autobús (serveis).
\
1. *Marquesina*: Es tracta d'una plataforma de capacitat $K$ on els usuaris arriben de individualment amb temps aleatori $tau_A$ i esperen a ser servits per un autobús. S'assumeix que els usuaris són respectuossos i s'ordenen en una cua per ordre d'arribada per tal de pujar a l'autobús seguint la doctrina FIFO (First-In First-Out). Si en un determinat moment la cua conté $K$ usuaris i arriba un de nou, aquest no entra al sistema, sinó que és descartat.
2. *Autobús*: És l'únic servidor del sistema d'espera. Arriba en un temps aleatori a la parada $tau_B$ i amb una capacitat $X$. Permet començar l'embarcament dels usuaris esperant a la marquesina, els quals triguen a pujar a l'autobús un temps aleatori $tau_C$. El bus marxa de la parada només quan exhaureix la seva capacitat o bé quan no queden usuaris esperant a la marquesina. Si arriba un autobús quan un encara està servint, es reseteja la font, no s'acumula la capacitat. Si un autobús arriba a la parada i no hi ha clients a atendre no se serveix a ningú, és a dir, que l'autobús marxa de la parada.

Com a sistema d'espera ens interessa estudiar una serie de magnituts que resulten del desenvolupament de la trajectòria de la simulació/realització, i que caracteritzen el seu comportament:

- *$L$*: Nombre mitjà de clients al sistema. Aquest magnitud mesura el nombre d'usuaris que hi han simultàniament en la totalitat del sistema, és a dir, tan esperant a la cua com a embarcats a l'autobús esperant a marxar. 
- *$L_q$*: Nombre mitjà de clients a la cua. Es mesura la quantitat d'usuaris esperant exclusivament a la marquesina.
- *$W$*: Temps total mitjà d'un client al sistema. Quantifica el temps del recorregut de l'usuari des de la seva arribada a la marquesina fins que marxa l'autobús al que ha aconseguit embarcar.
- *$W_q$*: Temps mitjà de permanència d'un client a la cua. Aquest temps comprèn des de l'arribada de l'usuari a la marquesina fins a l'instant immediatament abans a que comenci el seu embarcament.
- *$W_s$*: Temps mitjà de servei a un client. Comprèn des del moment en que l'usuari comença l'embarcament fins que marxa el seu autobús. Observem que això conté el propi temps d'embarcament però també el dels possibles usuaris següents a la cua.

== Modelització

#text(blue)[
  He tingut una miqueta de habbit hole amb això. resulta que aquestes cues en bulk son un tipus de cua conegut, per tant és classificable.

  Tenim que aquest tipus de cues son amb "vacances" ja que els servidor atent no regularment (quan arriba l'autobus) i el temps entre busos és exponencial. Les vacances poden ser
  - múltiples: el servidor marxa, si quan torna no hi ha ningú torna a fer unes altres vacances
  - simple: el servidor marxa, si quan torna no hi ha ningú a la cua es manté allà.

  Així i tot, la idea seria que la cua és això, concretament pel grup 2

  $M\/G^((Y))\/1\/"Vac" "amb multiples vacances"$
  
  - M: temps entre arribades d'usuaris -> exponencial normal ergo M
  - G: General, ja que pot ser diverses coses segons Don Codina.
  - Y: temps de pujada de passatgers: Y és perque la batchsize és random (la capacitat del bus)
  - 1: un servidor
  - Vac: cada quan "retorna" o n'arriba un de nou vaja de busos. Això és la Hypo-Exponencial
  
  les fonts d'això són... complicades xd. Era tot tan dispers que he fet un deep research amb el gemini, perque els llibres que hi havia sobre el tema eren massa teòrics i no m'explicaven com classifica-les 
  
  Si et poses perepunyetes, crec que la M pot posar-se com $"GI"$, que és general interarrival si en algun moment no és exponencial, però no és el nostre cas (en el grup dos)

  SUPER CONCRETAMENT, la del grup dos pot ser això: $M\/G^((Y))\/1\/K\/"Hypo"$. Diguem-ne que és complicat

  PROPOSTA EN NET:
]

#text(red)[

  El sistema d'espera descrit anteriorment es pot identficar de manera general amb una notació de Kendall @kendall-notation ampliada (com generalitzar les cues en bulk @chaudhry-templeton-41 @chaudhry-templeton-42) (concepte vacances simples i múltiples @fiems-queues-survey):

  $ "GI"\/G^((Y))\/1\/K\/"Vac" "amb vacances múltiples" $  

  On cada una de les magnituds representa el següent:
  - $"GI"$ (_General Independent_): el temps entre dues arribades segueix una distribució en genera.
  - $G^((Y))$ (_General Bulk Service_): el servei és en _bulk_ (per lots), on concretament la mida depend d'una variable aleatòria $Y$. El superíndex denota la capacitat estocàstica en cues de transport.
  - $1$: Només un servidor (la marquesina), els busos arriben d'un en un.
  - $K$: capacitat màxima d'usuaris al sistema, que pot ser infinita.
  - $"Vac"$ (Vacances): com es comporta el servidor quan no hi ha usuaris presents. Hi ha dos tipus de vacances: (1) múltiples si quan no hi ha ningú a la cua i el servidor arriba, aquest s'espera a els següents usuaris; (2) simple, el servidor s'espera a servir usuaris encara que quan arribi no n'hi hagi cap.

  Més concretament, la instància que ens ha estat proporcionada per a avaluar es pot classificar com una $M\/G^((Y))\/1\/K\/"Hypo" "amb vacances multiples"$ definida pels paràmetres següents:
  + Temps d'arribada entre usuaris ($M$): El temps entre arribades consequtives a la marquesina és $tau_A = t_(A, i+1) - t_(A, i)$. Segueix una exponencial $tau_A ~ "Exp"(lambda)$
  + Capacitat del bus (Y): La capacitat dels autobusos és una exponencial truncada amb màxim $C_("max") = 40$. Si $X$ és la exponencial base, definim $Y$ com
  $ Y ~ "TuncExp"(40) = min{40, X} "on" X ~ "Exp"(eta) $
  - Servidor: Només té un servidor.
  - Capacitat del sistema: no hi ha capacitat màxima.
  - Arribada de busos: El temps d'arribada entre bus i bus segueix una Hypoexponencial de dues fases $X ~ "Hypo"(3,7)$.

  La Hypoexponencial es defineix com la suma de variables aleatòries amb paràmetres diferents.

  $ T_("bus") ~ "Hypo"(lambda_1, ..., lambda_n) = sum_(i=1)^n X_i "on" X_i ~ "Exp"(lambda_i)$

]

El sistema d'espera descrit anteriorment es pot identificar amb una cua amb working vacations, amb la següent notació $$ mitjançant una serie de hipòtesis que es defineixen a continuació. A continuació es proporciona una simple demostració d'aquesta afirmació que no busca ser rigorosa:
1. El temps entre dues arribades d'usuaris consecutives a la marquesina $tau_(A, i+1) - tau_(A, i)$ és una v.a. que segueix una llei exponencial de paràmetre fix $lambda$.
2. El temps d'arribada entre busos a la parada $tau_(B, i+1) - tau_(B, i)$ és una v.a. que segueix una llei exponencial de paràmetre fix $mu$.
3. El temps que triga un usuari a pujar de la marquesina $tau_C$ al bus és una v.a. degenerada i de valor constant $nu approx 0$.
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

Una representació general del diagrama de transicions de la parada d'autobús és donada per la #ref(<fig:markov_bus>), i per la seva simplificació #ref(<fig:mmx1k>).


== Estat estacionari i la Llei de Little

#text(blue)[
  HOLA ARNAU :D Jo trauria tot aquest apartat explicant-ho tot i ho resumiria a un apartat entre la implementació i els resultats que es digui == Test/Verificacions, què et sembla?
]
El fet que el comportament teòric del sistema d'espera de la parada d'autobús sigui equivalent a una cua $M$/$M^([X])$/$1$/$K$ sota aquestes condicions ens permet resoldre les equacions del seu estat estacionari de la cadena de Màrkov asssociada.

Per calcular les probabilitats d'estat estacionari $P_n$, plantegem les equacions d'equilibri global de la cadena de Markov contínua. L'estructura de transicions dona lloc al sistema lineal $Q^T P = 0$ juntament amb la normalització $sum_(n=0)^K P_n = 1$ i $P_n >= 0$. Fixem la capacitat de l'autobús com a una v.a. constant $X equiv c = 3$ i la marquesina $K = 9$. Formalment, hem de resoldre el sistema d'equacions:


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

Hem simulat el sistema de la marquesina mitjançant l'algorisme _Event-Scheduling_, que consisteix en que cada vegada que un esdeveniment d'un tipus concret succeeix, en generem un del mateix tipus per mantenir l'algorisme funcionant, fins que un dels esdeveniments superi l'horitzó temporal, no sent atès mai.

Hem escollit Zig @zig com el llenguatge per a implementar l'algorisme. Zig és un llenguatge de sistemes amb gestió de memòria manual i control de flux i memòria explícit, i tot i no tenir una _release_ estable, és absolutament funcional per a la gran majoria de casos d'ús. Hem escollit aquest llenguatge ja que al ser una simulació una tasca relativament exigent per a horitzons llargs o per a múltiples repeticions, ens voliem allunyar de llenguatges interpretats com Python o R, que haguessin donat resultats amb gran marge de millor segons l'òptim a nivell de temps i rendiment. També hem escollit usar Zig sobre C, ja que la filosofia de Zig és extremadament semblant a la de C (gestió de memòria manual i simplicitat) però amb sensibilitats modernes que prevenen molts dels problemes comuns que té C: violacions de segment, indeterminacions en codi i l'ús de `make` per a compilar el projecte.

*Min-Heap per l'accés als esdeveniments*

L'algorisme _Event-Scheduling_ es basa en mantenir una llista ordenada dels esdeveniments generats segons el temps, i processar sempre el de menor temps. Per continuar l'algorisme, sempre que es processi un esdevieniment de tipus A, se'n genera un altre al futur i es guarda a la llista, de manera que en algun moment es traurà de la llista i serà processat, mantenint el bucle. Sobre la implementació d'aquesta llista - part més troncal de l'algorisme- la primera consideració és descartar l'ús d'una array o `ArrayList` per a mantenir els esdeveniments a memòria, ja que només es necessita l'esdeveniment amb el temps més petit. L'ús de qualsevol tipus d'estructura de dades estil llista implicaria una inserció a la llista de cost $O(n)$, ja que s'haurien de desplaçar tots els elements de la llista una posició per a fer lloc al nou. L'avantatge de l'ús d'una llista ordenada és que té un accés molt ràpid, $O(log_2(n))$ ja que només hem de cercar la llista un cop.

En el cas de l'_Event-Scheduling_ no hem d'accedir a un element qualsevol, sinó que només hem d'accedir al primer element - el més pròxim al temps actual. Per tant, hem emprat una implementació de l'estructura Heap @heap, que guarda els elements sense ordre, però garanteix que el primer element de la estructura sempre serà el de menor temps, donant-nos un accés de $O(1)$. En comparació amb la llista, també guanyem en inserció, ja que un heap té un cost d'accés de $O(log_2(n))$ al usar una estructura d'arbre binari per emmagatzemar les dades. El heap és la millor estructura per aquest problema, ja que els requeriments que tenim són als d'accedir al mínim element el més ràpid possible, sense necessitat d'accedir o eliminar un esdeveniment qualsevol. Això sí, si que hem emprat una `ArrayList` per a guardar-nos la traça del problema.

*Descacoblament Distribució-Lògica*

Tornant al cas concret del problema que ens ocupa, el problema té tres tipus d'esdeveniments (Arribada, Servei, Embarcament, però té quatre paràmetres aleatòris: rati d'arribades ($lambda$), rati de serveis ($mu$), capacitat del bus $C$ i temps d'embarcament $Y$, seguint totes una distribució. Hem aconseguit desacoplar completament la implementació i la lògica de l'algorisme mitjançant una unió sobre els diferents tipus que es vulguin demanar. Adicionalment de la Constant, Uniforme i Exponencial, s'han afegit la Exponencial truncada, la Hypo-Exponencial, la Hyper-Exponencial i la $k$-Erlang. S'ha emprat una estructura general que s'instancia com un tipus de distribució concreta, i no haver de programar ni la lògica de la generació de paràmetres aleartòris ni que a dins de l'algorisme hi hagi lògica de selecció segons el tipus de distribució. És a dir, la lògica de l'_Event-Scheduling_ i les distribucions dels paràmetres estan completament desacoplades. Això ho hem aconseguit mitjançant l'estructura @distribution.

#figure(
```zig
pub const Distribution = union(enum) {
    constant: f64,
    exponential: f64,
    uniform: struct { min: f64, max: f64 },
    hypo: []f64, // directament les esperances
    hyper: struct { probs: []const f64, rates: []f64 }, // probabilitats del branching i els ratis de cada exponencial
    erlang: struct { k: usize, lambda: f64 }, // shape, scale
    exp_trunc: struct { lambda: f64, max: f64 },

    pub fn sample(self: Distribution, rng: Random) !f64 {
        switch (self) {
            .constant => |val| return val,
            .exponential => |lambda| return sampling.rexp(f64, lambda, rng),
            .uniform => |p| return try sampling.runif(f64, p.min, p.max, rng),
            .hypo => |rates| return sampling.rhypo(f64, rates, rng),
            .hyper => |p| return sampling.rhyper(f64, p.probs, p.rates, rng),
            .erlang => |p| return sampling.rerlang(f64, p.k, p.lambda, rng),
            .exp_trunc => |p| return @min(sampling.rexp(f64, p.lambda, rng), p.max),
        }
    }
}
```,
caption: [Definició de la Unió Distribution]
) <distribution>

`Distribution` és una unió, és a dir, que quan s'instacii serà un dels tipus definits just sota l'estructura (`constant, exponential, uniform, hypo, hyper, erlang, exp_trunc`). La funció sample, implementa en cadascun d'aquests casos la generació d'un nombre aleatòri d'una de les distribucions ja dites. `sampling` conté totes les implementacions sobre l'RNG, concretametn és el fitxer `rng.zig`. Aleshores, la funció `eventBusSimulation` de `simulation.zig` com a argument un `SimConfig`, on totes les magintuds aleatòries son de tipus distribució, tal com es mostra a @simconfig.

#figure(
```zig
pub const SimConfig = struct {
    passenger_interarrival: Distribution,
    bus_interarrival: Distribution,
    bus_capacity: Distribution,
    boarding_time: Distribution,
    system_capacity: u64,
    horizon: f64,
}
```,
caption: [Definició de l'estructura SimConfig ]
) <simconfig>


*Entrada de paràmetres*

Comparat amb la preentrega, és molt farragós introduïr una Hipoexponencial o una $k$-Erlang mitjançant la terminal, així que hem implementat un JSON on s'ha d'introduïr l'estructra `SimConfig` i la distribució apropiada per a cada paràmetre, com es mostra a @input-json: 

#figure(
```json
{
  "iterations": 10000000,
  "seed": 42,
  "sim_config": {
    "horizon": 300.0,
    "system_capacity": 0,
    "passenger_interarrival": { 
        "exponential": 0.30
    },
    "bus_interarrival": { 
        "hypo": [0.333333, 0.142857]
    },
    "bus_capacity": { 
        "exp_trunc": { "lambda": 0.10, "max": 30.0 }
    },
    "boarding_time": { 
        "uniform": {"min": 2.0, "max": 8.0}
    }
  }
}
```,
caption: [Exemple de paràmetres d'entrada de la nostra instància. ]
) <input-json>

La clau `sim_config` ha de contenir els mateixos noms que es mostren a la seva definició @simconfig. Cada un dels paràmetres, ha de tenir la definició del tipus de `Distribution` @distribution i els paràmetres que estiguin sota el tipus de la distribució. Totes les magnituds es mosten en minuts, excepte el `boading_time` que és en segons, tal com s'especifica a l'enunciat de l'entrega.

Adicionalment, es pot escollir el nombre de iteracions que es vol que es faci el programa i quina llavor utilitzar, fet tremendament important per garantir la reproducibilitat dels resultats. En cas de no proveir-se cap llavor (`seed = null`) el programa n'agafarà una d'aleatòria. Si el nombre a `iterations` és exactament 1, es generaran els fitxers de la traça i totes les dades dels usuaris.

Per últim, `system_capacity = 0` farà que el programa carregui `std.math.maxInt(u64)` al programa, és a dir, el sistema tindrà capacitat infinita.

*Fitxers Traça i Usertimes.csv*

Escriure a fitxer dins de un bucle genera una interrupció del programa a nivell de SO per a escriure els continguts nous. Aquesta és una pràctica poc recomanda per obtenir un bon rendiment, així que explicarem com hem implementat l'escriptura a fitxer i explicant una solució vàlida però potencialment perillosa.

La primera solució seria crear una llista amb tots els usuaris i mantenir-ne un punter al primer usuari de la cua. Quan arribés un autobús a la marquesina, aniriem movent el punter a mesura que els usuaris anessin pujant i escrivint-hi en quin moment han pujat a l'autobús, i calculant les magnituds $W_s, W_q, W$ un cop s'hagin servit. Després, es queden emmagatzemats a dins de la llista.

Tot i aquesta aproximació donar resultats correctes, mantienir una ArrayList a memòria amb usuaris ja servits té dos problemes fonamentals quan l'horitzó és arbitrariament llarg:
1. Out-of-memory error: si algun usuari volgués executar la simulació per a un horitzó suficientment llarg, podriem quedar-nos sense memòria dinàmica per a el programa. A mesura que la llista creix, aquesta ocupa més memòria amb dades que ja han estat processades. Tot i que un ordinador modern es quedi sense memòria és altament improbable, és millor tenir la seguretat que no pot passar.
2. Rendiment: A mesura que l'ArrayList creix, el sistema operatiu necessita no només reservar més memòria per a la llista, sinó trobar-ne amb espais contigus per a copiar tota l'estructura amb les noves cel·les buides. Això pot perjudicar molt el rendiment de la simulació en horitzons grans, ja que cada reserva de memòria és una crida a SO que interromp el programa, i cada reorganització de la memòria ho fa més.

La solució implementada ha estat la de l'ús d'un buffer a l'stack, com el que es mostra a @buffer-file. El tamany és d'aquest és 64KB, i dins de la funció de la simulació es passa com a argument el tiputs `uwriter: *Io.Writer`, que és el que la funció utilitzarà per a escriure els usuaris. 

#figure(
  ```zig
  var user_buffer: [64 * 1024]u8 = undefined;
  const user_file = try std.fs.cwd().createFile("usertimes.csv", .{ .read = false });
  var user_writer = user_file.writer(&user_buffer);
  const uwriter = &user_writer.interface;

  ```,
  caption: [Creació d'un fitxer, obertura del mateix i creació d'un punter `Io.Writer`]
) <buffer-file>

Aleshores, quan un autobús comença a servir els usuaris, s'executa el codi @write-buffer. Aquest codi calcula totes les magnituds d'espera per a tots els usuaris que seran servits pel bus (des del primer a la cua fins al capacitat de l'autobús) d'un en un i augmenta el punter per indicar quin és el primer de la llista; és la mateixa lògica que l'aproximació perillosa descrita al principi d'aquesta secció. La diferència rau en que la llista no s'allarga indefinidiament, sinó que un cop un usuari ha estat servit i les magnituds d'espera calculades, s'escriuen al buffer `user_buffer` com una línia del csv resultant. Un cop tots han estat servits, s'actualitza el "punter" (utilitzem un index `first_user_in_queue` per a comoditat) a el primer i es desplacen tots els usuaris que hi ha actualment a la cua tantes posicions com usuaris han pujat desplaçant la memòria de l'arraylist $c$ posicions, el nombre d'usuaris que ja no és a la cua.

#figure(
```zig
const passengers_on_bus = realized_bus_capacity - current_bus_capacity;
const start_index: usize = first_user_in_queue - passengers_on_bus;

for (start_index..first_user_in_queue) |i| {
    const user: *User = &bus_stop.items[i];
    user.*.departure = t_clock;
    user.*.service_time = (t_clock - user.*.about_to_board.?);
    user.*.total_time = user.*.queue_time.? + user.*.service_time.?;
    
    // update accumulators
    sum_queue_time += user.*.queue_time.?;
    sum_service_time += user.*.service_time.?;
    sum_total_time += user.*.total_time.?;
    total_served_passengers += 1;

    if (user_writer) |writer| {
        try user.*.formatCsv(writer);
    }
}

if (first_user_in_queue > 0) {
    bus_stop.replaceRange(gpa, 0, first_user_in_queue, &[_]User{}) catch unreachable;
    first_user_in_queue = 0;
}

acc_boarding = 0.0;
current_bus_capacity = 0;
realized_bus_capacity = 0;
```, caption: [Lògica de processament d'usuaris]
) <write-buffer>

Aquesta aproximació resol els dos potencials problemes que tenia l'ArrayList infinita: si la simulació convergeix, no es necessitarà reservar mai més memòria, ja que anirem copiant la llista en memòria que el programa ja posseix; si la simulació divergeix, encara necessitarem reservar memòria extra, però no tanta, a més a més que és un problema insalvable. Al guardar-se els usuaris formatats en un buffer a stack, no necessitem creixement de memòria dinàmica. Si el buffer s'omplís, Zig invocaria automàticament un `flush` que escriura a fitxer totes les dades que hi hagués, és a dir, es produiria la interrupció del programa, però només cada 64KB que és un nombre absolutament suficient.

Aleshores, per a calcular la mitjana de les tres magnituds d'espera $W, W_s, W_q$, senzillament utilitzem un accumulador per a cada una, i dividim pel nombre d'usuaris servits al final de la simulació.

La traça s'ha implementat d'una manera anàloga.

= Resultats

Un cop implementat el motor de simulació, procedim en verificar la seva correcta programació mitjançant diverses instàncies preliminars per finalment executar la instància assignada al nostre grup.

En el primer apartat es presenten els resultats sota els paràmetres que simplifiquen el sistema a la cua ja descrita en els apartats anteriors. Buscarem calcular principalment el valor de la ocupació mitjana del sistema d'espera $hat(L)$ per comparar-lo amb el valor teòric $L$ aconseguit mitjançant les equacions d'estat estacionari. Després, descriurem la instància assignada al nostre grup (Grup 2), analitzant amb detall les connotacions que aquesta comporta.
== Validació de la $M\/\M^([X])\/1\/K$
Per reduïr la parada d'autobusos a la cua, recordem que tractem amb arribades d'usuaris i de busos Poissonianes de paràmetres $lambda$ i $mu$ respectivament, temps d'embarcament nuls, i capacitats de l'autobús $X$ i marquesina $K$ finites. Això porta a la definició del fitxer de paràmetres d'entrada `input_params/mmx1k.json`.
Fixem els mateixos paràmetres que a la preentrega,
#align(center, table(
  columns: 4,
  stroke: none,
  column-gutter: 2em, // Space between items
  [$lambda := 5$], [$mu := 4$], [$K := 9$], [$X := 3$]
))
amb un horitzó temporal de $T = 10000$. Resolent numèricament el sistema d'equacions globals de l'estat estacionari trobem que el valor teòric de $L$ és, aproximadament, $L approx 1.5770.$ Executem la nostra implementació amb aquests mateixos paràmetres, i generem $B=100000$ trajectòries, de forma que podem estimar $L$ amb alta precisió proporcionant un interval de confiança al nivell $95\%$:
$
  hat(L) = 1.5769 plus.minus 1.19 dot 10^(-4).
$
Observem que el valor calculat és molt proper al valor teòric, i la estimació puntual té una desviació típica molt petita de $hat(sigma) approx 6.0714 dot 10^(-5) $. Altres magnituts del sistema d'espera reportades són:

$
  hat(L_q) = 1.5769 plus.minus 1.19 dot 10^(-4).
$
$
  hat(W_q) = 0.3183 plus.minus 2.20 dot 10^(-5).
$
$
  hat(W_s) = 0.
$

$
  hat(W) = 0.3183 plus.minus 2.20 dot 10^(-5).
$
\

Observem que sota aquests condicions tenim $hat(W_s) = 0$, un fet que és d'esperar ja que en l'arribada d'un bus a la parada aquest serveix immediatament als $X = 3$ primers usuaris de la parada com a conseqüència del temps d'embarcament nul. Aquest fet també provoca que observem $hat(L) = hat(L_q)$, ja que no hi ha pràcticament distinció entre cua i sistema d'espera. Finalment, cal destacar que tenim $hat(L)\/hat(W) approx 4.9541 approx 5 = lambda$, verificant la Llei de Little.

== Definició de la instància #label("sec:inst")
L'entrega final incrementa la complexitat del model de simulació mitjançant distribucions temporals amb memòria i factors de capacitat molt limitats. En particular, els paràmetres assignats pel Grup 2 són els següents:

\

- La capacitat d'un autobús a la seva arribada $X$ segueix una distribució exponencial truncada d'esperança $K^(prime)(e^2-3)\/(2e^2-2) ~ K^prime\/3$, amb $K^(prime) := 30$:

$
  X ~ f_(gamma)(c) = 2 / (K^(prime)(e^2 - 1)) op("exp") lr((2(1 - c / K^prime))), quad 0 <= c <= K^prime  quad [text("usuari")\/text("autobus")].
$

- La capacitat de la marquesina $K$ és il·limitada:

$
    K = + infinity  quad [text("usuari")]. 
$

- El temps de pujada d'un usuari segueix una distribució uniforme entre $a := 2$ i $b := 8$:


$
  tau_(C, i) equiv nu  ~ "Unif"(a,b) quad [text("s")\/text("usuari")].
$

- El temps entre les arribades d'autobusos a la parada segueix una distribució hipoexponencial de dues etapes amb temps mitjans $1\/mu_1 := 3$ i $1\/mu_2 := 7$:

$
  tau_(B, i+1) - tau_(B, i) ~ "Hypo"(mu_1, mu_2) quad [text("min")\/text("autobus")].
$

- El temps entre les arribades d'usuaris a la marquesina segueix una distribució exponencial de paràmetre $lambda_j = rho_j dot mu dot bb(E)(X) quad [text("usuari")\/text("min")]$, $j = 1,dots,4$, on $mu = 1\/ bb(E)(tau_B)$:

$
  tau_(A, i+1) - tau_(A, i) ~ "Exp"(lambda_j) quad j = 1,dots,4 quad [text("min")\/text("usuari")].
$


Observem que $lambda_j$ varia per $j = 1,dots,4$ mitjançant els següents valors de $rho_j$:
#align(center, table(
  columns: 4,
  stroke: none,
  column-gutter: 2em, // Space between items
  [$rho_1 := 0.3$], [$rho_2 := 0.5333$], [$rho_3 := 0.75$], [$rho_4 := 0.9.$]
))
\

A priori podem afirmar que el factor de càrrega $rho_j$ congestiona més el sistema d'espera a mesura que aquest incrementa. El resultat, no obstant, és un sistema d'espera estable per a tot $j = 1,dots,4$. En efecte, busquem calcular la freqüència de servei de passatgers, el qual està comprès per dos factors:

\
  1. Per un costat tenim la freqüència de servei d'usuaris definida per la capacitat dels autobusos en la seva arribada a la parada:
  $
    mu_(text("bus")) = mu dot bb(E)(X) = 0.1 dot 10 = 1 quad [text("usuari")\/text("min")].
  $
  Observem que aquesta seria la freqüència màxima de servei si el temps d'embarcament fos nul.
  2. D'altra banda, un cop un autobús és a la parada, la freqüència de pujada física dels usuaris és:
  $
    mu_(text("pujada")) = (bb(E)(tau_C)\/60)^(-1) = (5\/60)^
    (-1) = 12 quad [text("usuari")\/text("min")].
  $
 La freqüència efectiva de servei del sistema queda definida pel factor que constitueix el vertader _bottleneck_, és a dir, el mínim entre els dos ratis:

  $
    mu^(prime) = min( mu_(text("bus")), mu_(text("pujada"))) = min(1, 12) = 1 quad [text("usuari")\/text("min")].
  $

En el pitjor dels casos tenim un rati d'arribades d'usuaris a la parada de 
$
  lambda_4 = rho_4 dot mu dot bb(E)(X) = 0.9 dot 0.1 dot 10 =  0.9 quad [text("usuari")\/text("min")].
$

Per tant, confirmem l'estabilitat del sistema:
$
  rho_4^prime = lambda_4 \/ mu^prime = 0.9\/1 = 0.9 < 1.
$

Cal destacar però que la marquesina no té capacitat finita, de forma que la cua pot crèixer arbitràriament. No obstant, aquesta garantia d'estabilitat implica que la Llei de Little es verifica en un horitzó temporal llunyà.
\

== Resultats de la instància

Finalment, encapsulem el conjunt de paràmetres de la instància del Grup 2 en la carpeta `input_parameters/grup2`, on trobem els fitxers `rho<j>.json`, un per cada factor de càrrega $rho_j$, $j = 1,dots,4$. Seguint l'enunciat de la pràctica fixem $T = 300$ min, de forma que no estem teòricament al límit, a un context on podríem trobar la Llei de Little, sino que el sistema està en un estat transitori. Donat que en aquest cas l'horitzó temporal és petit, realitzarem en cada cas $B = 10^7$ simulacions. Fixem també el paràmetre `seed = 42` per reproducibilitat:

#figure(
  caption: [Estimació de magnituds del S.E. (Grup 2, $T = 300$ min, $B = 10^7$)],
  table(
    columns: (auto, auto, auto, auto, auto),
    inset: 10pt,
    align: (col, row) => (if col == 0 { left } else { center }),
    stroke: none,
    table.header(
      [*Magnitud*], 
      [*$rho = 0.30$*], 
      [*$rho approx 0.53$*], 
      [*$rho = 0.75$*], 
      [*$rho = 0.90$*],
      table.hline(stroke: 1pt),
    ),
    
    // Row 1: Avg Clients (L)
    $hat(L)$,   
    $3.4890 plus.minus 8.19 dot 10^(-4)$,
    $8.7156 plus.minus 2.64 dot 10^(-3)$,
    $17.8954 plus.minus 6.13 dot 10^(-3)$,
    $28.0258 plus.minus 9.30 dot 10^(-3)$,
    
    // Row 2: Avg Clients Queue (Lq)
    $hat(L_q)$, 
    $3.4316 plus.minus 8.11 dot 10^(-4)$,
    $8.5343 plus.minus 2.63 dot 10^(-3)$,
    $17.5663 plus.minus 6.13 dot 10^(-3)$,
    $27.6051 plus.minus 9.31 dot 10^(-3)$,

    // Row 3: Avg Queue Time (Wq)
    $hat(W_q)$, 
    $11.3146 plus.minus 2.51 dot 10^(-3)$,
    $15.8730 plus.minus 4.86 dot 10^(-3)$,
    $23.4463 plus.minus 8.48 dot 10^(-3)$,
    $30.9548 plus.minus 1.10 dot 10^(-2)$,

    // Row 4: Avg Service Time (Ws)
    $hat(W_s)$, 
    $0.2815 plus.minus 3.50 dot 10^(-5)$,
    $0.4443 plus.minus 5.30 dot 10^(-5)$,
    $0.5714 plus.minus 5.70 dot 10^(-5)$,
    $0.6327 plus.minus 5.80 dot 10^(-5)$,

    // Row 5: Avg Total Time (W)
    $hat(W)$,   
    $11.5960 plus.minus 2.53 dot 10^(-3)$,
    $16.3173 plus.minus 4.89 dot 10^(-3)$,
    $24.0177 plus.minus 8.49 dot 10^(-3)$,
    $31.5874 plus.minus 1.10 dot 10^(-2)$,

    // Row 6: L/W (Little's Law Check)
    $hat(L)\/hat(W)$,   
    $0.3008$,
    $0.5341$,
    $0.7450$,
    $0.8872$,

    // Row 7: Lq/Wq
    $hat(L_q)\/hat(W_q)$,   
    $0.3033$,
    $0.5377$,
    $0.7492$,
    $0.8917$,

    table.hline(stroke: 1pt),
  ),
  supplement: "Taula"
)<tab:inst>
\
La @tab:inst presenta els resultats obtinguts després d'executar $B= 10^7$ de rèpliques per a cada escenari de càrrega. L'anàlisi d'aquestes magnituds ens permet destacar quatre comportaments fonamentals del sistema:

+ 
  $hat(L)\/hat(W)$ aproxima amb precisió la freqüència d'arribades ($lambda approx rho$) per als escenaris de càrrega baixa i mitjana. No obstant això, per al cas de màxima congestió ($rho=0.90$), el rati obtingut és de $0.8872$, lleugerament inferior al teòric.

+ 
  A diferència de models més simples, el temps mig d'espera no és constant sinó que creix significativament amb la congestió.
  - Amb baixa càrrega, $rho=0.3$, l'espera és d'aproximadament $11.3$ minuts. Tenint en compte que l'interval mig entre busos és de aproximadament $10$ minuts, això indica que la gran majoria d'usuaris pugen al primer autobús que arriba.
  - Amb alta càrrega, $rho=0.9$, l'espera es dispara fins als $31$ minuts. Això implica que, en mitjana, un usuari ha de deixar passar entre 2 i 3 autobusos abans de poder pujar-hi, evidenciant l'impacte crític de la capacitat limitada provocada per la distribució exponencial truncada.

+ 
  La longitud mitjana de la cua creix de manera no lineal. Passem de tenir $3.4$ usuaris esperant en el cas tranquil a $27.6$ usuaris en el cas congestionat.

+ 
  Els intervals de confiança obtinguts són extremadament estrets (amb un error relatiu inferior a l'1% en tots els casos). Això confirma que el nombre de rèpliques utilitzat ($B=10^7$) ha estat suficient per proporcionar estimadors molt fiables del comportament mitjà del sistema.

\

#text(blue)[
  TODO: Posar fotos rexulonas de histogrames de $W$ com demana our lord and saviour
]

== Validació de la Llei de Little

A l'execució de la configuració desginada per l'enunciat de la pràcica hem pogut observar com la proporció entre els valors estimats de $L$ i $W$, així com $L_q$ i $W_q$ s'aproxima en cada cas a $lambda_j$. No obstant, aquesta aproximació no és molt propera, un fet que és d'esperar degut al horitzó fixat de $T = 300$. 
\

En aquest apartat volem anar més enllà del _scope_ del que es demana a l'enunciat per aprofitar per posar a prova la nostra implementació del simulador, i aproximar de forma arbitràriament precisa aquests quocients mitjançant un horitzó de $T = 10^6$ min i $B = 10^4$ simulacions mentres mantenim la resta de paràmetres igual. Els fitxers de configuració de paràmetres en aquest cas són `input_params/little/rho<j>.json` per $j=1,...,4$

#figure(
  caption: [Estimació de magnituds del S.E. (Grup 2, $T = 10^6$ min, $B = 10^4$)],
  table(
    columns: (auto, auto, auto, auto, auto),
    inset: 10pt,
    align: (col, row) => (if col == 0 { left } else { center }),
    stroke: none,
    table.header(
      [*Magnitud*], 
      [*$rho = 0.30$*], 
      [*$rho approx 0.53$*], 
      [*$rho = 0.75$*], 
      [*$rho = 0.90$*],
      table.hline(stroke: 1pt),
    ),
    
    // Row 1: Avg Clients (L)
    $hat(L)$,   
    $3.6855 plus.minus 5.07 dot 10^(-4)$,
    $9.9791 plus.minus 2.22 dot 10^(-3)$,
    $29.0626 plus.minus 1.47 dot 10^(-2)$,
    $193.5186 plus.minus 5.94 dot 10^(-1)$,
    
    // Row 2: Avg Clients Queue (Lq)
    $hat(L_q)$, 
    $3.6229 plus.minus 5.02 dot 10^(-4)$,
    $9.7723 plus.minus 2.21 dot 10^(-3)$,
    $28.6535 plus.minus 1.46 dot 10^(-2)$,
    $192.9403 plus.minus 5.94 dot 10^(-1)$,

    // Row 3: Avg Queue Time (Wq)
    $hat(W_q)$, 
    $11.9932 plus.minus 1.57 dot 10^(-3)$,
    $18.2411 plus.minus 4.03 dot 10^(-3)$,
    $38.1210 plus.minus 1.93 dot 10^(-2)$,
    $214.2862 plus.minus 6.59 dot 10^(-1)$,

    // Row 4: Avg Service Time (Ws)
    $hat(W_s)$, 
    $0.2923 plus.minus 2.10 dot 10^(-5)$,
    $0.4712 plus.minus 3.10 dot 10^(-5)$,
    $0.6289 plus.minus 3.50 dot 10^(-5)$,
    $0.7260 plus.minus 3.50 dot 10^(-5)$,

    // Row 5: Avg Total Time (W)
    $hat(W)$,   
    $12.2855 plus.minus 1.58 dot 10^(-3)$,
    $18.7123 plus.minus 4.05 dot 10^(-3)$,
    $38.7499 plus.minus 1.94 dot 10^(-2)$,
    $215.0122 plus.minus 6.59 dot 10^(-1)$,

    // Row 6: L/W (Little's Law Check)
    $hat(L)\/hat(W)$,   
    $0.2999$,
    $0.5333$,
    $0.7500$,
    $0.9000$,

    // Row 7: Lq/Wq
    $hat(L_q)\/hat(W_q)$,   
    $0.3021$,
    $0.5357$,
    $0.7516$,
    $0.9004$,

    table.hline(stroke: 1pt),
  ),
  supplement: "Taula"
)<tab:little>
\
A la @tab:little presentem els resultats amb un horitzó temporal llunyà ($T = 10^6$), la qual cosa ens permet observar el vertader règim estacionari del sistema. En efecte:

+ 
  Comparant amb els resultats anteriors ($T=300$), veiem que per a càrregues baixes ($rho=0.3$) els resultats són idèntics ($hat(L_q) approx 3.6$). En canvi, per a $rho=0.9$, la cua mitjana ha passat de $28$ a $193$. Això demostra que amb $T=300$ el sistema encara es trobava en un estat transitori i no havia tingut temps d'assolir l'estat d'equilibri.

+
  Tot i que per a $rho=0.90$ observem valors molt elevats ($hat(L_q) approx 193$ usuaris), aquests són valors finits i convergents. Si el sistema fos inestable ($rho > 1$), amb un horitzó de $T=10^6$, la cua hauria crescut arbitràriament. El fet que s'estabilitzi confirma que $rho < 1$, tot i que el sistema es troba en un estat de congestió màxima.
+ 
  Gràcies a l'extensió de $T$, observem com el rati $hat(L)\/hat(W)$ per a $rho=0.90$ és exactament $0.9000$, el·liminant així el biaix introduït per la situació d'alta congestió al règim transitori.

+
  Malgrat ser estable matemàticament, un temps d'espera de $hat(W_q) approx 214$ minuts (més de 3.5 hores) indica que el servei és inacceptable a efectes pràctics.

#pagebreak()

= Conclusions

La realització d'aquesta pràctica ha permès desenvolupar i validar un motor de _Discrete-Event Simulation_ capaç de modelitzar sistemes de cues complexos amb distribucions amb memòria. A partir de l'anàlisi dels resultats presentats a l'apartat anterior, extraiem les següents conclusions principals:

+ 
  La implementació ha demostrat ser correcta i precisa. En la primera fase, la coincidència gairebé exacta entre els valors teòrics i els simulats per a la cua $M\/M^([X])\/1\/K$ (amb un error relatiu inferior al $0.01%$) ha servit per certificar el bon funcionament del nucli del simulador.

+ 
  L'extensió de l'horitzó temporal de $T = 300$ min a $T = 10^6$ min ens ha demostrat que en sistemes amb alta càrrega ($rho=0.9$), les simulacions de curta durada introdueixen un biaix sobre les estimacions de les magnituts del sistema, ja que mostra un estat transitori on la cua sembla moderada ($hat(L_q) approx 28$). Ha estat amb $T = 10^6$ que hem pogut observar el veritable règim estacionari, on la cua s'estabilitza en valors molt superiors ($hat(L_q) approx 193$).

+ 
  Hem comprovat que la Llei de Little es troba present en tots els casos, però la seva verificació empírica depèn estretament de l'estabilitat temporal. Mentre que en l'escenari de $T=300$ s'observaven petites desviacions degudes a l'estat transitori, en l'escenari de $T=10^6$ la relació s'ha complert amb gran precisió fins i tot en el pitjor cas de càrrega.

+ 
  Finalment, l'anàlisi de la instància ens porta a una conclusió pràctica rellevant des del punt de vista més aplicat dins de la Investigació Operativa. Tot i que hem demostrat analíticament i empíricament que el sistema és estable per a $rho=0.9$, el resultat és operativament inviable. Un temps d'espera mitjà de més de 3.5 hores per agafar un autobús és inacceptable des del punt de vista de l'usuari. Això demostra que garantir $rho < 1$ és una condició necessària per a l'estabilitat, però no suficient per a garantir una qualitat de servei adequada. Això permet arribar a la conclusió operativa que per arribar un funcionament òptim, el sistema requeriria augmentar la freqüència de pas o la capacitat dels vehicles per reduir el factor de càrrega a nivells factibles.

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

A l'entrega s'hi poden trobar els binaris per a les tres plataformes i arquitectures principals (MacOS (aarch64), Windows (x86) i GNU-Linux (x86)) per executar el codi. Per tant, per a executar-lo és tan senzill com obrir una terminal, navegar fins a la carpeta on es troba el binari i executar-lo. El programa necessita un argument a la terminal, el camí relatiu des de l'executable al json.

Ara bé, si el lector és desconfiat a executar un binari trobat a internet - fet no només comprensible sinó respectable - aquí donem informació tècnica per tal de compilar el programa.

Primer, la versió de Zig emprada ha estat la 0.15.2, i és la única dependència. Aleshores, s'ha de descarregar zig pel seu sistema operatiu i arqutectura seguint les instruccions a la pàgina de Zig @zig. Es pot comprovar que la instal·lació ha estat exitosa corrent a una terminal `zig version`, on hauria d'apareixer la versió actual.

Per a compilar el programa, col·loquis sobre l'arrel del projecte, que és un hi hauria d'haver-hi dos fitxers: `build.zig` i `build.zig.zon`. Zig és ell mateix el compilador de Zig (és l'equivalent a make en C i C++) i per tant nosaltres hem definit quines opcions hi ha al compilar el programa.
- `zig build`: compila el programa i no l'executa. El programa es troba a `/zig-out/`, i des d'allà es pot executar.
- `zig build run`: compila i executa el programa. Per passar-li arguments, s'ha d'usar dos guions de la següent manera `zig build run -- help`, sinó el build system l'entendrà com un argument. La compilació en aquest i en l'anterior és en mode debug, per tant no tindrà un rendiment molt alt.
- `zig build release`: compila el programa per a les tres plataformes i aquitectures ja nombrades, amb mode `ReleaseSafe`, on se salta diverses comprovacions i accelera substancialment el temps d'execució del programa.

En cas d'errors, sempre es pot utilitzar directament `zig run src/main.zig` i també funcionaria, tot i que la compilació serà en mode debug.

Qualsevol problema en la compilació o execució no es dubti a contactar amb els autors.

#pagebreak()
= MeanHeap struct _versus_ MeanHeap MultiArrayList

Una de les proves que s'han realitzat per a obtenir un bon rendiment ha estat la implementació del heap amb una MultiArrayList. En un llenguatge de programació orientat a objectes, normalment la estructura natural a tenir és una llista d'objectes iguals, que és com està implementat el heap a `structheap.zig`: mantenim una `ArrayList(Events)` i cada element de la llista conté una estructura `Event`. 

#figure(
  ```zig
pub const Event = struct {
    time: f64,
    type: EventType,
    id: u64,
};
  ```
)
Així i tot, només hi ha un element d'`Event` al que se li faci un accés real (`time`), i per tant estem movent a la memòria cau una estructura que consta de 3 elements quan podria ser una d'una.

Al fitxer `multiheap.zig` s'ha reimplementat la mateixa estructura amb una `MulitArrayList`, on el que es fa és en comptes de tenir una llista d'structs, s'implementa com una estructura amb tres llistes, una per a cada argument. Aquesta implementació pot millorar el rendiment ja que només s'ha de moure tota l'estructura només un cop, mentre que les comparacions del camp temps es fan en una llista, que serà més ràpid que movent tota l'estructura i accedint al camp correcte una per una.

Així i tot, no s'han aconseguit millores empíriques amb aquesta nova implementació. Sospitem que la raó és que l'estructura `Event` és massa petita per verure beneficis reals al dividir-la en multiples llistes, així que l'implementació final utiltiza `structheap.zig`.


#pagebreak()
= Implementacions Extres <app:implementacions_extres>

Per entendre millor l'algorisme de l'_Event-Scheduling_, el nostre flux de treball ha necessitat de dues implementacions més primerenques a mode de prototip i de prova de concepte.

El primer pas va ser reimplementar el codi d'exemple d'una cua $M\/M\/1$ en Python, i comprovar que els resultats eren exactament els mateixos. Curiosament, la nostra implementació ha resultat ser bastant diferent de la original, així que l'adjuntem al codi de la pràctica al fitxer `mm1.py`.

Seguidament, per confirmar que erem capaços d'implementar Zig amb prou soltura, varem traduïr la implementació del `mm1.py` a Zig. Aquest fitxer també es pot trobar a `mm1.zig`.

Com a detall extra, vàrem comentar de paraula que entregariem una llibreria de python amb l'algorisme compilat. Malauradament, això no ha estat possible per problemes tècnics que van més enllà de l'abast de la pràctica i dels nostres coneixements. Per poder empaquetar el binari de Zig en una llibreria de Python, s'ha intentat usar `Ziggy-Pydust`, una llibreria que genera totes les dependències extres per a poder cridar el binari des de Python. Amb poc intents i seguint la documentació, hem aconseguit que funcioni perfectament per a Linux, però la llibreria és massa jove com per a tenir support per a Windows, per això vam haver de desestimar la iniciativa i entregar un binari directament.


#bibliography("works.yml")
