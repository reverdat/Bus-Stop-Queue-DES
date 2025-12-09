# Simulació Assigment 1
------------
# ADMEP

## A. Aims

The primary aim of this simulation study is to compare two different estimation methods for the parameters of the Weibull distribution, i.e. with a r.v. with probability density function

$$
f(x; \alpha, \beta) = \frac{\beta}{\alpha}\left(\frac{x}{\alpha}\right)^{\beta - 1} \exp\left(-(x/\alpha)^{\beta}\right)\mathbf{1}_{x \geq 0},
$$

where $\alpha > 0$ and $\beta > 0$ are the scale and shape parameters. Such methods are the ordinary Maximum Likelihood Estimation (MLE) and the Median Ranks Regression (MRR). To that end, theory for both methods is explained in detail, and simulations are performed to assess the quality and verify the properties of the resulting point estimates.

## D. Data-Generating Mechanisms (DGM)

The DGM defines how pseudo-random sampling is used to create data. This study will exclusively contain parametric simulations of Weibull-distributed data for different configurations of the parameters $(\alpha, \beta)$ in order to experiment with the estimation as a function of the shape of the distribution, as well as the sample size.



### 1. Model Specification

*   **Data Structure:** $\textit{i.i.d}$. observations $T_1, T_2, \ldots, T_n$ are collected for a predefined sample size $n > 0$.
*   **Distribution:** $T_i \sim \text{Weibull}(\alpha, \beta)$, for some $\alpha, \beta >0$. Observations represent time/cycles until failure.



### 2. Factors to vary

The data is simulated under three possible values for each parameter: small, medium and large; moreover, these scenarios are repeated for three increasing values for the sample size, thus defining the following factor grid:

| Factor | Type | Small | Medium | Large|
| :--- | :--- | :--- | :--- | :--- |
| **$\alpha$ (Scale)** | Distribution parameter | 2.0 | 10.0 | 50.0 |
| **$\beta$ (Shape)** | Distribution parameter | 0.8 | 1.0 | 3.0 |
| **$n$ (Sample size)** | Sampling parameter | 10 | 50 | 200 |

The choice of this parameter grid is justified as follows:

* $\alpha$ **(Scale)**: Known as the characteristic life, it is scaled according to the context of the problem; that is, we chose these values as representatives for the three distinct simulation scenarios, but in real-world setting, they scale according to the units of the observations (seconds, minutes, hours, cycles).
* $\beta$ **(Shape)**: In our predefined context, $\alpha$ is a dimensionless parameter known as failure rate, and modifies the behaviour of the Weibull distribution in the following three characterized cases:

    1. **$\beta < 1$**: Decreasing failure rate/"infant mortality". The longer a unit survives, the lower its probability of failing in the next instant.
    2. **$\beta = 1$**: Constant failure rate. Reduces the Weibull to an Exponential distribution. Failures are random and independent of time. 
    3. $\beta > 1$: Increasing failure rate. Wear-out; probability of failure increases as time increases.

* $n$ **(Sample size)**: Our choice is considered to be a standard set of values for a small, medium and large collections of observations.

### 3. Number of Repetitions ($n_{sim}$)

The number of repetitions must be chosen to achieve an acceptable Monte Carlo Standard Error (MCSE) for the MSE (**TBD: Perhaps look for an appropiate paper
on the number of simulations to performed, like Marozzi (2004) in permutation tests**).

Instead, we can add $n_{sim}$ as another factor to vary in the experiment, and look how the MCSE mesures decreases as the number of repetitions increase.


## M. Methods



### Method 1: Maximum Likelihood Estimation (MLE)

**TBD**

### Method 2: Median Ranks Regression (MRR)

The Median Ranks Regression (MMR) method for the estimation of the parameters cosists of three steps:

1. Compute the median rank $\text{MR}_j$ of each observed failure $T_j$ of the Weibull-distributed sample via
$$
0.50 = \sum_{k=j}^{N} \binom{N}{k} \text{MR}_{j}^{k}(1-\text{MR}_{j})^{N-k}
$$ 
and use it as estimate of the true unreliability: $Q(T_j) \approx MR_j$. The equation can be solved using root-finding algorithms such as Newton's method.

2. Transform the unreliability estimates via the mapping
$$
Q \mapsto \log\left(-\log\left(1-Q\right)\right).
$$
Indeed, observe that this function is well-defined, as $Q \in (0,1)$ and $-\log(1-Q) > 0$. This function transforms the cdf of the Weibull into a line. Indeed,
$$
F(x; \alpha, \beta) = 1 - e^{-(x/\alpha)^{\beta}}  \\
 F-1 = -e^{-(x/\alpha)^{\beta}} \\
-\log(1-F) = \left(\frac{x}{\alpha}\right)^{\beta} \\
\log\left(-\log(1-F)\right) = \beta\log(x) - \beta\log(\alpha).
$$

3. With the sample of pairs of failure times and their unreliability estimates $(T_j, Q_j)$, use Least Squares to fit a line and extract the resulting coefficients $m, b$. Then, inference on the parameters of our Weibull model can be achieved by
$$
m \equiv \beta \\
b \equiv -\beta\log\alpha \Rightarrow \alpha = \exp({-b/\beta}).
$$



## E. Estimands



| Statistical Task | Target | Description |
| :--- | :--- | :--- |
| Estimation | **$\alpha$** | Scale parameter |
| Estimation | **$\beta$** | Shape parameter |


## P. Performance Measures
For each of the parameters to be estimated, $\theta \coloneqq \alpha, \beta$, we compute the following standard performance measures:

| Performance Measure | Computation | MCSE Formula|
| :--- | :--- | :--- |
| **Bias** | $\frac{1}{n_{sim}}\sum_{i=1}^{n_{sim}} (\hat{\theta_{i}} - \theta)$ | $\sqrt{\frac{1}{n_{sim} - 1}\sum_{i=1}^{n_{sim}} (\hat{\theta_{i}} - \theta)^{2}}$ |
| **Empirical Standard Error (EmpSE)** | $\sqrt{\frac{1}{n_{sim} - 1}\sum_{i=1}^{n_{sim}} (\hat{\theta_{i}} - \bar{\theta})^{2}}$ | $\frac{\text{EmpSE}}{\sqrt{2(n_{sim} - 1)}}$ |
| **Mean Squared Error (MSE)** | $\frac{1}{n_{sim}}\sum_{i=1}^{n_{sim}} (\hat{\theta_{i}} - \theta)^{2}$ | $\sqrt{\frac{\sum_{i=1}^{n_{sim}} [(\hat{\theta_{i}} - \theta)^{2} - \text{MSE}]^{2}}{n_{sim}(n_{sim} - 1)}}$ |
where $\hat{\theta}_{i}$ is the parameter estimate for the $i$-th simulation, and $\bar{\theta} = \frac{1}{n_{sim}} \sum^{n_{sim}}_{i=1} \theta_i$.

Moreover, since MLE is the default estimation method for the Weibull parameters, we shall study whether there is an increase in precision by using MRR when compared to MLE:

$$\text{Relative increase in precision} = \frac{\text{Var}(\hat{\theta}_{MLE})}{\text{Var}(\hat{\theta}_{MRR})} = \left(\frac{\text{EmpSE}_{MLE}}{\text{EmpSE}_{MRR}}\right)^2$$


with MCSE defined as
$$\text{MCSE} \simeq 2 \frac{\text{Var}(\hat{\theta}_{MLE})}{\text{Var}(\hat{\theta}_{MRR})} \sqrt{\frac{1 - \rho^2_{MLE,MRR}}{n_{sim} - 1}}$$

where:
*   $\text{Var}(\hat{\theta}_{MLE})$ and $\text{Var}(\hat{\theta}_{MRR})$ are the empirical variances of the two estimators.
*   $\rho_{MLE,MRR}$ is the **correlation** of the estimates $\hat{\theta}_{MLE}$ and $\hat{\theta}_{MRR}$.




## Referències


[1] Morris TP, White IR, Crowther MJ. Using simulation studies to evaluate statistical methods. Statistics in Medicine. 2019;38(11):2074-102. 

[2] Civit S. Estimator comparison.  
