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
    empse: np.float64
    mse: np.float64


@dataclass
class SimulationResult:
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
        emp_se = np.sqrt(np.sum(np.pow(estimates - theta_bar, 2)) / (self.n_sim - 1))
        mse = np.sum(np.pow(estimates - theta, 2)) / self.n_sim
        return ParameterEstimate(
            name=name,
            theta=theta,
            estimates=estimates,
            bias=bias,
            empse=emp_se,
            mse=mse,
        )

    def simulate(
        self,
    ) -> SimulationResult | Tuple[List[SimulationResult], List[np.float64]]:
        sim_results: List[SimulationResult] = []
        samples: List[np.array] = [self._generate_sample() for _ in range(self.n_sim)]
        for estimation_method in self.estimation_methods:
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
                    method=estimation_method, alpha=alpha_results, beta=beta_results
                )
            )
        if len(sim_results) == 1:
            return sim_results[0]
        else:  # If more than one estimation method is used, compute relative increase
            relative_increase_list = [
                np.pow(sim_results[1].alpha.empse / sim_results[0].alpha.empse, 2),
                np.pow(sim_results[1].beta.empse / sim_results[0].beta.empse, 2),
            ]
            return sim_results, relative_increase_list


if __name__ == "__main__":
    seed = 1234
    rng = np.random.default_rng(seed)

    sim_1 = SimulationComparison(
        alpha=2.0, beta=0.8, n=200, estimation_methods=["mrr"], n_sim=1000, rng=rng
    ).simulate()
    
    print(sim_1.alpha)
    print(sim_1.beta)
