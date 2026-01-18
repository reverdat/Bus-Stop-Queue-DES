# Bus Stop Queueing Simulation (Zig)

A high-performance discrete-event simulation (DES) engine for analyzing bus stop operations as a batch-service queueing system. Built in Zig for maximum computational efficiency.

## Authors

- **Arnau Pérez Reverte (@reverdat)**
- **Pau Soler Valadés (@PauSolerValades)**

This project was developed as part of the Simulation course at MESIO, UPC-UB (2025-2026).

## Overview

This simulator models a realistic bus stop scenario using event-scheduling methodology where:
- **Passengers** arrive stochastically and join a FIFO queue
- **Buses** arrive at random intervals with random capacity
- **Boarding** takes random time per passenger, creating batch service dynamics

The implementation validates against analytical $M/M^{[X]}/1/K$ queueing model and verifies Little's Law empirically.

## Features

### Core Capabilities
- **Event-driven simulation** with priority queue (min-heap) scheduling
- **Multiple probability distributions**: Exponential, Uniform, Hypoexponential, Hyperexponential, k-Erlang, Truncated Exponential
- **Monte Carlo batch execution** with confidence intervals (up to 10^7 replications)
- **Analytical validation** against $M/M^{[X]}/1/K$ steady-state solutions
- **Little's Law verification** for system validation
- **JSON configuration** for flexible parameter specification
- **Trace generation** and detailed user timeline CSV export

### Performance
- **Fast execution**: 100,000+ replications in seconds on modest hardware
- **Memory efficient**: Buffered I/O to prevent memory overflow on long horizons

## System Model

The simulation represents the state as $(n, c)$ where:
- $n$ = number of passengers in the waiting area
- $c$ = remaining capacity of the current bus

### Event Types
1. **Arrival**: Passenger arrives and joins queue (or is lost if system at capacity)
2. **Service**: Bus arrives with random capacity
3. **Boarding**: Passenger completes boarding process

### Key Metrics
- **$L$**: Average customers in system
- **$L_q$**: Average customers in queue  
- **$W$**: Average total time in system
- **$W_q$**: Average queue waiting time
- **$W_s$**: Average service time

## Installation

### Building from Source

**Requirements**: Zig 0.15.2
```bash
# Clone repository
git clone https://github.com/reverdat/Bus-Stop-Queue-DES.git
cd Bus-Stop-Queue-DES

# Build (debug mode)
zig build

# Build optimized release binaries for all platforms
zig build release

# Build and run
zig build run -- input_params/mmx1k.json
```

The compiled binary will be in `zig-out/bin/`.

## Usage

### Basic Execution
```bash
# Run with configuration file
./busstop-simulation input_params/grup2/rho1.json

# Show help
./busstop-simulation --help

# Show system information
./busstop-simulation --info
```

### Configuration File Format

Create a JSON file with the following structure:
```json
{
  "iterations": 10000,
  "seed": 42,
  "sim_config": {
    "horizon": 300.0,
    "system_capacity": 0,
    "passenger_interarrival": {
      "exponential": 0.30
    },
    "bus_interarrival": {
      "hypo": [0.333333, 0.142857]
    },
    "bus_capacity": {
      "exp_trunc": { "lambda": 0.10, "max": 30.0 }
    },
    "boarding_time": {
      "uniform": {"min": 2.0, "max": 8.0}
    }
  }
}
```

**Note**: All time units are in **minutes** except `boarding_time` which is in **seconds**.

### Supported Distributions

| Distribution | JSON Format | Parameters |
|--------------|-------------|------------|
| Constant | `{"constant": 5.0}` | value |
| Exponential | `{"exponential": 0.5}` | rate (λ) |
| Uniform | `{"uniform": {"min": 2.0, "max": 8.0}}` | min, max |
| Hypoexponential | `{"hypo": [0.33, 0.14]}` | array of rates |
| Hyperexponential | `{"hyper": {"probs": [0.3, 0.7], "rates": [1.0, 2.0]}}` | probabilities, rates |
| k-Erlang | `{"erlang": {"k": 3, "lambda": 0.5}}` | shape, rate |
| Truncated Exp | `{"exp_trunc": {"lambda": 0.1, "max": 30.0}}` | rate, max value |

### Output

**Standard output** (B > 1):
```
+----------------------+
| BATCH RESULTS (B=10000000) |
+----------------------+
Avg Duration (s)        : 0.0002 +/- 0.000001 (95% CI)
Avg Clients (L)         : 3.2080 +/- 0.000696 (95% CI)
Avg Clients Queue (L_q) : 3.1511 +/- 0.000688 (95% CI)
Avg Queue Time (W_q)    : 10.3927 +/- 0.002120 (95% CI)
Avg Service Time (W_s)  : 0.2791 +/- 0.000034 (95% CI)
Avg Total Time (W)      : 10.6718 +/- 0.002140 (95% CI)
Total Time Elapsed: 17.5364s
```

**Files generated** (B = 1):
- `traca.txt`: Event trace showing state transitions
- `usertimes.csv`: Detailed timeline for each user

## Technical Details

### Algorithm: Event-Scheduling (DES)

The simulation uses a **min-heap priority queue** to efficiently process events in chronological order:

1. **O(1)** access to next event (minimum time)
2. **O(log n)** insertion of new events
3. Dynamic event generation maintains simulation flow

### Memory Management

- **Stack-allocated buffers** (64KB) for I/O operations
- **Arena allocator** for event storage
- **Incremental memory release** to prevent overflow on long horizons
- No dynamic growth for steady-state simulations

### Distribution Implementation

All distributions use the **inverse transform method** or **composition** where applicable:
- Truncated Exponential: Analytical CDF inversion
- Hypoexponential: Sampling from sum of independent exponentials
- Hyperexponential: Probabilistic branching + exponential sampling
