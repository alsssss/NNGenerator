import json
import numpy as np
import math

"""
File with functions used for generic purposes
"""

def calculate_num_stages(n_inputs):
    return math.ceil(math.log2(n_inputs))

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



