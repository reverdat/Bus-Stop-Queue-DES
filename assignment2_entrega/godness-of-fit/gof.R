# SCRIPT to generate goodness-of-fit results and hitograms of the following distributions:
# - uniform
# - exponential
# - trunc_exponential
# - hypoexponenital
# - hyperexponential
# - erlang

data_dir <- "data"
results_dir <- "results"

if (!dir.exists(results_dir)) {
  dir.create(results_dir)
}

# Truncated Exponential Professor's Formula
K_trunc <- 30 
f_trunc <- function(x) {
  # PDF for plotting
  val <- (2 / (K_trunc * (exp(2) - 1))) * exp(2 * (1 - x/K_trunc))
  val[x < 0 | x > K_trunc] <- 0
  return(val)
}

F_trunc <- function(x) {
  # CDF for KS Test
  p <- (exp(2) - exp(2 * (1 - x/K_trunc))) / (exp(2) - 1)
  p[x < 0] <- 0
  p[x > K_trunc] <- 1
  return(p)
}

# Erlang (Gamma)
k_erl <- 3      # Shape
lam_erl <- 0.5  # Rate (scale = 1/rate)

# hyperexponential 
probs_hyper <- c(0.3, 0.7)
rates_hyper <- c(0.5, 2.0)

dhyper_custom <- function(x) {
  probs_hyper[1] * dexp(x, rates_hyper[1]) + 
  probs_hyper[2] * dexp(x, rates_hyper[2])
}
phyper_custom <- function(x) {
  probs_hyper[1] * pexp(x, rates_hyper[1]) + 
  probs_hyper[2] * pexp(x, rates_hyper[2])
}

# Hypoexponential (Sum of DIFFERENT rates)
rates_hypo <- c(0.5, 1.2, 3.0)
# For Hypo, we simulate ground truth in R because the PDF is messy
simulate_hypo_r <- function(n) {
  replicate(n, sum(rexp(length(rates_hypo), rates_hypo)))
}
