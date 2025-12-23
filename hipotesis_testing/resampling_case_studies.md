2) (2!)^N
$delta = A - B$: temps de pendre l'aspirina menys el temps de no perdre-la.

H_0: "El sagnat d'abans és igual que el de després" $A=B$ o $ delta = 0$
H_A: El sagnat d'abans és menor que el de després d'ingerir  $delta > 0$

3) estadístic: mitjana de la diferència, no la diferència de la mitjana. Mitjana o mediana.


# Case study 4 

Relació entre més salari i absentisme laboral.
Aquest test no va entre comparar o no, sinó relacionar. Hi ha relació entre aquestes dues variables?
El text diu que ha de ser un model lineal, estimar beta_0 i beta_1.

X -> absence, Y -> wages 

$Y = beta_1*X + beta_0$

Volem veure la significancia de beta_0 i beta_1, és a dir que siguin correctes.

Test 1:
H_0: beta_0 = 0
H_1: beta_0 != 0

Test 2:
H_0: beta_1 = 0
H_1: beta_1 != 0

P2: només s'ha de permutar una columna. Permutacions: N! -> 15! -> Test de MonteCarlo

P3: permuto, calcula el model lineal i guarda els valors d'a i b. Repetir aquest procés i ploteja totes les a i b que t'has guardat.

# Case Study 5

Volem detectar com de pitjor avaluen els no experimentats que els experimentats.

Dos grups: experimentats vs novells.
X -> nombre d'errors detectats.
No li importen les persones concretes, és igual.

H_0: sigma_n == sigma_e
H_1: sigma_n > sigma_e

P2) Dos grups, permutem per columnes. PR_24^(12,12) = 2.7E6 -> test de montecarlo

P3) Estadístic pel còmput de variabilitats: $sigma_n/sigma_e$
NOTA: ni se t'acudeixi restar les variances, pot ser que apareguin valors negatius en alguna permutació -> error TREMENDAMENT greu.

(nota, a les solucions l'home fa un exacte per ensenyar-nos un altre estadístic)


