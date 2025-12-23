#!/bin/python

import matplotlib.pyplot as plt
from pathlib import Path

def main() -> None:
    current_dir = Path.cwd()
    csvs_current_dir = [item for item in current_dir.iterdir() if item.is_file() and item.suffix == ".csv"]

    for file_path in csvs_current_dir:
        print(file_path.name)
        sample = read_sample_file(file_path)
        
        plt.figure(figsize=(10, 6))
        plt.hist(sample, bins=100, color='skyblue', edgecolor='black', alpha=0.7)

        plt.title(f"Distribution of {file_path.name} Data", fontsize=16)
        plt.xlabel('Value Bins', fontsize=12)
        plt.ylabel('Frequency (Count)', fontsize=12)
        plt.grid(axis='y', linestyle='--', alpha=0.7)

        try:
            output_filename = f"{file_path.stem}.png"
            plt.savefig(output_filename, dpi=300, bbox_inches='tight')
            print(f"Histogram successfully saved to: {output_filename}")
        except Exception as e:
            print(f"Error saving the file: {e}")

        plt.close()

    
def read_sample_file(filepath: str) -> list[float]:
    file = open(filepath, 'r')
    content = file.read().split(" ")
    
    if content[-1] == '\n' or content[-1] == '\n\r':
        content = content[0:len(content)-2]

    return [float(number) for number in content]

if __name__ == "__main__":
    main()
