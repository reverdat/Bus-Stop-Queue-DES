"""
## inference.py

This module contains functions with the
different inference methods for the Weibull
distribution parameters alpha and beta
"""

from typing import Tuple, Literal, Callable

from scipy.stats import linregress, weibull_min
from scipy.special import betaincinv
import numpy as np

from dgm import WeibullDistribution

type EstimationMethod = Literal["mrr", "mle"]
type MRREstimationMethod = Literal["beta", "roots", "bernard"]
type MLEEstimationMethod = Literal["scipy"]

def estimation_method_dispatcher(estimation_method: EstimationMethod) -> Callable:
    if estimation_method == "mrr":
        return median_ranks_regression
    elif estimation_method == "mle":
        return mle_estimator 
    else:
        raise ValueError(f"Unknown estimation method: {estimation_method}")

def mle_estimator(sample: np.array, method: MLEEstimationMethod = "scipy") -> (float, float):
    
    if method != "scipy":
        raise NotImplementedError("Just scipy")

    n = len(sample)
    # compute mle with scipy. loc=0 due to using a two parameter weibull
    beta, loc, alpha = weibull_min.fit(sample, floc = 0)
    return alpha, beta 

def median_ranks_regression(
    sample: np.array, method: MRREstimationMethod = "beta"
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
        j = np.arange(1, n + 1)
        median_ranks = (j - .3)/(n + .4)
    else:
        raise ValueError(f"Uknown computation method: {method}")

    # 3. Assume median_ranks is Weibull CDF and linearize
    linear_probs = np.log(-np.log(1 - median_ranks))

    # 4. Fit Least Squares to the transformed sample of ranks as a linear function of the failure times
    fit_result = linregress(np.log(sorted_sample), linear_probs)

    # 5. Extract parameters from the linear fit
    beta = fit_result.slope
    alpha = np.exp(-fit_result.intercept / beta)

    return alpha, beta


if __name__ == "__main__":
    seed = 1234
    rng = np.random.default_rng(seed)
    
    alpha, beta = 2.0, 0.8

    print("Generating a Weibull Sample with alpha = {alpha} beta = {beta}")
    sample = WeibullDistribution(alpha=alpha, beta=beta, rng=rng).sample(1000)
    
    print("Estimation Results:")
    print(f"MRR - beta: \t{median_ranks_regression(sample)}")
    print(f"MRR - bernard: \t{median_ranks_regression(sample, method="bernard")}")
    print(f"MLE: \t\t {mle_estimator(sample)}")
