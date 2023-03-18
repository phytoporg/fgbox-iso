#!/usr/bin/python3

################################################################################
# patch_vdf.py - For patching Valve Data Files
# 
# Usage: ./patch_vdf.py
#   --vdf-file <Target VDF file to modify>
#   --data-path <VDF data path to modify, i.e. A.B.C>
#   --data-value <Json data to set for variable at the provided data path>
#
# Result goes to stdout
################################################################################

from collections import deque
import argparse
import json
import os
import sys

def nested_dicts_to_vdf(data):
    dict_stack = deque()

    # Maintain a stack of iteration state:
    #                   dict  keys               key index
    dict_stack.append([ data, list(data.keys()), 0 ])

    string_out = ""

    def indent_string(string):
        return '\t' * (len(dict_stack) - 1) + string

    while len(dict_stack) > 0:
        current_dict, current_keys, current_i = dict_stack.pop()

        while current_i < len(current_keys):
            key = current_keys[current_i]
            current_i += 1

            if type(current_dict[key]) is dict:
                # Entering another level of nesting, push state onto the stack and
                # begin anew!!
                dict_stack.append([ current_dict, current_keys, current_i ])
                current_dict = current_dict[key]
                current_keys = list(current_dict.keys())
                current_i = 0

                string_out += indent_string(f'"{key}"\n')
                string_out += indent_string('{\n')
            else:
                string_out += indent_string(f'\t"{key}"\t"{current_dict[key]}"\n')

        if len(dict_stack) > 0:
            string_out += indent_string('}\n')

    return string_out

def vdf_to_nested_dicts(vdf_file_path):
    with open(vdf_file_path, 'r') as fr:
        all_lines = fr.readlines()

    data = dict()
    dict_stack = deque()
    dict_stack.append(data)

    for line in all_lines:
        # Strip all double quotes, we'll reintroduce them when 
        # generating a vdf
        line_tokens = [token.replace('"','') for token in line.split()]
        if len(line_tokens) == 1:
            token = line_tokens[0]
            if token not in ['{', '}']:
                # New nesting level and key
                new_data = dict()
                dict_stack[-1][token] = new_data
                dict_stack.append(new_data)
            elif token == '}':
                # Closing up this nesting level
                dict_stack.pop()
        elif len(line_tokens) == 2:        
            # Key-value pair in the current nesting level
            key, value = line_tokens
            dict_stack[-1][key] = value

    return data
        
def main(args):
    if not os.path.exists(args.vdf_file):
        print(f'Could not find VDF file: {args.vdf_file}', file=sys.stderr)
        exit(1)

    # TODO: handle parse failures
    parsed_data_value = json.loads(args.data_value)

    data = vdf_to_nested_dicts(args.vdf_file)

    prev_iter = None
    data_iter = data
    data_path_traversed = []
    for data_path_token in args.data_path.split('.'):
        data_path_traversed.append(data_path_token)
        if data_path_token not in data_iter:
            print(f'Creating new path node: {".".join(data_path_traversed)}')
            data_iter[data_path_token] = dict()

        prev_iter = data_iter
        data_iter = data_iter[data_path_token]

    prev_iter[data_path_traversed[-1]] = parsed_data_value
    vdf_text = nested_dicts_to_vdf(data)
    print(vdf_text)

if __name__=="__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--vdf-file', help="Source VDF file to modify")
    parser.add_argument('--data-path', help="VDF data path to modify")
    parser.add_argument('--data-value', help="Json-encoded data value to set")

    main(parser.parse_args())
