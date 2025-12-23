#!/bin/R

if (!require("microbenchmark", quietly = TRUE)) {
  stop("microbenchmark not installed")
}
if (!require("ggplot2", quietly = TRUE)) {
  stop("ggplot2 not installed")
}

library(microbenchmark)
library(ggplot2)

n <- 1000000
min_val <- 0.0
max_val <- 1.0
num_trials <- 100

cat(paste("Benchmarking with n =", n, "samples over", num_trials, "trials.\n\n"))

benchmark_results <- microbenchmark(
  "Uniform" = {
    results <- numeric(n)
    results <- runif(n, min_val, max_val)
  }, 
  "Uniform (no storing)" = {
	runif(n, min_val, max_val)
  }, times = num_trials

)

print(benchmark_results)


