import os
import re
import subprocess

def run_analyze():
    print('Running flutter analyze...')
    with open('.analyze_out', 'w', encoding='utf-8') as f:
        subprocess.run(['flutter', 'analyze'], stdout=f, stderr=subprocess.STDOUT, shell=True)

def fix_errors():
    with open('.analyze_out', 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    fixed = 0
    for line in lines:
        if "error - Methods can't be invoked in constant expressions" in line or "error - Invalid constant value" in line or "error - Expected to find ','" in line:
            parts = line.split(' - ')
            if len(parts) >= 3:
                file_line_col = parts[-2].strip()
                match = re.match(r'(.+\.dart):(\d+):(\d+)', file_line_col)
                if match:
                    file_path = match.group(1)
                    line_num = int(match.group(2))
                    
                    if os.path.exists(file_path):
                        with open(file_path, 'r', encoding='utf-8') as src:
                            src_lines = src.readlines()
                        
                        if line_num <= len(src_lines):
                            for i in range(line_num - 1, max(-1, line_num - 11), -1):
                                if 'const ' in src_lines[i] or 'const\n' in src_lines[i] or 'const\r' in src_lines[i] or 'const[' in src_lines[i]:
                                    src_lines[i] = re.sub(r'\bconst\s+', '', src_lines[i], count=1)
                                    src_lines[i] = re.sub(r'\bconst\[', '[', src_lines[i], count=1)
                                    fixed += 1
                                    break
                                    
                        with open(file_path, 'w', encoding='utf-8') as src:
                            src.writelines(src_lines)
    return fixed

for _ in range(5):
    run_analyze()
    fixed_count = fix_errors()
    print('Fixed', fixed_count, 'const errors')
    if fixed_count == 0:
        break
