"""
## main.py

This module orchestrates our code to 
generate the results presented in our report,
guaranteeing true reproducibility of  
data and figures.
"""

import numpy as np
from simulation import SimulationComparison
import pandas as pd
from typing import List, Any

def save_simulation_results(
    all_data: List[tuple], 
    filename_metrics="simulation_metrics.csv", 
    filename_comparisons="simulation_comparisons.csv"
):
    """
    Parses a list of (sim_params, sim_output) and saves to CSVs.
    """
    metrics_records = []
    comparison_records = []

    for params, output in all_data:
        # Unpack simulation parameters
        sim_alpha, sim_beta, n = params

        # Normalization: Handle the different return types of .simulate()
        sim_results = []
        comp_metrics = None

        if hasattr(output, 'id'): 
            # Case 1: Single Estimation Method (Returns just SimulationResult)
            sim_results = [output]
        elif isinstance(output, tuple):
            # Case 2: Multiple Methods (Returns (List[SimulationResult], ComparisonMetrics))
            sim_results, comp_metrics = output
        else:
            print(f"Warning: Unknown output type for params {params}")
            continue

        # --- 1. Process Absolute Metrics (Bias, MSE, etc.) ---
        for res in sim_results:
            method_name, method_algo = res.method
            
            # Extract Alpha and Beta estimates
            for param_name in ['alpha', 'beta']:
                est = getattr(res, param_name) # Get the ParameterEstimate object
                
                metrics_records.append({
                    'sim_alpha': sim_alpha,
                    'sim_beta': sim_beta,
                    'n': n,
                    'method_type': method_name,
                    'method_algo': method_algo,
                    'parameter': param_name,
                    'bias': est.bias,
                    'bias_mcse': est.bias_mcse,
                    'empse': est.empse,
                    'empse_mcse': est.empse_mcse,
                    'mse': est.mse,
                    'mse_mcse': est.mse_mcse
                })

        # --- 2. Process Comparison Metrics (Rel Increase) ---
        if comp_metrics:
            # comp_metrics is a list of tuples: [(alpha_metrics), (beta_metrics)]
            # It compares sim_results[0] vs sim_results[1]
            base_method = f"{sim_results[0].method[0]}_{sim_results[0].method[1]}"
            comp_method = f"{sim_results[1].method[0]}_{sim_results[1].method[1]}"
            
            # Alpha Comparison (Index 0)
            comparison_records.append({
                'sim_alpha': sim_alpha, 'sim_beta': sim_beta, 'n': n,
                'parameter': 'alpha',
                'baseline': base_method, 'comparison': comp_method,
                'rel_increase': comp_metrics[0][0],
                'mcse_rel': comp_metrics[0][1]
            })
            
            # Beta Comparison (Index 1)
            comparison_records.append({
                'sim_alpha': sim_alpha, 'sim_beta': sim_beta, 'n': n,
                'parameter': 'beta',
                'baseline': base_method, 'comparison': comp_method,
                'rel_increase': comp_metrics[1][0],
                'mcse_rel': comp_metrics[1][1]
            })

    # Save to CSV
    df_metrics = pd.DataFrame(metrics_records)
    df_metrics.to_csv(filename_metrics, index=False)
    print(f"Saved metrics to {filename_metrics}")

    if comparison_records:
        df_comp = pd.DataFrame(comparison_records)
        df_comp.to_csv(filename_comparisons, index=False)
        print(f"Saved comparisons to {filename_comparisons}")

# això ja està fet per mi
def main():
    seed = 1234
    rng = np.random.default_rng(seed)

    n_sims = 1000
    alphas = [1.0, 2.0, 3.0]
    betas = [1.5, 2.0, 2.5]
    sample_sizes = [10, 50, 100]

    all_simulation_data = []

    for (alpha, beta, n) in [(a,b,n) for a in alphas for b in betas for n in sample_sizes]:
        print(f"Testing alpha={alpha}, beta={beta}, n={n}...")
        
        sim_output = SimulationComparison(
            alpha=alpha, 
            beta=beta, 
            n=n, 
            estimation_methods=[("mrr", "beta"), ("mrr", "bernard"), ("mle", "scipy")], 
            n_sim=1000, #ULL HO HE POSAT MÉS BAIX PER PROVAR 
            rng=rng
        ).simulate()
        
        all_simulation_data.append(((alpha, beta, n), sim_output))

    save_simulation_results(all_simulation_data)

if __name__ == "__main__":
    main()


