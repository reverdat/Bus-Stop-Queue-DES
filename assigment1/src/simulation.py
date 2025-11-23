"""
## simulation.py

This module implements the `SimulationComparison` class,
our high level abstraction to simulate a predefined
number of times our data-generating process, and for each fix sample
compare the difference estimation methods
"""

from typing import Literal, Tuple, List, Optional

from dataclasses import dataclass
import numpy as np

from dgm import WeibullDistribution
from inference import EstimationMethod, estimation_method_dispatcher


@dataclass
class ParameterEstimate:
    name: Literal["alpha", "beta"]
    theta: np.float64
    estimates: np.array
    bias: np.float64
    bias_mcse: np.float64
    empse: np.float64
    empse_mcse: np.float64
    mse: np.float64
    mse_mcse: np.float64


@dataclass
class SimulationResult:
    id: int
    method: EstimationMethod
    alpha: ParameterEstimate
    beta: ParameterEstimate


class SimulationComparison:
    def __init__(
        self, alpha, beta, n, estimation_methods: List[EstimationMethod], n_sim, rng
    ):
        self.alpha = alpha
        self.beta = beta
        self.n = n

        self.estimation_methods = estimation_methods
        self.n_sim = n_sim
        self.rng = rng

        self.weibull = WeibullDistribution(self.alpha, self.beta, self.rng)

    def _generate_sample(self) -> np.array:
        return self.weibull.sample(self.n)

    def _compute_performance_measures(
        self, name: str, theta: np.float64, estimates: np.array
    ) -> ParameterEstimate:
        bias = np.sum(estimates - theta) / self.n_sim
        theta_bar = np.sum(estimates) / self.n_sim
        bias_mcse = np.sqrt(
            np.sum(np.pow(estimates - theta_bar, 2)) / (self.n_sim * (self.n_sim - 1))
        )
        empse = np.sqrt(np.sum(np.pow(estimates - theta_bar, 2)) / (self.n_sim - 1))
        empse_mcse = empse / np.sqrt(2 * (self.n_sim - 1))
        mse = np.sum(np.pow(estimates - theta, 2)) / self.n_sim
        mse_mcse = np.sqrt(
            np.sum(np.power(np.power(estimates - theta, 2) - mse, 2))
            / (self.n_sim * (self.n_sim - 1))
        )
        return ParameterEstimate(
            name=name,
            theta=theta,
            estimates=estimates,
            bias=bias,
            bias_mcse=bias_mcse,
            empse=empse,
            empse_mcse=empse_mcse,
            mse=mse,
            mse_mcse=mse_mcse,
        )

    def simulate(
        self,
    ) -> SimulationResult | Tuple[List[SimulationResult], List[Tuple[np.float64]]]:
        """
        Execute the simulation study for the provided parameters. Generates
        a sample of size `n` for a `n_sim` number of times, and performs
        Weibull inference using each of the provided `estimation_methods`,
        resulting in point estimates alongside performance metrics and
        their MCSE.

        Returns
        -------

        `SimulationResult | Tuple[List[SimulationResult], List[Tuple[np.float64]]]`:
            If a single estimation method is used, returns a single `SimulationResult`
            object. Otherwise, returns a list with each `SimulationResult`
            alongside the Relative Increase metric with the MCSE.

        """

        sim_results: List[SimulationResult] = []
        samples: List[np.array] = [self._generate_sample() for _ in range(self.n_sim)]
        for i, estimation_method in enumerate(self.estimation_methods):
            alpha_estimates: List[np.float64] = []
            beta_estimates: List[np.float64] = []
            estimation_func = estimation_method_dispatcher(
                estimation_method=estimation_method
            )
            for sample in samples:
                alpha, beta = estimation_func(sample)
                alpha_estimates.append(alpha)
                beta_estimates.append(beta)

            alpha_estimates = np.asarray(alpha_estimates)
            beta_estimates = np.asarray(beta_estimates)

            alpha_results = self._compute_performance_measures(
                name="alpha", theta=self.alpha, estimates=alpha_estimates
            )
            beta_results = self._compute_performance_measures(
                name="beta", theta=self.beta, estimates=beta_estimates
            )
            sim_results.append(
                SimulationResult(
                    id=i+1,
                    method=estimation_method,
                    alpha=alpha_results,
                    beta=beta_results,
                )
            )
        if len(sim_results) == 1:
            return sim_results[0]
        else:  # If more than one estimation method is used, compute relative increase
            res_A = sim_results[0]  # Baseline (e.g. MLE)
            res_B = sim_results[1]  # Comparison method (e.g. MRR)

            comparison_metrics = []

            for _ in ["alpha", "beta"]:
                ests_A = res_A.param.estimates
                ests_B = res_B.param.estimates
                empse_A = res_A.param.empse
                empse_B = res_B.param.empse

                rho = np.corrcoef(ests_A, ests_B)[0, 1]

                var_ratio = (empse_A / empse_B) ** 2

                rel_increase = 100 * (var_ratio - 1)

                mcse_rel = 200 * var_ratio * np.sqrt((1 - rho**2) / (self.n_sim - 1))

                comparison_metrics.append((rel_increase, mcse_rel))

            return sim_results, comparison_metrics


if __name__ == "__main__":
    seed = 1234
    rng = np.random.default_rng(seed)

    sim_1 = SimulationComparison(
        alpha=2.0, beta=0.8, n=200, estimation_methods=["mrr"], n_sim=1000, rng=rng
    ).simulate()

    print(sim_1)
