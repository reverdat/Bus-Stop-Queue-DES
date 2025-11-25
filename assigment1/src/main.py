"""
main.py

Runs the whole study in order to pick the best 
alpha and beta values for our use case
"""
import numpy as np
from simulation import SimulationComparison, ParameterEstimate
import pandas as pd
from typing import List, Any

from dataclasses import asdict
from pprint import pprint

def main():
    seed = 1234
    rng = np.random.default_rng(seed)
    
    n_sims = 2  # Set to 1000 for final run [cite: 20]
    alphas = [1.0, 2.0, 3.0]
    betas = [1.5, 2.0, 2.5]
    sample_sizes = [10, 50, 100]
    
    scenarios = [(a, b) for a in alphas for b in betas]

    final_tables = {}

    for alpha, beta in scenarios:
        
        scenario_data = []
        
        for n in sample_sizes:
            print(f"Alpha={alpha} Beta={beta} sample={n}")
            sim_output = SimulationComparison(
                alpha=alpha, 
                beta=beta, 
                n=n, 
                estimation_methods=[("mrr", "beta"), ("mrr", "bernard"), ("mle", "scipy")], 
                n_sim=n_sims, 
                rng=rng
            ).simulate()
            
            sim_results_all_methods, _ = sim_output
            
            for sim_result in sim_results_all_methods:
                for param in ["alpha", "beta"]:
                    value = getattr(sim_result, param)
                    param_dict = asdict(value)
                    
                    del param_dict["estimates"]
                    
                    row = {
                        'method_full': f"{sim_result.method[0].upper()} ({sim_result.method[1]})",
                        'n': n,
                        'parameter': param, 
                        **param_dict 
                    }
                    scenario_data.append(row)
        
        df_scenario = pd.DataFrame(scenario_data)
        
        # Pivot: Rows=N, Cols=Parameter -> Metric -> Method
        pivot_table = df_scenario.pivot_table(
            index='n',
            columns=['parameter', 'method_full'],
            values=['bias', 'mse', 'empse_mcse'] # Add the metrics you want to see
        )
        
        pivot_table.columns = pivot_table.columns.swaplevel(0, 1) 
        pivot_table.sort_index(axis=1, level=0, inplace=True)
        
        key_name = f"A{alpha}_B{beta}".replace(".", "")
        final_tables[key_name] = pivot_table
        print(pivot_table)
        
        print("Written to results!")
        pivot_table.to_csv(f"./results/sim-alpha{alpha}-beta{beta}.csv")
        
    

if __name__ == "__main__":
    main()


