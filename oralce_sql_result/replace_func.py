# -*- coding: cp932 -*-
import re
import os


def get_patterns():
    patterns = [] 
    for old_func, new_func in FUNC_MAP.items():
        pattern = re.compile(rf'\b{old_func}\s*\(', re.IGNORECASE)
        patterns.append((old_func, pattern, f"{new_func}("))
    return patterns

def process_file(filename, patterns):
    input_path = os.path.join(INPUT_DIR, filename)
    output_path = os.path.join(OUTPUT_DIR, filename)
    
    file_stat = {func: 0 for func in FUNC_MAP.keys()}
    new_lines = []
    has_replacement = False

    with open(input_path, 'r', encoding='cp932', errors='replace') as f:
        for line in f:
            if line.strip().startswith('--'):
                new_lines.append(line)
                continue
            temp_line = line
            for func_name, pattern, replacement in patterns:
                temp_line, count = pattern.subn(replacement, temp_line)
                if count > 0:
                    file_stat[func_name] += count
                    has_replacement = True
            new_lines.append(temp_line)

    if has_replacement:
        with open(output_path, 'w', encoding='cp932') as f:
            if new_lines and not new_lines[0].upper().startswith('CREATE'):
                f.write("CREATE OR REPLACE ")
            f.writelines(new_lines)
            # 各ファイルの最後にスラッシュとエラー表示を追加
            # if not new_lines[-1].strip().endswith('/'):
            #     f.write("\n/\n")
            # f.write("SHOW ERRORS\n") 
        return file_stat
    return None

def main():
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
    else:
        for f in os.listdir(OUTPUT_DIR):
            file_path = os.path.join(OUTPUT_DIR, f)
            if os.path.isfile(file_path): os.unlink(file_path)

    patterns = get_patterns()
    processed_files = []
    
    print(f"{'Filename':<30} | {'Details'}")
    print("-" * 60)

    for filename in sorted(os.listdir(INPUT_DIR)):
        if not filename.endswith('.sql') or filename.startswith(EXCLUDE_PREFIX):
            continue
        stat = process_file(filename, patterns)
        if stat:
            details = ", ".join([f"{k}:{v}" for k, v in stat.items() if v > 0])
            print(f"{filename:<30} | {details}")
            processed_files.append(filename)

    # --- all_run.sql の自動生成 (強化版) ---
    if processed_files:
        all_run_path = os.path.join(OUTPUT_DIR, ALL_RUN_FILE)
        with open(all_run_path, 'w', encoding='cp932') as f:
            f.write(f"SET FEEDBACK ON\n")
            f.write(f"SET ECHO OFF\n")
            f.write(f"SET PAGESIZE 0\n")
            f.write(f"SPOOL {LOG_FILE}\n\n") # ログ記録開始
            
            for pf in processed_files:
                f.write(f"PROMPT >>> Installing: {pf}\n")
                f.write(f"@@{pf}\n") # @@を使用してカレントディレクトリのファイルを指定
                f.write(f"SHOW ERRORS\n")
            
            f.write(f"\nSPOOL OFF\n")
            f.write(f"PROMPT --- Migration Process Finished. Check {LOG_FILE} for details. ---\n")
        
        print("-" * 60)
        print(f"置換実行ファイル数: {len(processed_files)}")
        print(f"生成完了: {all_run_path}")

if __name__ == "__main__":
    main()