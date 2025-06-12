import os
import numpy as np
import math
import shutil

"""
File with functions used for generic purposes, mostly list and array manipulation
"""

def calculate_num_stages(n_inputs):
    return math.ceil(math.log2(n_inputs))

def calculate_ROM_address(mem_depth):
    return int(math.ceil(math.log2(mem_depth))) 

def calculate_mem_depth(n_elements, denominator):
    return math.ceil(n_elements / denominator)

def concatenate_arrays(array):
    long_vector = np.concatenate(array)
    return long_vector

def generate_layer_offsets(step_size, num_layers):
    return [i * step_size for i in range(num_layers)]

def cumulative_offsets(lst):
    result = [0]
    for val in lst[:-1]:  
        result.append(result[-1] + val)
    return result

def insert_at_intervals(large_list, small_list, interval, count):
    result = []
    small_idx = 0
    inserted = 0
    i = 0

    while i < len(large_list):
        result.append(large_list[i])
        i += 1

        if (i % interval == 0) and (inserted < count) and (small_idx < len(small_list)):
            result.append(small_list[small_idx])
            small_idx += 1
            inserted += 1

    return result

def pad_to_multiple_of_four(data, length):
    result = []
    for i in range(0, len(data), length):
        segment = data[i:i+length]
        padding_needed = (4 - (len(segment) % 4)) % 4
        segment += [0] * padding_needed
        result.extend(segment)
    return result

def include_synthesis_files(synth_dir, final_dir):
    files_to_copy = [
        "clock_divider.vhd",
        "debounce.vhd",
        "memory3.vhd",
        "types.vhd",
        "uart.vhd",
        "wired.xdc"
    ]
    for file in files_to_copy:
        src = os.path.join(synth_dir, file)
        dst = os.path.join(final_dir, file)
        shutil.copy(src, dst)


"""
def pad_to_multiple_of_four(data, breakpoints):
    result = []
    last_index = 0

    for bp in breakpoints:
        segment = data[last_index:bp]
        padding_needed = (4 - (len(segment) % 4)) % 4
        segment += [0] * padding_needed
        result.extend(segment)
        last_index = bp

    # Pad the remaining tail if not covered by breakpoints
    if last_index < len(data):
        segment = data[last_index:]
        padding_needed = (4 - (len(segment) % 4)) % 4
        segment += [0] * padding_needed
        result.extend(segment)

    return result
"""