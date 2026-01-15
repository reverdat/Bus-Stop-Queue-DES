import sys
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

def main(input_path):
    output_dir = Path("results")
    output_dir.mkdir(parents=True, exist_ok=True)

    try:
        df = pd.read_csv(input_path)
        df = df.dropna(axis=1, how='all')
        df.columns = df.columns.str.strip()

    except Exception as e:
        print(f"Error reading CSV: {e}")
        sys.exit(1)

    plt.style.use('ggplot')

    # configuration: (Column Name, Title, Color, Output Filename)
    plots_config = [
        ('queue_time',   r'$W_q$ (Queue Time)',   '#E24A33', 'histogram_Wq.png'),
        ('service_time', r'$W_s$ (Service Time)', '#348ABD', 'histogram_Ws.png'),
        ('total_time',   r'$W$ (Total Time)',     '#988ED5', 'histogram_W.png'),
    ]

    for col, title, color, out_name in plots_config:
        if col in df.columns:
            plt.figure(figsize=(10, 6))
            
            data = df[col]
            
            plt.hist(data, bins=30, color=color, edgecolor='white', alpha=0.8)
            
            mean_val = data.mean()
            plt.axvline(mean_val, color='black', linestyle='--', linewidth=1, label=f'Mean: {mean_val:.2f}')
            
            plt.title(title, fontsize=16)
            plt.xlabel("Time")
            plt.ylabel("Frequency")
            plt.legend()
            
            plt.tight_layout()

            # Save individual file
            save_path = output_dir / out_name
            plt.savefig(save_path, dpi=300)
            
            plt.close()
            
            print(f"Saved: {save_path}")
        else:
            print(f"Warning: Column '{col}' not found in CSV.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python plot_results.py <filename.csv>")
        sys.exit(1)

    filename = sys.argv[1]
    input_path = Path(filename)

    if not input_path.exists():
        print(f"Error: File '{filename}' not found.")
        sys.exit(1)

    main(input_path)
