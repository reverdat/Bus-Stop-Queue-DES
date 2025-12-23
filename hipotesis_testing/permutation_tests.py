import marimo

__generated_with = "0.16.5"
app = marimo.App(width="medium")


@app.cell
def _():
    import marimo as mo
    import scipy.stats as stats
    import polars as pl
    import pandas as pd
    import numpy as np
    import matplotlib.pyplot as plt
    return mo, np, pl, plt, stats


@app.cell
def _(mo):
    mo.md(
        r"""
    # Cas d'estudi 1: Tast de vins

    Tenim tres grups de persones, A, B, i C. Cada grup ha fet un tast de vi amb el mateix vi, però amb circumstàncies diferents. El grup A ha estat un tast prèmium, el grup B ha estat un tast normal i el C un tast deixat.

    L'objectiu del test d'hipòtesi seria veure si l'entorn ha tingut algun tipus d'influència sobre la percepció del vi dels participants de l'estudi.
    """
    )
    return


@app.cell
def _(pl):
    df1 = pl.read_csv("casestudy1.csv")
    df1
    return (df1,)


@app.cell
def _(mo):
    mo.md(
        r"""
    ## 1. Test

    Seleccionem un test ANOVA d'anàlisi de la variança entre els tres grups.

    ## 2. Hipòtesi Nula

    Escollim l'hipòtesi nula com la més conservadora que hem d'intentar rebutjar. Fem per tant

    $$
    H_0: \mu_A = \mu_B = \mu_C \\
    $$

    El test d'hipòtesi ens intentarà rebutjar o no rebutjar aquesta hipòtesi.

    ## 3. Càlcul del $p$-valor

    Per a fer-ho emprem un test de permutacions. Els passos dins del test de permutacions seran els següents:

    ### 3.1 Estadístic

    Escollim l'$F$ estadístic obtingut de l'anova.

    ### 3.2 Trobem l'estadístic mostral

    $F_M$ serà el valor de l'$F$ estadístic de la mostra actual, és a dir, realitzar un ANOVA sobre els tres grups A, B i C.
    """
    )
    return


@app.cell
def _(df1, stats):
    Ag = df1["A"].to_numpy()
    Bg = df1["B"].to_numpy()
    Cg = df1["C"].to_numpy()

    f_sample = stats.f_oneway(Ag, Bg, Cg).statistic
    print(f"L'estadístic F de la mostra és {f_sample}")
    return Ag, Bg, Cg, f_sample


@app.cell
def _(mo):
    mo.md(
        r"""
    ### Nombre de permutacions
    Un cop sabem l'ANOVA de la mostra, hem de decidir quin mètode usar:
    - Exacte: calcularem l'ANOVA de totes les permutacions
    - MonteCarlo: calcularem l'ANOVA de les permutacions informatives mitjançant el mètode de MonteCarlo.

    Per a saber-ho, depen exclusivament del nombre de permutacions possibles que té aquest problema.

    Tenim tres grups de persones completament diferents, això ens dona un total de 24 observacions. Aquestes persones es poden partir en tres grups, A, B, C iguals, i és clar que la permutació que volem realitzar és moure una mostra del grup A a un altre grup i observar com canvia l'ANOVA. Això és clarament 

    $$R_{8,8,8}^{24} = \binom{24}{8} \binom{16}{8} \binom{8}{8}$$
    """
    )
    return


@app.cell
def _():
    from scipy.special import comb

    n_perm = comb(N=24, k=8, exact=True)*comb(N=16, k=8, exact=True)
    print(f"Hi ha {n_perm} ({n_perm:.2e}) permutacions possibles")
    return


@app.cell
def _(mo):
    mo.md(
        r"""
    Degut a ser un nombre molt gran, el mètode de MonteCarlo és la única opció factible.

    ### 3.4 Trobar la distribució sota $H_0$

    Utilitzant un subconjunt de permutacions informatives, generem la distribució sota la hipòtesi nula.
    """
    )
    return


@app.cell
def _(Ag, Bg, Cg, np, stats):
    n_resamples = 9999 
    total_sample = np.concatenate((Ag, Bg, Cg))

    perms = [np.random.permutation(total_sample) for _ in range(0,n_resamples)]

    f_statistics = [
        stats.f_oneway(element[0:8], element[8:16], element[16:24]).statistic
        for element in perms
    ]
    return f_statistics, n_resamples


@app.cell
def _(f_sample, f_statistics, plt):
    plt.figure()
    plt.hist(f_statistics, bins=20)
    plt.axvline(x=f_sample, color='r') 
    plt.show()
    return


@app.cell
def _(mo):
    mo.md(
        r"""
    ### 3.5 Càlcul del $p$-valor

    Aproximem el $p$-valor mitjançant MonteCarlo dividint el nombre d'elements per sota del valor de l'estadístic mostral entre el nombre de sampleig de hem volgut utilitzar, és a dir amb la fòrmula.

    $$
    p \approx \frac{\sum_{i=1}^n I(F_M \le F_i) + 1}{n + 1}
    $$

    on $I$ és la funció indicatriu. El $+1$ s'ha de col·locar com a garantia a que sempre hi haurà un element major que la distribució mostral, ja que en cas contrari, ens quedaria un $p$-valor de 0, valor estadísticament sense sen
    """
    )
    return


@app.cell
def _(f_sample, f_statistics):
    def pvalue_mc(sample_statistic, mc_statistics):
        extreme_observations = sum(sample_statistic <= s for s in mc_statistics)
        pvalue = (extreme_observations + 1) / (len(mc_statistics) + 1)
        return pvalue, extreme_observations

    pvalue, extreme_observations = pvalue_mc(f_sample, f_statistics)
    print(f"El p-valor és de {pvalue:.3e}. Hi ha {extreme_observations} observacions sobre F mostral")
    return (pvalue_mc,)


@app.cell
def _(mo):
    mo.md(
        r"""
    Com es pot veure, el $p$-valor (a menys que s'hagi tingut molta mala sort...) és bastant petit.

    ## 4. Significancia Estadística

    El $p$-valor és baix, és a dir, que la simulació sota $H_0$ són poc probables de succeir com a fenòmen aleatòri, ja que el valor de $p$ és significant.

    ## 5. Conclusió

    Per tant, degut a la significancia del $p$-valor, es pot dir que hi ha una forta evidència en que l'observació d'aquest esdeveniment degut a un efecte de l'aleatorietat és molt poc probable, i per tant les dades es poden prendre com una evidència clara i de gran magnitud contra la hipòtesi nul·la; per tant la presentació dels vins ha tingut effecte sobre la percepció dels individus encara que sigui el mateix vi.
    """
    )
    return


@app.cell
def _(mo):
    mo.md(
        r"""
    # Cas d'estudi 2: Tast de vins 2. 

    Assumim ara que en comptes de 24 mostres, les mateixes 8 persones fan el test A, B, i C. Un cop això és així, podem seguir demostrant la mateixa hipòtesi?

    ## 1. Test

    Seguirem utilitzant un ANOVA entre els tres grups, però la metodologia de l'experiment seguirà el mètode de [Randomized Block Design](https://en.wikipedia.org/wiki/Generalized_randomized_block_design). S'utilitzen per mirar la interacció entre [blocs](https://en.wikipedia.org/wiki/Blocking_(statistics)) (agrupaments de dades similars en una o diverses caractererístiques) contra tractaments. Cada tractament es replica com a mínim dues vegades per bloc, permetent l'estimació dels termes d'interacció d'un _model lineal_. La idea enginyosa és que els blocs s'agrupen amb la _variable de no interès_ (nuisance parameter), és a dir, la que creiem que no explicarà la varianca de la relació i és la qual haurem de permutar per comprovar si les altres dues tenen realment relació.

    Hem de definir per tant els blocs, els termes interactius i el model lineal:
    + Objectiu: quina relació volem modelitzar? la relació entre la variable `tast` i la variable `valoració`.
    + Blocs: La variable de no interès son els `subjecte`, perque cadascun ha participat en els tres grups, i la relació real està en els grups, no amb quin individu ha donat la valoració. Per tant, els blocks seran `(valoracio_A_i, valoracio_B_i, valoracio_B_i)` on `i=1..8` nombre de subjectes diferents.
    + Randomització: dins de cada bloc randomitzem les valoracions (això és el $3!$ que s'ha mencionat abans al text.) 

    ## 2. Hipòtesi Nul·la

    Utilitzem la mateixa hipòtesi nul·la

    $$H_0: \mu_A = \mu_B = \mu_C$$

    ## 3. Càlcul del $p$-valor

    Al utilitzar el mateix estadístic, ja tenim el còmput mostral. El que canvia ara són les permutacions.

    Al primer cas d'estudi, permutavem l'etiqueta A, B o C segons el grup. Ara però, no té sentit permutar etiquetes de persones diferents, així que per a cada individu només tenim $3!$ posicions. Sabent el nombre de mostres obtenim

    $$R_3^8 = (3!)^8$$
    """
    )
    return


@app.cell
def _():
    from math import factorial

    num_perm_total = factorial(3)**8
    print(f"Hi ha un total de {num_perm_total} ({num_perm_total:.2e}) combinacions")
    return


@app.cell
def _(mo):
    mo.md(
        r"""
    El nombre és adequat per un test de MonteCarlo, tot i que un exacte (si tens mijta horeta...) també és possible d'utilitzar. Per a fer el codi lleugerament més llegible i eficient, primer he generat totes les possibles iteracions mitjançant un generador de python a `all_combinations_iterator`, i d'allà n'extrec una mostra per a fer montecarlo.

    Per a calcular, primer convertim el dataset de tres columnes A, B i C en un dataset per facilitat.
    """
    )
    return


@app.cell
def _(df1):
    df2 = (
        df1 
        .with_row_index(name="Subjecte", offset=1) # Adds index col 'Subjecte' starting at 1
        .unpivot(
            index="Subjecte", 
            on=["A", "B", "C"],
            variable_name="Tast", 
            value_name="Valoracio"
        )
        .sort("Subjecte")
    )
    # el convertim a pandas per utilitzar-lo directament amb stats model
    df2 = df2.to_pandas()
    df2
    return (df2,)


@app.cell
def _(mo):
    mo.md(r"""Un cop amb les dades, creem un model lineal que relacioni Valoracio amb Tast i Grup amb les dades actuals i en calculem l'$F$ estadístic.""")
    return


@app.cell
def _(df2):
    import statsmodels.api as sm
    from statsmodels.formula.api import ols
    from time import time

    def f_statistic_sample(df2):
        model_obs = ols('Valoracio ~ C(Subjecte) + C(Tast)', data=df2).fit()
        anova_table_obs = sm.stats.anova_lm(model_obs, type=2)

        return anova_table_obs

    t1 = time()
    anova_table_obs = f_statistic_sample(df2)
    t2 = time()

    print(anova_table_obs)
    f_obs = anova_table_obs.loc['C(Tast)', 'F']
    print(f"\nF-estatistic mostral (f.obs): {f_obs:.4f} in {t2-t1}")
    return f_obs, ols, sm


@app.cell
def _(mo):
    mo.md(r"""Permutem per a fer montecarlo: ens guardem els $F$-estadístics d'un subconjunt de premutacions informatives per a fer la distribució de l'estadístic sota la hipòtesi nu""")
    return


@app.cell
def _(df2, n_resamples, np, ols, pl, sm):
    # funció bastant ineficient però acaba en uns dos minuts!
    # l'alternativa més eficient és usar OLS amb numpy i productes però s'enrreda molt ràpid
    def permute_and_fit(df: pl.DataFrame):
        df_perm_pd = df.copy()

        # permuta aplicant una transformació per subjecte (group)
        df_perm_pd['Valoracio'] = df_perm_pd.groupby('Subjecte')['Valoracio'] \
                                          .transform(np.random.permutation)

        model_perm = ols('Valoracio ~ C(Subjecte) + C(Tast)', data=df_perm_pd).fit()
        anova_table_perm = sm.stats.anova_lm(model_perm, type=2)
        return anova_table_perm.loc['C(Tast)', 'F']

    f_perm_comp = [permute_and_fit(df2) for _ in range(n_resamples)]
    len(f_perm_comp)
    return (f_perm_comp,)


@app.cell
def _(f_obs, f_perm_comp, pvalue_mc):
    p_value, ex_ob = pvalue_mc(f_obs, f_perm_comp)

    print(f"El p-valor és de {p_value:.3e}. Hi ha {ex_ob} observacions sobre F mostral")
    return


@app.cell
def _(f_obs, f_perm_comp, plt):
    plt.figure()
    plt.hist(f_perm_comp, bins=30)
    plt.axvline(x=f_obs, color='r') 
    plt.show()
    return


@app.cell
def _(mo):
    mo.md(
        r"""
    Com s'aprecia a la gràfica, clarament el p valor és significatiu. Concretament, NO hi ha cap permutació amb un estadístic per sobre l'estadístic mostral! Això també mostra la importancia d'afergir el +1 tan al numerador com al denominador, sinó sortiria un $p$-valor de zero.

    ## 4. Significancia Estadística

    El p-valor de $10^{-4}$ és absolutament significatiu.

    ## 5. Conclusió

    Es rebutja la hipòtesi nul·la ja que el p-valor és absolutament significant, i per tant, l'efecte de l'entorn ha infuit en la valoració del vi absolutament, molt més ara que s'han agrupat les persones en blocs que no només en el cas 1.
    """
    )
    return


if __name__ == "__main__":
    app.run()
