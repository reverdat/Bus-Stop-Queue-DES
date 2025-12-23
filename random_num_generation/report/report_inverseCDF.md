# Mètode de generació mitjançant la funció inversa.

Aquest document és un comentari sobre el codi entregat a `rng.zig` i les decisions preses per implementar aquest programa.

## Zig: què és i perquè?
Zig és un projecte dirigit per Andrew Kelly, i busca crear un llenguatge de programació senzill, amb control de memòria i sense amagar cap control de flux. Rep molta influència de C, i tot i no haver arribat a la 1.0. (actualment 0.15.1) té un rendiment comparable a C o C++, al permetre també gestió manual de la memòria.

## Generació de Nombres Aleatoris
Al contrari d'R, que té un sistema complex per generar nombres alearòris provist, la primera decisió a prendre és escollir quin generador de nombres aleat̀òris volem utilitzar. Per sort, la llibreria estàndard de zig `std` té diverses implementacions de com generar nombres aleatòris, juntament amb una interfície `Random`, que ens prové amb funcions essencials com `float()` per generar un nombre real aleatori o `intLessThan()` per generar un enter.

Com que l'objectiu d'aquesta entrega és entendre el mètode de la funció inversa, m'he limitat a implementar les funcions exclusivament per tipus `f32`i `f64`.

La `std` ens prové de diversos algorismes per generar els nombres aleatoris, com per exemple Xoshiro256++, que utilitza les operacions XOR, rotate, shift rotate sobre un nombre de 64 bits per a obtenir els nombres aleatoris. És el més ràpid i no és criptograficament segur, però a efectes pràctics és més que suficient pel que ens ocupa.

## runif

El primer pas pel mètode de la inversa és generar els valors de la distribució uniforme, que és la funció `runif()`. Els arguments que rep son el tipus de valor a generar (`f32 o f64`) el mínim, el màxim i el generador de nombres aleatoris que es vulgui utilitzar, així no s'ha d'instanciar més vegades durant l'execució del programa.

Matemàticament, és ben senzill. S'utilitza la funció `rng.float()` per a obtenir un nombre entre 0 i 1 del tipus T, i després utilitzem l'escalat classic $a + (b-a) * u$.

## Exponencial, Weibull i Gamma

[EXPAND] utilitzem directament la funció inversa de cada una, cridem una sample de runif i l'apliquem per a obtenir-ho.

Per a comprovar els valors, aquests s'escriuen en un fitxer a memòria, juntament amb un script de python que genera un histograma sobre les dades per verificar visualment si la forma és l'esperada.

## Detalls sobre la implementació
El programa provist només usa array de memòria predeterminada per generar les distribucions ja que és tant petit que, per obtenir una altra distribució seria tan senzill com canviar el nombre. Així i tot, s'enten que no és un comportament òptim per a un programa, on s'esperaria un executable que et dongues les distribucions amb un nombre dinàmic. en aquest cas d'hauria d'utilitzar una ArrayList per aconseguir memòria dinàmica.




