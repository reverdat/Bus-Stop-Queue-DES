"""
## main.py

This module orchestrates our code to
generate the results presented in our report,
guaranteeing true reproducibility of
data and figures.
"""
from typing import List, Any
from dataclasses import asdict
import os
from pprint import pprint

import numpy as np
import pandas as pd

from simulation import SimulationComparison, ParameterEstimate

# Check if results folder exists 
os.makedirs("../results", exist_ok=True)

def main():
    seed = 1234
    rng = np.random.default_rng(seed)

    n_sims = 1000
    # n_sims = 115
    alphas = [1.0, 2.0, 3.0]
    betas = [0.5, 1.0, 3.0]
    sample_sizes = [10, 50, 200]

    scenarios = [(a, b) for a in alphas for b in betas]

    final_tables = {}


    ###### I. SIMULATION

    for alpha, beta in scenarios:
        scenario_summary_data = []
        scenario_raw_estimates = []

        for n in sample_sizes:
            print(f"Alpha={alpha} Beta={beta} sample={n}")
            sim_output = SimulationComparison(
                alpha=alpha,
                beta=beta,
                n=n,
                estimation_methods=[
                    ("mrr", "beta"),
                    ("mrr", "bernard"),
                    ("mle", "scipy"),
                ],
                n_sim=n_sims,
                rng=rng,
            ).simulate()

            if isinstance(sim_output, tuple):
                sim_results_all_methods = sim_output[0]
            else:
                sim_results_all_methods = [sim_output]

            for sim_result in sim_results_all_methods:
                method_name = f"{sim_result.method[0].upper()} ({sim_result.method[1]})"

                df_est = pd.DataFrame(
                    {
                        "sim_id": range(1, n_sims + 1),
                        "n": n,
                        "method_full": method_name,
                        "alpha_hat": sim_result.alpha.estimates,
                        "beta_hat": sim_result.beta.estimates,
                    }
                )
                scenario_raw_estimates.append(df_est)

                for param in ["alpha", "beta"]:
                    value = getattr(sim_result, param)
                    param_dict = asdict(value)

                    del param_dict["estimates"]

                    row = {
                        "method_full": method_name,
                        "n": n,
                        "parameter": param,
                        **param_dict,
                    }
                    scenario_summary_data.append(row)

        df_scenario = pd.DataFrame(scenario_summary_data)

        # Pivot: Rows=N, Cols=Parameter -> Method -> Metric
        pivot_table = df_scenario.pivot_table(
            index="n",
            columns=["parameter", "method_full"],
            values=["bias", "empse", "mse", "bias_mcse", "empse_mcse", "mse_mcse"],
        )

        # Reorder levels to: Parameter -> Method -> Metric
        pivot_table.columns = pivot_table.columns.reorder_levels([1, 2, 0])
        pivot_table = pivot_table.sort_index(axis=1, level=[0, 1])

        key_name = f"A{alpha}_B{beta}".replace(".", "")
        final_tables[key_name] = pivot_table

        pivot_table.to_csv(f"../results/summary-alpha{alpha}-beta{beta}.csv",float_format='%.2e')
        print(f"Saved summary for A={alpha}, B={beta}")

        df_estimates_final = pd.concat(scenario_raw_estimates, ignore_index=True)

        df_estimates_final.to_csv(
            f"../results/estimates-alpha{alpha}-beta{beta}.csv", index=False, float_format='%.2e',
        )
        print(f"Saved estimates for A={alpha}, B={beta}")


    ## II. PLOTTING RESULTS

    





if __name__ == "__main__":
    main()
