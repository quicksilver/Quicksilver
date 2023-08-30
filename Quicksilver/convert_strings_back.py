import os
import sys
import re

regex = re.compile(r"\"(.+?)\" = \"(.+?)\"")
id_regex = re.compile(r"^/\* ([0-9]+(\.\w+)+) \*/$")

def reformat_file(stringsfile):
    print("Working on", stringsfile)
    lines = None
    for encoding in ['UTF-8', 'UTF-16']:
        try:
            with open(stringsfile, 'r', encoding=encoding) as f:
                lines = [l.strip().lstrip('\ufeff') for l in f.readlines()]
                break
        except UnicodeDecodeError:
            continue
    if lines == None:
        raise UnicodeDecodeError("Couldn't decode file ", stringsfile)
    
    new_lines = []
    for linenum, line in enumerate(lines):
        try:
            strings = regex.search(line)
            if strings:
                id_val = id_regex.search(lines[linenum-1])
                if id_val:
                    new_lines[-1] = "/* {} */".format(strings.group(1))
                    new_lines.append('"{}" = "{}"'.format(id_val.group(1), strings.group(2)))
                    continue
        except:
            print("WARNING: incompatible line: ", line)
        
        new_lines.append(line)
    with open(stringsfile, 'w') as f:
        f.writelines(l + "\n" for l in new_lines)

def main():
    try:
        directory = sys.argv[1]
    except IndexError:
        raise IndexError("Please input the directory you'd like to re-index")

    for root, dirs, files in os.walk(directory):
        for f in files:
            if f.endswith(".strings") and f not in ["IGNORED.strings", "Localizable.strings"]:
                 reformat_file(os.path.join(root, f))

if __name__ == "__main__":
    main()