"""
## plotting.py

This module contains all functions
which generate Matplotlib figures
given a sample
"""

from typing import Optional, Tuple, Dict, List

import os

import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
import matplotlib.ticker as ticker

import seaborn as sns
import numpy as np
import pandas as pd

from dgm import WeibullDistribution
from inference import ImplementedEstimationMethods
from utils import PROJECT_ROOT

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
            f"{PROJECT_ROOT}/plots/weibull_{params['alpha']}_{params['beta']}.png",
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
        3.0: "Wear-Out\n(β > 1)",
    }

    for i, (params, sample) in enumerate(sample_grid.items()):
        plot_histogram_weibull(
            sample,
            params={"alpha": params[0], "beta": params[1]},
            ax=axs[i],
            save_plot=False,
        )

    beta_vals = sorted(set(beta for alpha, beta in sample_grid.keys()))
    for col, beta in enumerate(beta_vals):
        fig.text(
            (col + 0.56) / 3,
            0.88,
            beta_interpretations[beta],
            ha="center",
            va="bottom",
            fontsize=12,
            fontweight="bold",
        )

    plt.suptitle("Weibull Distribution Samples", fontsize=20, y=0.98)
    plt.figtext(0.48, 0.94, f"n = {sample_size}", fontsize=18, style="italic")
    plt.tight_layout(rect=[0, 0, 1, 0.92])

    if save_plot:
        plt.savefig(f"{PROJECT_ROOT}/plots/weibull_grid_{sample_size}.png", dpi=500, bbox_inches="tight")
        plt.close(fig)
    else:
        plt.show()


def plot_estimates_method(
    alpha: np.float64, beta: np.float64, method: str, results_dir: str = "./results"
):
    est_file = os.path.join(results_dir, f"estimates-alpha{alpha}-beta{beta}.csv")
    sum_file = os.path.join(results_dir, f"summary-alpha{alpha}-beta{beta}.csv")

    df_est = pd.read_csv(est_file)
    df_est_method = df_est[
        df_est["method_full"].str.contains(method, case=False, regex=False)
    ]

    full_method_name = df_est_method["method_full"].iloc[0]

    df_sum = pd.read_csv(sum_file, header=[0, 1, 2], index_col=0)
    sample_sizes = sorted(df_est_method["n"].unique())
    n_rows = len(sample_sizes)

    max_radius = 0
    for n in sample_sizes:
        # Distance = Bias + Half-Width of CI
        subset_est = df_est_method[df_est_method["n"] == n]

        mean_a = subset_est["alpha_hat"].mean()
        se_a = df_sum["alpha"][full_method_name]["empse"].loc[n]

        extent_a = abs(mean_a - alpha) + (1.96 * se_a)

        mean_b = subset_est["beta_hat"].mean()
        se_b = df_sum["beta"][full_method_name]["empse"].loc[n]

        extent_b = abs(mean_b - beta) + (1.96 * se_b)

        max_radius = max(max_radius, extent_a, extent_b)

    max_radius = max_radius * 1.1

    fig, axs = plt.subplots(
        nrows=n_rows,
        ncols=2,
        figsize=(12, 1.2 * n_rows),
        sharex=False,  # We set limits manually
    )

    fig.subplots_adjust(
        top=0.85, bottom=0.25, left=0.10, right=0.95, hspace=0.6, wspace=0.1
    )

    color_true = "red"
    color_estimate = "black"

    for i, n in enumerate(sample_sizes):
        row_axs = axs if n_rows == 1 else axs[i]
        subset_est = df_est_method[df_est_method["n"] == n]

        def plot_param_on_axis(ax, param_name, true_val):
            mean_val = subset_est[f"{param_name}_hat"].mean()
            empse_val = df_sum[param_name][full_method_name]["empse"].loc[n]

            # 1. Plot Truth
            ax.axvline(
                true_val,
                color=color_true,
                linestyle="--",
                linewidth=2,
                alpha=0.8,
                zorder=1,
            )

            ax.errorbar(
                x=mean_val,
                y=0,
                xerr=1.96 * empse_val,
                fmt="o",
                color=color_estimate,
                ecolor=color_estimate,
                capsize=6,
                capthick=1.5,
                elinewidth=1.5,
                markersize=6,
                zorder=2,
            )

            ax.set_xlim(true_val - max_radius, true_val + max_radius)

            ax.xaxis.set_major_locator(ticker.MaxNLocator(nbins=5))

            ax.set_ylim(-1, 1)
            ax.set_yticks([])
            ax.spines["left"].set_visible(False)
            ax.spines["right"].set_visible(False)
            ax.spines["top"].set_visible(False)
            ax.spines["bottom"].set_visible(True)
            ax.spines["bottom"].set_color("black")
            ax.spines["bottom"].set_linewidth(1.2)
            ax.tick_params(
                axis="x", direction="out", length=5, width=1.2, colors="black"
            )

            return ax

        ax_a = row_axs[0]
        plot_param_on_axis(ax_a, "alpha", alpha)
        ax_a.text(
            -0.02,
            0,
            f"n = {n}",
            transform=ax_a.transAxes,
            fontsize=14,
            style="italic",
            ha="right",
            va="center",
            color="black",
        )

        if i == 0:
            ax_a.set_title(f"α = {alpha}", fontsize=14, pad=15)

        ax_b = row_axs[1]
        plot_param_on_axis(ax_b, "beta", beta)

        if i == 0:
            ax_b.set_title(f"β = {beta}", fontsize=14, pad=15)

    fig.suptitle(
        "Weibull Simulation Inference Results", fontsize=18, fontweight="bold", y=1.12
    )
    fig.text(
        0.5,
        1.0,
        f"Method: {full_method_name}, n_sim = 1000",
        fontsize=14,
        style="italic",
        ha="center",
    )

    legend_elements = [
        Line2D(
            [0], [0], color=color_true, linestyle="--", linewidth=2, label="True Value"
        ),
        Line2D(
            [0],
            [0],
            color=color_estimate,
            marker=".",
            linestyle="-",
            linewidth=2,
            markersize=12,
            markeredgewidth=2,
            label="Mean ± 1.96 EmpSE (95% CI)",
        ),
    ]

    fig.legend(
        handles=legend_elements,
        loc="lower center",
        bbox_to_anchor=(0.5, 0.05),
        ncol=2,
        frameon=False,
        fontsize=14,
    )

    filename = f"{PROJECT_ROOT}/plots/estimates-plot-alpha{alpha}-beta{beta}-{method}.png"
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    print(f"Plot saved to {filename}")
    plt.close(fig)

def plot_2d_density(
    alpha: float,
    beta: float,
    methods: List[str],
    results_dir: str = ".",
    output_dir: str = "."
):
    """
    Creates a grid of 2D Density plots (Kernel Density Estimation).
    Rows: Sample Sizes (n)
    Cols: Methods
    Axes are fixed across all subplots for direct comparison of convergence.
    """
    # 1. Load Data
    filename = f"estimates-alpha{alpha}-beta{beta}.csv"
    path = os.path.join(results_dir, filename)
    
    if not os.path.exists(path):
        print(f"Estimates file not found: {path}")
        return
        
    df = pd.read_csv(path)
    
    # 2. Filter Methods and Map Names
    available_methods = df['method_full'].unique()
    selected_methods = []
    
    # Preserve order of user's 'methods' list
    for user_method in methods:
        match = next((m for m in available_methods if user_method.lower() in m.lower()), None)
        if match and match not in selected_methods:
            selected_methods.append(match)
            
    if not selected_methods:
        print(f"No matching methods found in {filename}")
        return

    # Filter DataFrame
    df = df[df['method_full'].isin(selected_methods)]
    sample_sizes = sorted(df['n'].unique())

    # 3. Calculate Global Axis Limits (Robust to outliers)
    # We use 0.5% and 99.5% quantiles to define the view area, 
    # preventing one extreme simulation from making the rest look tiny.
    x_min, x_max = df['alpha_hat'].quantile([0.005, 0.995])
    y_min, y_max = df['beta_hat'].quantile([0.005, 0.995])
    
    # Add a 10% breathing room
    x_pad = (x_max - x_min) * 0.1
    y_pad = (y_max - y_min) * 0.1
    
    xlim = (x_min - x_pad, x_max + x_pad)
    ylim = (y_min - y_pad, y_max + y_pad)

    # 4. Create Grid
    n_rows = len(sample_sizes)
    n_cols = len(selected_methods)
    
    # squeeze=False ensures axs is always a 2D array [row][col]
    fig, axs = plt.subplots(
        nrows=n_rows, 
        ncols=n_cols, 
        figsize=(4 * n_cols, 3.5 * n_rows),
        sharex=True, 
        sharey=True,
        squeeze=False 
    )

    # 5. Plotting Loop
    for r, n in enumerate(sample_sizes):
        for c, method in enumerate(selected_methods):
            ax = axs[r][c]
            
            # Subset data
            data = df[(df['n'] == n) & (df['method_full'] == method)]
            
            if data.empty:
                ax.text(0.5, 0.5, "No Data", ha='center', va='center')
                continue

            # Density Plot (KDE)
            # fill=True creates the shaded contour
            sns.kdeplot(
                x=data['alpha_hat'], 
                y=data['beta_hat'], 
                ax=ax, 
                fill=True, 
                cmap="Blues", 
                thresh=0.05, # Lowest iso-proportion level at which to draw a contour
            )
            
            # Mark the True Value
            ax.axvline(alpha, color="red", linestyle="--", linewidth=1.5, alpha=0.6)
            ax.axhline(beta, color="red", linestyle="--", linewidth=1.5, alpha=0.6)
            ax.plot(alpha, beta, 'ro', markersize=5, markeredgecolor="Black", zorder = 10, markeredgewidth=1.0, label='True Value')
            
            # Enforce Global Limits
            ax.set_xlim(xlim)
            ax.set_ylim(ylim)
            
            # Titles and Labels
            if r == 0:
                ax.set_title(method, fontsize=14, fontweight='bold', pad=10)
            
            if c == 0:
                ax.set_ylabel(f"n = {n}\n\nEstimated $\\beta$", fontsize=12)
            else:
                ax.set_ylabel("")
                
            if r == n_rows - 1:
                ax.set_xlabel("Estimated $\\alpha$", fontsize=12)
            else:
                ax.set_xlabel("")

            # Grid
            ax.grid(True, linestyle=':', alpha=0.6)

    # Global Title
    fig.suptitle(f"Joint Density of Estimates ($\\alpha$={alpha}, $\\beta$={beta})", fontsize=20, y=1.02)
    
    # Legend (only need one for the red star)
    # We grab the handle from the first plot
    handles, labels = axs[0][0].get_legend_handles_labels()
    # Filter to only keep 'True Value'
    by_label = dict(zip(labels, handles))
    if 'True Value' in by_label:
        fig.legend([by_label['True Value']], ['True Value'], loc='upper right', bbox_to_anchor=(0.95, 1.02), frameon=False)

    # Save
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    filename = f"density_comparison_alpha{alpha}_beta{beta}.png"
    filepath = os.path.join(output_dir, filename)
    plt.savefig(filepath, dpi=300, bbox_inches="tight")
    print(f"Plot saved to {filepath}")
    plt.close(fig)

def plot_2d_density_old(
    alpha: np.float64,
    beta: np.float64,
    methods: List[ImplementedEstimationMethods],
    results_dir: str = "./results",
):
    est_file = os.path.join(results_dir, f"estimates-alpha{alpha}-beta{beta}.csv")
    df_est = pd.read_csv(est_file)

    sample_sizes = sorted(df_est["n"].unique())

    n_rows = len(sample_sizes)
    n_cols = len(methods)

    fig, axs = plt.subplots(
        nrows=n_rows,
        ncols=n_cols,
        figsize=(4 * n_cols, 3.5 * n_rows),
        sharex="col",
        sharey="row",
    )

    fig.subplots_adjust(
        top=0.90, bottom=0.10, left=0.10, right=0.95, hspace=0.2, wspace=0.1
    )

    c_true = "red"

    if n_rows == 1 and n_cols == 1:
        axs = np.array([[axs]])
    elif n_rows == 1:
        axs = axs[np.newaxis, :]
    elif n_cols == 1:
        axs = axs[:, np.newaxis]

    for i, n in enumerate(sample_sizes):
        for j, method_query in enumerate(methods):
            ax = axs[i, j]

            subset = df_est[
                (df_est["n"] == n)
                & (
                    df_est["method_full"].str.contains(
                        method_query, case=False, regex=False
                    )
                )
            ]

            if subset.empty:
                ax.text(0.5, 0.5, "No Data", ha="center", transform=ax.transAxes)
                continue

            method_display = subset["method_full"].iloc[0]

            x = subset["alpha_hat"]
            y = subset["beta_hat"]

            # A. Plot Density
            sns.kdeplot(
                x=x,
                y=y,
                ax=ax,
                fill=True,
                cmap="Greys",
                thresh=0.05,
                levels=10,
                alpha=0.9,
            )

            ax.axvline(alpha, color=c_true, linestyle="--", linewidth=1.5, alpha=0.6)
            ax.axhline(beta, color=c_true, linestyle="--", linewidth=1.5, alpha=0.6)
            ax.plot(
                alpha,
                beta,
                ".",
                color=c_true,
                markersize=12,
                markeredgecolor="white",
                markeredgewidth=1.5,
                zorder=10,
            )

            if j == 0:
                ax.set_ylabel(r"$\hat{\beta}$", fontsize=12)
                ax.text(
                    -0.27,
                    0.5,
                    f"n = {n}",
                    transform=ax.transAxes,
                    fontsize=14,
                    style="italic",
                    va="center",
                    ha="center",
                    rotation=90,
                )
            else:
                ax.set_ylabel("")

            if i == 0:
                ax.set_title(method_display, fontsize=14, fontweight="bold", pad=15)

            if i == n_rows - 1:
                ax.set_xlabel(r"$\hat{\alpha}$", fontsize=12)
            else:
                ax.set_xlabel("")

            ax.spines["top"].set_visible(False)
            ax.spines["right"].set_visible(False)

    fig.suptitle(
        "Joint Distribution of Estimates", fontsize=18, fontweight="bold", y=1.0
    )
    fig.text(
        0.5,
        0.96,
        f"(α={alpha}, β={beta}), n_sim = 1000",
        fontsize=14,
        style="italic",
        ha="center",
    )

    legend_elements = [
        Line2D(
            [0],
            [0],
            color=c_true,
            linestyle="--",
            marker=".",
            markersize=12,
            label="True (α, β)",
        )
    ]
    fig.legend(
        handles=legend_elements,
        loc="lower center",
        bbox_to_anchor=(0.5, 0.02),
        frameon=False,
        fontsize=12,
    )

    filename = f"{PROJECT_ROOT}/plots/density2d-grid-alpha{alpha}-beta{beta}.png"
    plt.savefig(filename, dpi=300, bbox_inches="tight")
    print(f"Plot saved to {filename}")
    plt.close(fig)



def plot_metrics_comparison(
    alpha: float,
    beta: float,
    methods: List[str],
    param_name: str = "beta",
    results_dir: str = ".",
    save_plot: bool = True,
):
    """
    Plots Bias, Empirical SE, and Root MSE for a specific parameter (alpha or beta)
    across different sample sizes for the specified methods.
    """
    # 1. Construct the filename
    sum_file = os.path.join(results_dir, f"summary-alpha{alpha}-beta{beta}.csv")
    
    if not os.path.exists(sum_file):
        print(f"Error: Summary file not found at {sum_file}")
        return

    # 2. Read the CSV with a 3-level header (Parameter, Method, Metric)
    try:
        df = pd.read_csv(sum_file, header=[0, 1, 2], index_col=0)
    except Exception as e:
        print(f"Error reading CSV: {e}")
        return

    # 3. Select the data for the requested parameter
    if param_name not in df.columns.levels[0]:
        print(f"Parameter '{param_name}' not found in file.")
        return
    
    sub_df = df[param_name]

    # 4. Map user-provided method strings to actual column names
    available_methods = sub_df.columns.get_level_values(0).unique()
    selected_map = {}
    
    for user_method in methods:
        match = next((m for m in available_methods if user_method.lower() in m.lower()), None)
        if match:
            selected_map[user_method] = match
        else:
            print(f"Warning: Method '{user_method}' not found in data.")

    if not selected_map:
        print("No valid methods found to plot.")
        return

    # 5. Setup the Plot
    fig, axs = plt.subplots(nrows=1, ncols=3, figsize=(18, 5))
    fig.subplots_adjust(wspace=0.3)
    
    metrics_config = [
        ("bias", "Bias"),
        ("empse", "Empirical SE"),
        ("mse", "MSE"),
    ]

    # CHANGED: Use a high-contrast palette (Set1) to distinguish similar methods
    colors = sns.color_palette("Set1", n_colors=len(selected_map))
    # Line styles cycle for extra distinction
    line_styles = ["-", "--", "-.", ":"]

    # 6. Plotting Loop
    for col_idx, (metric_key, metric_title) in enumerate(metrics_config):
        ax = axs[col_idx]
        
        for i, (user_label, full_method) in enumerate(selected_map.items()):
            try:
                # CHANGED: Explicit calculation for RMSE from 'mse' column
                if metric_key == "mse":
                    if 'mse' in sub_df[full_method]:
                        data = sub_df[full_method]['mse']
                    else:
                        print(f"MSE column missing for {full_method}")
                        continue
                else:
                    data = sub_df[full_method][metric_key]
                
                # CHANGED: Added marker='o' to draw points at the sample sizes
                ax.plot(
                    data.index, 
                    data.values, 
                    label=user_label, 
                    color=colors[i], 
                    linewidth=2.5,
                    linestyle=line_styles[i % len(line_styles)],
                    marker='o',      # Draws the point
                    markersize=8
                )
            except KeyError as e:
                print(f"Data missing for {full_method} - {metric_key}: {e}")
                continue

        # Styling
        ax.set_title(metric_title, fontsize=18, pad=15)
        ax.set_xlabel(r"$n_{obs}$", fontsize=14)
        
        # Clean spines
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.spines['left'].set_visible(False)
        ax.spines['bottom'].set_color('grey')
        
        # Grid and Ticks
        ax.grid(axis='y', color='lightgrey', linestyle='-', linewidth=0.5)
        ax.tick_params(axis='y', length=0)
        ax.tick_params(axis='x', colors='grey')
        
        # Specific Adjustments
        if metric_key == "bias":
            ax.axhline(0, color='black', linewidth=1, alpha=0.3)
        else:
            ax.set_ylim(bottom=0)

    # 7. Legend
    handles, labels = axs[0].get_legend_handles_labels()
    fig.legend(
        handles, 
        labels, 
        loc='lower center', 
        bbox_to_anchor=(0.5, -0.1), 
        ncol=len(selected_map), 
        frameon=False, 
        fontsize=14
    )
    
    fig.suptitle(
        f"Performance Metrics for {param_name} ($\\alpha$={alpha}, $\\beta$={beta})", 
        fontsize=20, 
        y=1.05
    )

    if save_plot:
        filename = f"{PROJECT_ROOT}/plots/metrics_comparison_alpha{alpha}_beta{beta}_{param_name}.png"
        plt.savefig(filename, dpi=300, bbox_inches="tight")
        print(f"Plot saved to {filename}")
        plt.close(fig)
    else:
        plt.show()

if __name__ == "__main__":
    plot_metrics_comparison(
        alpha=1.0, 
        beta=1.0, 
        methods=["MLE (scipy)", "MRR (beta)", "MRR (bernard)"], 
        param_name="beta",
        results_dir="./results"
    )
    plot_estimates_method(1.0, 1.0, "MLE (scipy)")
    plot_2d_density(1.0, 1.0, ["MLE (scipy)", "MRR (beta)", "MRR (bernard)"])
