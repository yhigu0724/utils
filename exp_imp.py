import re


def extract_info(filename):
    result = []
    with open(filename, "r") as file:
        for line in file:
            match = re.search(r'"(.*?)"\."(.*?)"\s+.*?(\d+)行', line)
            if match:
                first_text = match.group(1)
                second_text = match.group(2)
                number = match.group(3)
                result.append((first_text, second_text, number))
    return result


def compare_files(file1, file2):
    file1_info = extract_info(file1)
    file2_info = extract_info(file2)

    for info in file1_info:
        if info in file2_info:
            print(f"OK: {info}")
        else:
            print(f"NG: {info}")


# 2つのファイル名を指定して関数を呼び出す
# compare_files("nishi_exp.log", "nishi_imp.log")
compare_files("outsys_exp.log", "outsys_imp.log")
