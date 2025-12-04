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
from pathlib import Path
from pprint import pprint

import numpy as np
import pandas as pd
from utils import REPO_ROOT, PROJECT_ROOT

from simulation import SimulationComparison, ParameterEstimate
import re

from plotting import plot_metrics_comparison, plot_2d_density, plot_estimates_method

PROJECT_ROOT = f"{REPO_ROOT}/assigment1"

# Check if results folder exists
os.makedirs(f"{PROJECT_ROOT}/results", exist_ok=True)
os.makedirs(f"{PROJECT_ROOT}/plots", exist_ok=True)


def main():
    seed = 1234
    rng = np.random.default_rng(seed)

    n_sims = 1000
    # n_sims = 115
    alphas = [1.0, 2.0, 3.0]
    betas = [0.5, 1.0, 3.0]
    sample_sizes = [10, 50, 200]

    run_simulation(alphas, betas, sample_sizes, n_sims, rng)
    generate_results_plots(f"{PROJECT_ROOT}/results")
    ## II. PLOTTING RESULTS


def generate_results_plots(results_dir: str):
    """
    Scans the results directory for summary files and generates all available
    plots for every alpha/beta configuration found.
    """

    # Regex to identify summary files and extract parameters
    pattern = re.compile(r"summary-alpha([\d\.]+)-beta([\d\.]+)\.csv")

    files = [f for f in os.listdir(results_dir) if pattern.match(f)]

    if not files:
        print(f"No summary files found in {results_dir}")
        return

    print(f"Found {len(files)} configurations. Generating plots...")

    for filename in files:
        match = pattern.match(filename)
        alpha_val = float(match.group(1))
        beta_val = float(match.group(2))

        full_path = os.path.join(results_dir, filename)

        # 1. Detect Methods from the CSV header
        try:
            # Read just the header to get method names
            df_head = pd.read_csv(full_path, header=[0, 1, 2], nrows=0)
            # Level 1 contains method names (e.g., 'MLE (scipy)', 'MRR (beta)')
            methods_in_file = list(df_head.columns.levels[1].unique())
        except Exception as e:
            print(f"Skipping {filename}: {e}")
            continue

        print(
            f"Processing alpha={alpha_val}, beta={beta_val} | Methods: {methods_in_file}"
        )

        # --- Plot Type 1: Metrics Comparison (Bias, SE, RMSE) ---
        # Plot for Alpha
        plot_metrics_comparison(
            alpha=alpha_val,
            beta=beta_val,
            methods=methods_in_file,
            param_name="alpha",
            results_dir=results_dir,
        )
        # Plot for Beta
        plot_metrics_comparison(
            alpha=alpha_val,
            beta=beta_val,
            methods=methods_in_file,
            param_name="beta",
            results_dir=results_dir,
        )

        # --- Plot Type 2: 2D Joint Density ---
        # Note: This function uses its own hardcoded path inside plotting.py
        # (usually {PROJECT_ROOT}/plots/...), so we just pass results_dir.
        try:
            plot_2d_density(
                alpha=alpha_val,
                beta=beta_val,
                methods=methods_in_file,
                results_dir=results_dir,
            )
        except Exception as e:
            print(f"Failed 2D density plot: {e}")

        # --- Plot Type 3: Estimates & CI Coverage per Method ---
        # This needs to be called individually for each method.
        for method in methods_in_file:
            try:
                plot_estimates_method(
                    alpha=alpha_val,
                    beta=beta_val,
                    method=method,
                    results_dir=results_dir,
                )
            except Exception as e:
                print(f"Failed estimates plot for {method}: {e}")

    print("All plots generated successfully.")


def run_simulation(alphas, betas, n_sims, sample_sizes, rng):
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

        pivot_table.to_csv(
            f"../results/summary-alpha{alpha}-beta{beta}.csv", float_format="%.2e"
        )
        print(f"Saved summary for A={alpha}, B={beta}")

        df_estimates_final = pd.concat(scenario_raw_estimates, ignore_index=True)

        df_estimates_final.to_csv(
            f"../results/estimates-alpha{alpha}-beta{beta}.csv",
            index=False,
            float_format="%.2e",
        )
        print(f"Saved estimates for A={alpha}, B={beta}")


if __name__ == "__main__":
    main()
