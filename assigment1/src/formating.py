import pandas as pd
import re
import sys

def format_value(val, mcse):
    """Formats value and MCSE to 4 decimal places."""
    try:
        v = float(val)
        m = float(mcse)
        return f"{v:.4f} ({m:.4f})"
    except:
        return f"{val} ({mcse})"

def generate_typst_table(file_path):
    try:
        # Read without header initially to parse flexible structures
        df = pd.read_csv(file_path, header=None)
    except Exception as e:
        return f"Error reading file {file_path}: {e}"

    # 1. Find the row containing 'method' (header row)
    method_row_idx = None
    for i, row in df.iterrows():
        if str(row[0]).lower().startswith("method"):
            method_row_idx = i
            break
            
    if method_row_idx is None:
        return f"Error: Could not find 'method' header row in {file_path}."

    # Data starts 3 rows after the method row (Method -> Metrics -> n -> Data)
    data_start_idx = method_row_idx + 3
    
    # 2. Extract alpha/beta from filename for the caption
    filename = file_path.split('/')[-1]
    match = re.search(r'alpha([\d\.]+)-beta([\d\.]+)', filename)
    if match:
        alpha_val = match.group(1)
        beta_val = match.group(2)
        # Create a clean label tag
        caption_label = f"tbl-results-alpha{alpha_val}-beta{beta_val}".replace('.', '')
    else:
        alpha_val = "?"
        beta_val = "?"
        caption_label = "tbl-results"
    
    typst_rows = ""
    
    # 3. Extract and Process Data Rows
    # Filter for rows that actually contain method data (column 1 shouldn't be NaN)
    raw_data = df.iloc[data_start_idx:]
    valid_rows = []
    
    # Fill forward 'n' values (merged cells often leave NaNs)
    current_n = None
    for i, row in raw_data.iterrows():
        if pd.isna(row[1]): # Skip empty rows
            continue
        if not pd.isna(row[0]): # New 'n' block
            current_n = str(row[0])
        
        row_data = row.copy()
        row_data['n_filled'] = current_n
        valid_rows.append(row_data)

    # 4. Generate Typst Body
    # Define column offsets for the 3 methods (Alpha start, Beta start)
    # Based on file structure: MLE(1,19), MRR-Bernard(7,25), MRR-Beta(13,31)
    methods_config = [
        ('MLE', 1, 19),
        ('MRR (Bernard)', 7, 25),
        ('MRR (Beta)', 13, 31)
    ]

    for i, row in enumerate(valid_rows):
        n_val = row['n_filled']
        
        # Loop through the 3 methods for this single data row
        for m_idx, (m_name, a_idx, b_idx) in enumerate(methods_config):
            
            # Alpha Metrics
            a_bias = format_value(row[a_idx], row[a_idx+1])
            a_empse = format_value(row[a_idx+2], row[a_idx+3])
            a_mse = format_value(row[a_idx+4], row[a_idx+5])
            
            # Beta Metrics
            b_bias = format_value(row[b_idx], row[b_idx+1])
            b_empse = format_value(row[b_idx+2], row[b_idx+3])
            b_mse = format_value(row[b_idx+4], row[b_idx+5])
            
            # Add rowspan only for the first line of the block
            prefix = f"    table.cell(rowspan: 3)[{n_val}], " if m_idx == 0 else ""
                
            line = f"{prefix}[{m_name}], [{a_bias}], [{a_empse}], [{a_mse}], [{b_bias}], [{b_empse}], [{b_mse}]"
            
            # Add comma or newline
            is_last = (i == len(valid_rows) - 1 and m_idx == 2)
            typst_rows += line + ("\n" if is_last else ",\n")

    # 5. Assemble Full Figure
    header = f"""#figure(
  text(size: 9pt)[
    #table(
      columns: (auto, auto, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
      inset: 6pt,
      align: (col, row) => (center + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon, center + horizon).at(col),
      fill: (col, row) => if row < 2 {{ luma(240) }} else {{ none }},
      stroke: (x, y) => (
        top: if y == 2 {{ 1pt }} else {{ 0pt }},
        bottom: 1pt + luma(200),
      ),
      
      table.cell(rowspan: 2)[$m$], table.cell(rowspan: 2)[*Mètode*], 
      table.cell(colspan: 3)[$hat(alpha)$ (Paràmetre de forma)], table.cell(colspan: 3)[$hat(beta)$ (Paràmetre d'escala)],
      
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],
      [Biaix (MCSE)], [EmpSE (MCSE)], [MSE (MCSE)],

{typst_rows}    )
  ],
  caption: [Resultats de la simulació per a $alpha={alpha_val}, beta={beta_val}$. Els valors es mostren com a Estimació (MCSE).]
) <{caption_label}>"""
    
    return header

import os
from os import listdir

files = [file for file in listdir("../results/") if "summary" in file]

for file in files:
    full_path = os.path.join("../results/", file)
    if os.path.isfile(full_path):
        print(generate_typst_table(full_path))


