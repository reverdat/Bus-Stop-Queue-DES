"""
## inference.py

This module contains functions with the
different inference methods for the Weibull
distribution parameters alpha and beta
"""

from typing import Tuple, Literal

from scipy.stats import linregress
from scipy.special import betaincinv
import numpy as np

from dgm import WeibullDistribution


def median_ranks_regression(
    sample: np.array, method: Literal["beta", "roots", "bernard"] = "beta"
) -> Tuple[float]:
    """
    Performs Medians Rank Regression (MRR) estimation
    over a sample of assumed to be Weibull-dsitributed data.

    Parameters
    ----------

        sample: `np.array`
            Sample of Weibull-distributed data.
        method: `Literal["beta", "roots", "bernard"]`
            Median Rank computation method.

    Returns
    -------

        alpha, beta: `Tuple[float]`
            Estimated parameters via MRR.

    """

    # 1. Sort the sample of failure times
    sorted_sample = np.sort(sample)
    n = len(sorted_sample)

    if method == "beta":
        # 2. Vectorized calculation (betaincinv is a ufunc)
        j = np.arange(1, n + 1)
        median_ranks = betaincinv(j, n - j + 1, 0.5)
    elif method == "roots":
        raise NotImplementedError("`roots` Median Rank Computation not implemented")
    elif method == "bernard":
        raise NotImplementedError("`bernard` Median Rank Computation not implemented")
    else:
        raise ValueError(f"Uknown computation method: {method}")
    
    # 3. Assume median_ranks is Weibull CDF and linearize
    linear_probs = np.log(-np.log(1-median_ranks))

    # 4. Fit Least Squares to the transformed sample of ranks as a linear function of the failure times
    fit_result = linregress(np.log(sorted_sample), linear_probs)

    # 5. Extract parameters from the linear fit
    beta = fit_result.slope
    alpha = np.exp(-fit_result.intercept/beta)

    return alpha, beta


if __name__ == "__main__":
    seed = 1234
    rng = np.random.default_rng(seed)

    sample = WeibullDistribution(alpha=2.0, beta=0.8, rng=rng).sample(1000)

    print(median_ranks_regression(sample))
