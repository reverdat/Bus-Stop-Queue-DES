"""
## plotting.py

This module contains all functions
which generate Matplotlib figures
given a sample
"""

from typing import Optional, Tuple, Dict

import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np

from dgm import WeibullDistribution


def plot_histogram_weibull(
    sample: np.ndarray, params: Optional[Dict] = None, ax=None, save_plot: bool = True
):
    if ax is None:
        fig, ax = plt.subplots()
    else:
        fig = ax.figure

    sns.histplot(x=sample, kde=False, stat="density", color="white", ax=ax)
    sns.kdeplot(x=sample, color="black", ax=ax)
    ax.set_xlabel("Failure time")

    if ax is None:
        fig.suptitle("Weibull Distribution sample", fontsize=14)

    if params is not None:
        ax.set_title(f"(α = {params['alpha']}, β = {params['beta']})")

    if save_plot and params is not None and ax is None:
        plt.savefig(
            f"weibull_{params['alpha']}_{params['beta']}.png",
            dpi=500,
            bbox_inches="tight",
        )
        plt.close(fig)
    elif not save_plot and ax is None:
        plt.show()

def plot_grid_weibull(sample_grid: Dict[Tuple, np.ndarray], save_plot: bool = True):
    n_scenarios = len(list(sample_grid.keys()))
    n_rows = int(np.ceil(n_scenarios / 3)) 
    fig, axs = plt.subplots(nrows=n_rows, ncols=3, figsize=(14, 4 * n_rows))
    axs = axs.flatten()  
    
    sample_size = len(next(iter(sample_grid.values())))
    
    beta_interpretations = {
        0.8: "Infant Mortality\n(β < 1)",
        1.0: "Constant Failure\n(β = 1)", 
        3.0: "Wear-Out\n(β > 1)"
    }
    
    for i, (params, sample) in enumerate(sample_grid.items()):
        plot_histogram_weibull(
            sample,
            params={"alpha": params[0], "beta": params[1]},
            ax=axs[i],
            save_plot=False 
        )
    
    beta_vals = sorted(set(beta for alpha, beta in sample_grid.keys()))
    for col, beta in enumerate(beta_vals):
        fig.text(
            (col + 0.56) / 3,  
            0.88,             
            beta_interpretations[beta],
            ha='center',
            va='bottom',
            fontsize=12,
            fontweight='bold'
        )
    
    plt.suptitle("Weibull Distribution Samples", fontsize=20, y=0.98)
    plt.figtext(0.48, 0.94, f"n = {sample_size}", 
                fontsize=14, style='italic') 
    plt.tight_layout(rect=[0, 0, 1, 0.92])  
    
    if save_plot:
        plt.savefig(f"weibull_grid_{sample_size}.png", dpi=500, bbox_inches='tight')
        plt.close(fig)  
    else:
        plt.show()


"""
TODO:
Alguns dels plots que caldria fer per presentar resultats:

    ## A nivell local de la simulació

    1. Figura amb dos plots en dues columnes: una per alpha i l'altre per beta.
    En cada plot, scatterplot dels `estimates` de `simulation.ParameterEstimate`,
    amb línia vertical corresponent amb la mitja $\bar{\theta}$, línia vertical 
    amb el valor real $\theta$ i dues línies simètriques al voltant de 
    $\bar{\theta}$ corresponent al l'interval de confiança al 95% 
    obtingut al fer $\bar{\theta} \pm 1.96 \text{EmpSE}$. 
    Posar el sample size, mètode de inferència com a subtitol.

    Potser extendre això a múltiples rows per factors variants (n o alpha i beta).

    ## A nivell global, múltiples simulacions com a comparació dels dos mètodes

    1. Veure Figura 1 del paper de simulation studies, corbes de bias, empse i
    mse com a funció del sample size per cadascun dels mètodes.
"""


if __name__ == "__main__":
    seed = 1234
    # Create a single generator to share in all distribution objects
    rng = np.random.default_rng(seed)

    alpha_vals = [2.0, 10.0, 50.0]
    beta_vals = [0.8, 1.0, 3.0]
    sample_grid = {}

    for alpha in alpha_vals:
        for beta in beta_vals:
            sample_grid[(alpha, beta)] = WeibullDistribution(
                alpha=alpha, beta=beta, rng=rng
            ).sample(10)

    plot_grid_weibull(sample_grid, save_plot=True)


    for alpha in alpha_vals:
        for beta in beta_vals:
            sample_grid[(alpha, beta)] = WeibullDistribution(
                alpha=alpha, beta=beta, rng=rng
            ).sample(50)

    plot_grid_weibull(sample_grid, save_plot=True)

    for alpha in alpha_vals:
        for beta in beta_vals:
            sample_grid[(alpha, beta)] = WeibullDistribution(
                alpha=alpha, beta=beta, rng=rng
            ).sample(200)

    plot_grid_weibull(sample_grid, save_plot=True)
