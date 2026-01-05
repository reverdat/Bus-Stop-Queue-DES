"""
## dgm.py

This module contains all the functionality
required to generate a sample of an arbitrary
size for a Weibull distribution. Random
state is controlled in order to ensure
reproducibility.
"""

import numpy as np

class WeibullDistribution:
    """
    A Weibull-distributed random variables of parameters
        - alpha: Scale parameter (characteristic life). Greater than 0.
        - beta: Shape parameter (failure rate). Greater than 0.
    """

    def __init__(
        self,
        alpha: float,
        beta: float,
        rng: np.random.Generator = None,
        seed: int = None,
    ):
        if rng is not None:
            self.rng = rng
        elif seed is not None:
            self.rng = np.random.default_rng(seed)
        else:
            self.rng = np.random.default_rng()

        if alpha <= 0:
            raise ValueError(
                "Parameter alpha of Weibull distribution must be greater than 0."
            )
        self.alpha = alpha

        if beta <= 0:
            raise ValueError(
                "Parameter beta of Weibull distribution must be greater than 0."
            )
        self.beta = beta
        self.params = {"alpha": alpha, "beta": beta}

    def sample(self, n: int) -> np.array:
        sample = self.alpha * np.pow(-np.log(self.rng.random(n)), 1.0 / self.beta)
        return sample
