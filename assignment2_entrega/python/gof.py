import os
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats

DATA_DIR = "samples"
RESULTS_DIR = "results"

if not os.path.exists(RESULTS_DIR):
    os.makedirs(RESULTS_DIR)

def check_distributions():
    # Get all .txt files
    files = [f for f in os.listdir(DATA_DIR) if f.endswith('.txt') or f.endswith('.csv')]
    
    print(files)
    print(f"{'FILE':<20} | {'P-VALUE':<10} | {'RESULT'}")
    print("-" * 50)

    for filename in files:
        filepath = os.path.join(DATA_DIR, filename)

        
        # Load data
        try:
            data = np.loadtxt(filepath)
        except Exception as e:
            print(f"Could not read {filename}: {e}")
            continue

        if len(data) == 0: continue

        name = os.path.splitext(filename)[0]
        p_value = 0.0
        
        # Plotting setup
        plt.figure(figsize=(10, 6))
        plt.hist(data, bins=50, density=True, alpha=0.6, color='skyblue', edgecolor='white', label='Zig Data')
        x_space = np.linspace(min(data), max(data), 1000)

        # trunc
        if "trunc" in name:
            K = 30
            # definició manual
            def trunc_cdf(c):
                c = np.clip(c, 0, K)
                return (np.exp(2) - np.exp(2 * (1 - c/K))) / (np.exp(2) - 1)
            
            y_plot = (2 / (K * (np.exp(2) - 1))) * np.exp(2 * (1 - x_space/K))
            plt.plot(x_space, y_plot, 'r-', lw=2, label='Theoretical PDF')

            statistic, p_value = stats.kstest(data, trunc_cdf)

        # erlang
        elif "erlang" in name or "gamma" in name:
            k = 3
            lam = 0.5
            scale = 1.0 / lam
            
            plt.plot(x_space, stats.gamma.pdf(x_space, a=k, scale=scale), 'r-', lw=2)
            
            statistic, p_value = stats.kstest(data, 'gamma', args=(k, 0, scale))

        # hyperexponential
        elif "hyper" in name:
            probs = [0.3, 0.7]
            rates = [3, 7]
            
            # Define Mixture CDF: p1*CDF1 + p2*CDF2
            def hyper_cdf(x):
                return (probs[0] * stats.expon.cdf(x, scale=1/rates[0]) + 
                        probs[1] * stats.expon.cdf(x, scale=1/rates[1]))
            
            y_plot = (probs[0] * stats.expon.pdf(x_space, scale=1/rates[0]) + 
                      probs[1] * stats.expon.pdf(x_space, scale=1/rates[1]))
            plt.plot(x_space, y_plot, 'r-', lw=2)

            statistic, p_value = stats.kstest(data, hyper_cdf)

        # hypoexponential
        elif "hypo" in name:
            rates = [3, 7] 
            
            sim_size = len(data)
            r1 = np.random.exponential(1/rates[0], sim_size)
            r2 = np.random.exponential(1/rates[1], sim_size)
            ground_truth = r1 + r2 
            
            kde = stats.gaussian_kde(ground_truth)
            plt.plot(x_space, kde(x_space), 'g--', lw=2, label='Python Simulation')
            
            statistic, p_value = stats.ks_2samp(data, ground_truth)

        elif "exp" in name:
            lam = 3.0
            statistic, p_value = stats.kstest(data, 'expon', args=(0, 1/lam))
            plt.plot(x_space, stats.expon.pdf(x_space, scale=1/lam), 'r-')

        
        plt.title(f"{name} (p-value: {p_value:.4f})")
        plt.legend()
        plt.savefig(os.path.join(RESULTS_DIR, f"{name}.png"))
        plt.close()

        status = "PASS" if p_value > 0.05 else "FAIL"
        print(f"{filename:<20} | {p_value:<10.4f} | {status}")

if __name__ == "__main__":
    check_distributions()
