import sys
import re
import numpy as np
import os
import shutil
import helper as help
from jinja2 import Environment, FileSystemLoader
from ModelParser import ModelParser
from TopModel import TopModel 
from LoaderModel import LoaderModel
from PkgModel import PkgModel
from TestBenchModel import TestBenchModel
from ControllerModel import ControllerModel
from MaxModel import MaxModel

""" 
Folder structure: 
proj.
  |-> Source_Code -> The main python code is here 
        |->Json_files     
  |-> Templates -> VHDL templates are here
  |-> ONNX_Models
  |-> Results
"""

class Manager:

    dtype_bit_map = {
        "float32": 32,
        "float64": 64,
        "int8": 8,
        "int16": 16,
        "int32": 32,
        "int64": 64,
        "uint8": 8,
        "uint16": 16,
        "uint32": 32,
        "uint64": 64,
        "bit": 1
    }

    max_width_mem = []
    max_neuron_mem = []
    fixed_neur_mem = []
    neuron_sum_mem = []
    layer_max_counter = 0
    one_layer_mem = []
    neuron_attitudes = []
    full_output_mem = [] 
    current_neurons = []

    def __init__(self, filename, final_dir):
        here = os.path.dirname(os.path.abspath(__file__))  
        parent_dir = os.path.join(here, os.pardir)  
        templates_dir = os.path.join(parent_dir, "Templates")  
        os.makedirs(templates_dir, exist_ok=True)
        json_dir = os.path.join(here, "json_files")
        os.makedirs(json_dir, exist_ok=True)
        ONNX_dir = os.path.join(parent_dir, "ONNX_Models")  
        os.makedirs(ONNX_dir, exist_ok=True)
        results_dir = os.path.join(parent_dir, "Results")  
        os.makedirs(results_dir, exist_ok=True)

        self.templates_dir = templates_dir  
        self.json_dir = json_dir
        self.ONNX_dir = ONNX_dir
        self.final_dir = os.path.join(results_dir, final_dir) 
        self.activations = [
            'Relu', 'Sigmoid', 'Tanh', 'Softmax', 'LeakyRelu',
            'Elu', 'Selu', 'PRelu', 'ThresholdedRelu'
        ]

        self.prepare_folder(self.final_dir)

        parser = ModelParser(self.ONNX_dir, filename)
        parser.parser()
        parser.hyperM_function()
        self.onnx_dict = parser.model
        self.onnx_dict["different_neurons"] = True
        self.onnx_dict["handshake"] = True
        if self.onnx_dict["handshake"] is True:
             self.onnx_dict["sum_logic"] = "state_mode"
        else:
             self.onnx_dict["sum_logic"] = "no_loop"

#   Start from this class to enable full customization of every single neuron
    """ def get_strings(expected_length):
        user_inputs = []
        print("Enter strings one by one. Press Enter on an empty line to finish.")
        while True:
            user_input = input(">> ").strip()
            if user_input == "":
                break
            if user_input in expected_dict and len(expected_dict[user_input]) == expected_length:
                user_inputs.append(user_input)
            else:
                print("Invalid input (not in dictionary or wrong length). Skipped.")
        return user_inputs"""

    def prepare_folder(self, folder_path):
        if os.path.exists(folder_path):
            for item in os.listdir(folder_path):
                item_path = os.path.join(folder_path, item)
                if os.path.isfile(item_path) or os.path.islink(item_path):
                    os.remove(item_path)
                elif os.path.isdir(item_path):
                    shutil.rmtree(item_path)
        else:
            os.makedirs(folder_path)

    def get_total_layer_count(self):
        layer_count = self.onnx_dict["num_layers"]
        return(layer_count)

    def get_layer_names(self):
        layer_names = []
        layers = self.onnx_dict.get("layers", [])
        if not layers:
            raise ValueError("Error: No layers found in the ONNX dictionary.")
        for index, layer in enumerate(layers):
            layer_name = layer.get("layer_name", "")
            if layer_name: 
                base_layer_name = layer_name.split('/')[-1]
                layer_names.append(f"{base_layer_name}_{index}")
        return layer_names

    def get_layer_weight_matrix(self, layer_index):
        weights = self.onnx_dict["layers"][layer_index].get("weights_matrix", [])
        return np.array(weights)
    
    def get_all_weight_columns_flattened(self):
        flattened = []
        for layer_index in range(self.onnx_dict["num_layers"]):
            matrix = self.get_layer_weight_matrix(layer_index)
            for col in range(matrix.shape[1]):
                flattened.extend([int(val) for val in matrix[:, col]])
        return flattened
        
    def get_all_columns_padded(self):
        all_columns = []

        # Collect all column vectors from each layer
        for layer_index in range(self.onnx_dict["num_layers"]):
            matrix = self.get_layer_weight_matrix(layer_index)
            _, num_neurons = matrix.shape
            for col in range(num_neurons):
                col_data = [int(val) for val in matrix[:, col]]  # Convert to integers
                all_columns.append(col_data)

        # Find the maximum length
        max_length = max(len(col) for col in all_columns)

        # Pad each column with zeros (as integers) to the max_length
        padded_columns = []
        for col in all_columns:
            padding = [0] * (max_length - len(col))  # Use integer zero
            padded_columns.append(col + padding)

        return padded_columns

    def get_padded_weight_columns(self, selected_layers, max_neurons_num, less_neuron=False):
        all_columns = []

        # Collect all columns (neuron weight vectors) from the selected layers
        for layer_index in selected_layers:
            matrix = np.array(self.onnx_dict["layers"][layer_index]["weights_matrix"])
            num_inputs, num_neurons = matrix.shape

            layer_columns = []
            for col in range(num_neurons):
                column_data = [int(val) for val in matrix[:, col]]
                layer_columns.append(column_data)

            if less_neuron:
                remainder = len(layer_columns) % max_neurons_num
                padding_needed = (max_neurons_num - remainder) if remainder != 0 else 0

                if padding_needed > 0:
                    zero_col = [0] * num_inputs
                    layer_columns.extend([zero_col] * padding_needed)

            all_columns.extend(layer_columns)

        # Now ensure all columns are padded to the same height (max_length)
        max_length = max(len(col) for col in all_columns)
        padded_columns = [col + [0] * (max_length - len(col)) for col in all_columns]

        if less_neuron:
            return padded_columns

        # Default behavior: pad rows to fill max_neurons_num × num_layers
        desired_total_rows = max_neurons_num * len(selected_layers)
        current_rows = len(padded_columns)
        pad_rows = desired_total_rows - current_rows

        if pad_rows > 0:
            zero_column = [0] * max_length
            padded_columns.extend([zero_column] * pad_rows)

        return padded_columns

    def get_weight_indexes(self):
        input_widths= self.get_layer_input_widths()
        neurons= self.get_neuron_per_layer()
        count = 0
        result = []
        for i in range(len(input_widths)):
            temp = []
            for j in range(neurons[i]):
                temp.append(count + input_widths[i] * j)
            result += temp
            count = temp[-1] + input_widths[i]  # move to the next block
        return result
    
    def get_weight_costants(self, input_width, num_neurons):
        return [input_width * i for i in range(num_neurons)]
    
    def get_bias_indexes(self):
        initial = [0]
        extension = self.get_layer_input_widths()[1:]
        initial.extend(extension)
        return initial

    def get_biases_all(self, selected_layers) -> list:
        layers = self.onnx_dict.get("layers", [])
        if not layers:
            raise ValueError("No layers found in ONNX dictionary.")

        bias_list = []
        for i, layer in enumerate(layers):
            if i not in selected_layers:
                continue  # Skip if the layer is not selected
            biases = layer.get("biases", [])
            bias_values = [b["bias_value"] for b in biases]
            bias_list.append(bias_values)

        return bias_list
        
    def get_flattened_biases(self):
        all_biases = []
        for layer in self.onnx_dict["layers"]:
            biases = [int(b["bias_value"]) for b in layer["biases"]]
            all_biases.extend(biases)
        return all_biases
    
    def get_padded_biases(self, selected_layers, max_neurons_num, less_neuron=False):
        all_biases = []
        bias_list = self.get_biases_all(selected_layers)  # Get biases only for selected layers

        if not bias_list:
            raise ValueError("No biases found for selected layers.")

        if less_neuron:
            for layer_idx in range(len(selected_layers)):  # Iterate over the indices of selected layers
                biases = [int(float(b)) for b in bias_list[layer_idx]]  # Get biases for each layer
                remainder = len(biases) % max_neurons_num
                padding_needed = (max_neurons_num - remainder) if remainder != 0 else 0

                if padding_needed > 0:
                    biases.extend([0] * padding_needed)

                all_biases.extend(biases)  # Flatten here

            max_len = max(len(bias_list[layer_idx]) for layer_idx in range(len(selected_layers)))
            padded_max = max_neurons_num * ((max_len + max_neurons_num - 1) // max_neurons_num)
            return all_biases, padded_max

        # Default case: pad each bias list to the longest, then flatten
        max_len = max(len(bias) for bias in bias_list) if bias_list else 0

        for biases in bias_list:
            biases = [int(float(val)) for val in biases]
            padded = biases + [0] * (max_len - len(biases))
            all_biases.extend(padded)  # Flatten here too

        return all_biases, max_len
                
    def get_layer_generics(self) -> list:
        layer_generics = []
        layers = self.onnx_dict.get("layers", [])
        if not layers:
            raise ValueError("Error: No layers found in the ONNX dictionary.")
        if self.onnx_dict["is_serialized"] is True:            
            if self.onnx_dict.get("serial_layers", 0) > 1:
                layer_reuses = self.onnx_dict.get("layer_reuses", [])
                for i in range(self.onnx_dict["serial_layers"]):
                    generics = {
                    "layer_number": layer_reuses[i],
                    "start_index" : help.cumulative_offsets(layer_reuses)[i]
                    }
                    layer_generics.append(generics)
            else:   
                generics = {
                "layer_number": self.get_total_layer_count()
                }
                layer_generics.append(generics)
#        else:
#            for _ in range(self.get_total_layer_count()):
#                layer_generics.append({})
        return layer_generics
        
    def get_bit_size_from_dtype(self, dtype: str) -> int:
        if dtype in self.dtype_bit_map:
            return self.dtype_bit_map[dtype]
        else:
            raise ValueError(f"Unsupported dtype: {dtype}")

    def get_bit_sizes(self) -> list:
        layers = self.onnx_dict.get("layers", [])
        if not layers:
            raise ValueError("No layers found in ONNX dictionary.")

        first_layer = layers[0]
        weights_dtype = first_layer.get("weights_dtype")
        biases_dtype = first_layer.get("biases_dtype")

        io_info = self.onnx_dict.get("inputs_outputs", {})
        input_dtype = io_info.get("inputs", [{}])[0].get("type")
        output_dtype = io_info.get("outputs", [{}])[0].get("type")
        w_bitwidth = self.get_bit_size_from_dtype(weights_dtype)
        b_bitwidth = self.get_bit_size_from_dtype(biases_dtype)
        i_bitwidth = self.get_bit_size_from_dtype(input_dtype)
        o_bitwidth = self.get_bit_size_from_dtype(output_dtype)
        if w_bitwidth == b_bitwidth:
            bitwidth = w_bitwidth
            return[bitwidth,i_bitwidth,o_bitwidth]
        else:
            print("Error: Bitwidths must be the same. w_bitwidth: {}, b_bitwidth: {}".format(w_bitwidth, b_bitwidth))
            sys.exit(1) 

    def get_layer_io_bitwidths(self, layer: dict) -> tuple:
        io_info = self.onnx_dict.get("inputs_outputs", {})
        input_tensors = layer.get("layer_inputs", [])
        output_tensors = layer.get("layer_outputs", [])

        # Assume first input/output names are the ones to check
        input_type = None
        output_type = None

        for inp in input_tensors:
            for io in io_info.get("inputs", []):
                if io.get("name") == inp:
                    input_type = io.get("type")
                    break

        for out in output_tensors:
            for io in io_info.get("outputs", []):
                if io.get("name") == out:
                    output_type = io.get("type")
                    break

        if input_type is None or output_type is None:
            raise ValueError(f"Could not resolve input/output types for layer: {layer.get('layer_name')}")

        i_bitwidth = self.get_bit_size_from_dtype(input_type)
        o_bitwidth = self.get_bit_size_from_dtype(output_type)

        return i_bitwidth, o_bitwidth


    def get_data_widths(self) -> list:
        data_widths = []
        layers = self.onnx_dict.get("layers", [])
        if not layers:
            raise ValueError("Error: No layers found in the ONNX dictionary.")
        data_widths.append(layers[0]["layer_inputs"])
        for layer in layers:
            data_widths.append(layer["layer_outputs"])        
        return data_widths

    def get_layer_input_widths(self) -> list:
        input_widths = []
        layers = self.onnx_dict.get("layers", [])
        if not layers:
            raise ValueError("Error: No layers found in the ONNX dictionary.")
        for layer in layers:
            input_widths.append(layer["layer_inputs"])        
        return input_widths

    def get_neuron_per_layer(self) -> list:
        neurons_per_layer = []
        layers = self.onnx_dict.get("layers", [])
        if not layers:
            raise ValueError("Error: No layers found in the ONNX dictionary.")
        for layer in layers:
            neurons_per_layer.append(layer["layer_outputs"])        
        return neurons_per_layer
   
    def check_binarize(self):
        activation_functions = {"Sigmoid", "Tanh", "ReLU", "LeakyReLU", 'Softmax', 'ThresholdedRelu'}  
        first_node = self.onnx_dict.get("node_0")
        second_node = self.onnx_dict.get("node_1")
        binarize = first_node in activation_functions or second_node in activation_functions
        return binarize
    
    def create_NN_model_dict(self):
        NN_dict={}
        data_widths = self.get_data_widths()
        NN_dict["is_serialized"] = self.onnx_dict["is_serialized"]
        NN_dict["network_name"] = "neural_network"
        if NN_dict["is_serialized"] is True :
            NN_dict["layer_count"] = self.onnx_dict["serial_layers"]
        else:
            NN_dict["layer_count"] = self.get_total_layer_count()
        NN_dict["layer_names"] = self.get_layer_names()
        if NN_dict["is_serialized"] is True :
            NN_dict["layer_names"] = [name + "_serial" for name in NN_dict["layer_names"]]
        NN_dict["layer_generics"] = self.get_layer_generics()
        NN_dict["input_width"] = data_widths[0]
        NN_dict["output_width"] = data_widths[-1]
        NN_dict["layer_output_widths"] = data_widths[1:]
        NN_dict["weight_file"] = self.onnx_dict["weight_file"]
        NN_dict["t_bitwidth"] = 8     # Chosen by me. Later i can include it in Hyper M file
        NN_dict["handshake"] = self.onnx_dict["handshake"]  # Chosen by me. Later i can include it in Hyper M file (It makes the layers tell the other layers their output is done)
        return NN_dict

    def create_layers_dict(self):
        weight_indexes = self.get_weight_indexes()
        layer_names = self.get_layer_names()
        neurons = self.get_neuron_per_layer()
        input_widths = self.get_layer_input_widths()
        data_widths = self.get_data_widths()
        bias_indexes= self.get_bias_indexes()
        bit_sizes = self.get_bit_sizes()
        

        count = 0
        neuron_count = 0
        if self.onnx_dict["is_serialized"] is True:
            layer_reuses = self.onnx_dict.get("layer_reuses", [])
            if layer_reuses == "max":
                layer_reuses = [self.onnx_dict["num_layers"]]
            layers_dict = [{} for _ in range(len(layer_reuses))]
            for i in range(len(layer_reuses)):
                layers_to_check = layer_reuses[i]
                layers_dict[i]["is_serialized"] = True
                layers_dict[i]["layer_reuses"] = layer_reuses
                layers_dict[i]["layer_number"] = layers_to_check
                layers_dict[i]["layer_name"] = layer_names[i] + "_serial"
                layers_dict[i]["layer_idx"] = i                          # entry added just for the TopModel class and generation
                layers_dict[i]["handshake"] = self.onnx_dict["handshake"]  # Chosen by me. Later i can include it in Hyper M file (It makes the layers tell the other layers their output is done)
                if i == 0 :
                    layers_dict[i]["first_layer"] = True
                else:
                    layers_dict[i]["first_layer"] = False
                layers_dict[i]["weight_file"] = self.onnx_dict["weight_file"]
                layers_dict[i]["max_data_width"] = max(input_widths[count : count + layers_to_check])
                layers_dict[i]["bias_indexes"] = bias_indexes[i]
                layers_dict[i]["data_widths"] = data_widths[count : count +layers_to_check+1]
                layers_dict[i]["max_neuron_number"] = max(neurons[count : count + layers_to_check])
                self.max_neuron_mem.append(layers_dict[i]["max_neuron_number"])
                self.neuron_sum_mem.append( sum(neurons[count : count + layers_to_check]))
                layers_dict[i]["out_neuron_number"] = neurons[count + layers_to_check -1]
                layers_dict[i]["other_neurons"] = layers_dict[i]["max_neuron_number"] -   layers_dict[i]["out_neuron_number"]


                
                if i == len(layer_reuses) - 1:
                    if bit_sizes[2] > 1:
                        layers_dict[i]["full_output"] = True
                    else:
                        layers_dict[i]["full_output"] = False
                else:
                        layers_dict[i]["full_output"] = False
                layers_dict[i]["neur_idx"] = neuron_count        
                if self.onnx_dict["serialized_neurons"][i] == "max" :
                    layers_dict[i]["less_neurons"] = False
                    layers_dict[i]["range_max"] = layers_dict[i]["max_neuron_number"] * layers_to_check 
                    if layers_to_check == 1:
                        self.max_width_mem.append(layers_dict[i]["max_data_width"])
                        if layers_dict[i]["full_output"] == True:
                            self.neuron_attitudes.append(False)
                            layers_dict[i]["output_bit"] = False
                            layers_dict[i]["output_f"] = True
                        else:
                            self.neuron_attitudes.append(True)
                            layers_dict[i]["output_bit"] = True
                            layers_dict[i]["output_f"] = False
                        self.full_output_mem.append(layers_dict[i]["full_output"])
                        self.fixed_neur_mem.append(0)
                        self.current_neurons.append(layers_dict[i]["max_neuron_number"])
                        layers_dict[i]["one_layer"] = True       #To be used inside layer model   
                        layers_dict[i]["use_two"] = False        #To only be used in the topModel class
                        self.one_layer_mem.append(True) 
                        self.layer_max_counter += 1 
                        neuron_count += 1
                    else:
                        self.max_width_mem.append(layers_dict[i]["max_data_width"])
                        self.full_output_mem.append(layers_dict[i]["full_output"])
                        self.fixed_neur_mem.append(0)
                        self.one_layer_mem.append(False)
                        self.current_neurons.append(layers_dict[i]["max_neuron_number"])
                        if layers_dict[i]["full_output"] == True :
                            self.max_width_mem.append(layers_dict[i]["max_data_width"])
                            self.neuron_attitudes.append(False)
                            self.neuron_attitudes.append(True)
                            self.full_output_mem.append(layers_dict[i]["full_output"])
                            self.one_layer_mem.append(False)
                            self.current_neurons.append(layers_dict[i]["max_neuron_number"])
                            layers_dict[i]["output_bit"] = True
                            layers_dict[i]["output_f"] = True
                            neuron_count += 2
                            layers_dict[i]["one_layer"] = False
                            layers_dict[i]["use_two"] = True
                            self.fixed_neur_mem.append(0)
                        else:
                            self.neuron_attitudes.append(True)
                            layers_dict[i]["output_bit"] = True
                            layers_dict[i]["output_f"] = False
                            neuron_count += 1
                            layers_dict[i]["one_layer"] = False
                            self.layer_max_counter += 1 
                            layers_dict[i]["use_two"] = False
                     
                    if "true_serial_neurons" not in self.onnx_dict:
                        self.onnx_dict["true_serial_neurons"] = {}
                    self.onnx_dict["true_serial_neurons"][i] = layers_dict[i]["max_neuron_number"]   # dummy entry, to be used just for dictionary creation
                else:
                    layers_dict[i]["less_neurons"] = True   
                    layers_dict[i]["fixed_neurons_num"] = self.onnx_dict["serialized_neurons"][i]
                    range_max = 0
                    for j in range(count, count + layers_to_check):
                        if neurons[j] % layers_dict[i]["fixed_neurons_num"] == 0:
                            range_max += (neurons[j] // layers_dict[i]["fixed_neurons_num"]) * layers_dict[i]["fixed_neurons_num"] 
                        else:
                            range_max += (neurons[j] // layers_dict[i]["fixed_neurons_num"] + 1) * layers_dict[i]["fixed_neurons_num"] 
                    layers_dict[i]["range_max"] = range_max
                    chosen_layers = []
                    max_overflow_steps = 0
                    for j,neurs in enumerate(neurons[count : count + layers_to_check]):
                        full_chunks = neurs // layers_dict[i]["fixed_neurons_num"]    
                        remainder = neurs % layers_dict[i]["fixed_neurons_num"]
                        layer_steps = []
                        for chunk in range(full_chunks):
                            start_bit = layers_dict[i]["max_neuron_number"] - layers_dict[i]["fixed_neurons_num"] * (chunk + 1)
                            end_bit = layers_dict[i]["max_neuron_number"] - layers_dict[i]["fixed_neurons_num"] * chunk - 1
                            layer_steps.append({
                                "start_bit": start_bit,
                                "end_bit": end_bit,
                                "slice_type": "full"
                            })
                        if remainder > 0:
                            end_bit = layers_dict[i]["max_neuron_number"] - layers_dict[i]["fixed_neurons_num"] * full_chunks - 1
                            start_bit = end_bit - remainder + 1
                            layer_steps.append({
                                "start_bit": start_bit,
                                "end_bit": end_bit,
                                "slice_type": "partial",
                                "partial_range": (layers_dict[i]["fixed_neurons_num"] - 1, layers_dict[i]["fixed_neurons_num"] - remainder)
                            })
                        chosen_layers.append(layer_steps)
                        if len(layer_steps) > max_overflow_steps:
                            max_overflow_steps = len(layer_steps)

                    layers_dict[i]["chosen_layers"] = chosen_layers 
                    layers_dict[i]["last_repeats"] = layers_dict[i]["out_neuron_number"] // layers_dict[i]["fixed_neurons_num"]
                    layers_dict[i]["last_remainder"] = layers_dict[i]["out_neuron_number"] % layers_dict[i]["fixed_neurons_num"]
                    if layers_dict[i]["full_output"]:
                        last_layer_steps = layers_dict[i]["last_repeats"] + (1 if layers_dict[i]["last_remainder"]  > 0 else 0)
                        if last_layer_steps > max_overflow_steps:
                            max_overflow_steps = last_layer_steps
                    layers_dict[i]["max_overflow_count"] = max_overflow_steps
                    self.fixed_neur_mem.append(layers_dict[i]["fixed_neurons_num"])
                    self.max_width_mem.append(layers_dict[i]["max_data_width"])
                    if layers_to_check == 1:
                        if layers_dict[i]["full_output"] == True:
                            self.neuron_attitudes.append(True)
                            layers_dict[i]["output_bit"] = False
                            layers_dict[i]["output_f"] = True
                        else:
                            self.neuron_attitudes.append(True)
                            layers_dict[i]["output_bit"] = True
                            layers_dict[i]["output_f"] = False
                        self.full_output_mem.append(layers_dict[i]["full_output"])
                        layers_dict[i]["one_layer"] = True
                        layers_dict[i]["use_two"] = False
                        self.one_layer_mem.append(True)
                        self.current_neurons.append(layers_dict[i]["fixed_neurons_num"])
                        self.layer_max_counter += 1 
                        neuron_count += 1
                    elif layers_dict[i]["full_output"] == True:
                        self.neuron_attitudes.append(False)
                        self.full_output_mem.append(layers_dict[i]["full_output"])
                        self.one_layer_mem.append(False)
                        layers_dict[i]["output_bit"] = True
                        layers_dict[i]["output_f"] = True                        
                        neuron_count += 1
                        self.layer_max_counter += 1 
                        layers_dict[i]["one_layer"] = False
                        self.current_neurons.append(layers_dict[i]["fixed_neurons_num"])
                        layers_dict[i]["use_two"] = False    
                    else:
                        self.neuron_attitudes.append(True)
                        self.full_output_mem.append(layers_dict[i]["full_output"])
                        self.current_neurons.append(layers_dict[i]["fixed_neurons_num"])
                        self.one_layer_mem.append(False)
                        neuron_count += 1
                        self.layer_max_counter += 1
                        layers_dict[i]["output_bit"] = True
                        layers_dict[i]["output_f"] = False
                        layers_dict[i]["one_layer"] = False
                        layers_dict[i]["use_two"] = False

                count = count + layers_to_check 
        else:
            layers = self.onnx_dict.get("layers", [])
            if not layers:
                raise ValueError("Error: No layers found in the ONNX dictionary.")
            layers_dict = [{} for _ in range(len(layers))]
            count = 0 
            for idx, _ in enumerate(layers):
                layers_dict[idx]["layer_name"] = re.sub(r'_\d+$', '', layer_names[idx])
                layers_dict[idx]["layer_idx"] = idx
                if idx == len(layers) - 1:
                    layers_dict[idx]["last_layer"] = True
                else:
                    layers_dict[idx]["last_layer"] = False
                if idx == 0 :
                    layers_dict[idx]["first_layer"] = True
                else:
                    layers_dict[idx]["first_layer"] = False
                layers_dict[idx]["input_width"] = input_widths[idx]
                layers_dict[idx]["data_width"] = data_widths[idx]
                layers_dict[idx]["output_width"] = neurons[idx]
                if idx == len(layers) - 1:
                    if bit_sizes[2] > 1:
                        layers_dict[idx]["full_output"] = True
                    else:
                        layers_dict[idx]["full_output"] = False       
                else:
                        layers_dict[idx]["full_output"] = False      
                layers_dict[idx]["different_files"] = self.onnx_dict["different_files"]
                if layers_dict[idx]["different_files"] is True:
                    layers_dict[idx]["neuron_count"] = neurons[idx]   # entry added just for the TopModel class
                    layers_dict[idx]["neuron_idx"] = bias_indexes[idx]   
                else:
                    layers_dict[idx]["neuron_count"] = 1              # entry added just for the TopModel class
                w_count = neurons[idx]        
                neuron_pairs = list(zip(range(bias_indexes[idx], bias_indexes[idx] + neurons[idx]), range(neurons[idx])))
                layers_dict[idx]["neurons_idx"] = neurons[idx]        # Just for reversing
                layers_dict[idx]["start_weights"] = weight_indexes[count : count + w_count]
                layers_dict[idx]["bias_indexes"] = bias_indexes[idx]
                layers_dict[idx]["weight_file"] = self.onnx_dict["weight_file"]
                layers_dict[idx]["num_stages"] = help.calculate_num_stages(data_widths[idx])
                layers_dict[idx]["is_serialized"] = False
                layers_dict[idx]["neuron_pairs"] = neuron_pairs
                layers_dict[idx]["handshake"] = self.onnx_dict["handshake"]
                count += w_count
        return layers_dict

    def create_neurons_dict(self):
        neurons = self.get_neuron_per_layer()
        bit_sizes = self.get_bit_sizes()
        input_widths = self.get_layer_input_widths()
        if self.onnx_dict["is_serialized"] is True:
            layer_reuses = self.onnx_dict["layer_reuses"]
            if layer_reuses == "max":
                layer_reuses = [self.onnx_dict["num_layers"]]
            neurons_dict = [{} for _ in range(2*len(layer_reuses) - self.layer_max_counter)]
            for i in range(2*len(layer_reuses) - self.layer_max_counter):
                neurons_dict[i]["name"] = "neuron"
                neurons_dict[i]["neur_idx"] = i
                neurons_dict[i]["neuron_number"] = self.current_neurons[i] - 1
                neurons_dict[i]["is_serialized"] = True
                neurons_dict[i]["different_files"] = False
                neurons_dict[i]["weight_file"] = self.onnx_dict["weight_file"]
                neurons_dict[i]["full_output"] = self.full_output_mem[i]
                neurons_dict[i]["last_layer"] = False
                neurons_dict[i]["w_bitwidth"] = bit_sizes[0]
                neurons_dict[i]["o_bitwidth"] = bit_sizes[2]
                neurons_dict[i]["activation"] = "threshold"
                neurons_dict[i]["sum_logic"] = self.onnx_dict["sum_logic"]
                neurons_dict[i]["weight_logic"] = "no_loop"
                neurons_dict[i]["num_stages"] = help.calculate_num_stages(self.max_width_mem[i])
                neurons_dict[i]["handshake"] = self.onnx_dict["handshake"]
                neurons_dict[i]["other_neuron"] = self.neuron_attitudes[i]
                neurons_dict[i]["one_layer"] = self.one_layer_mem[i]

        elif self.onnx_dict["different_files"] is True:
            neuron_sum = sum(neurons)
            neurons_dict = [{} for _ in range(neuron_sum)]
            layer_idx = 0
            layer_neuron_counter = 0  # How many neurons assigned for current layer
            layer_neuron_target = neurons[layer_idx] 
            for i in range(neuron_sum):
                neurons_dict[i]["name"] = "neuron"
                neurons_dict[i]["neur_idx"] = i
                neurons_dict[i]["is_serialized"] = False
                neurons_dict[i]["different_files"] = True
                neurons_dict[i]["weight_file"] = self.onnx_dict["weight_file"]
                if i >= neuron_sum - neurons[-1] :
                    neurons_dict[i]["last_layer"] = True
                    if bit_sizes[2] > 1:
                        neurons_dict[i]["full_output"] = True
                    else:
                        neurons_dict[i]["full_output"] = False
                else:
                    neurons_dict[i]["last_layer"] = False
                    neurons_dict[i]["full_output"] = False
                neurons_dict[i]["w_bitwidth"] = bit_sizes[0]
                neurons_dict[i]["o_bitwidth"] = bit_sizes[2]
                neurons_dict[i]["activation"] = "threshold"
                neurons_dict[i]["sum_logic"] = self.onnx_dict["sum_logic"]
                neurons_dict[i]["weight_logic"] = "no_loop"
                neurons_dict[i]["num_stages"] = help.calculate_num_stages(input_widths[layer_idx])
                neurons_dict[i]["handshake"] = self.onnx_dict["handshake"]
                layer_neuron_counter += 1
                if layer_neuron_counter == layer_neuron_target:
                    layer_idx += 1
                    if layer_idx < len(neurons):
                        layer_neuron_target += neurons[layer_idx]
                        layer_neuron_counter = 0
        else:
            layers = self.onnx_dict.get("layers", [])
            if not layers:
                raise ValueError("Error: No layers found in the ONNX dictionary.")
            neurons_dict = [{} for _ in range(len(layers))]
            for idx, _ in enumerate(layers):
                neurons_dict[idx]["name"] = "neuron"
                neurons_dict[idx]["neur_idx"] = idx
                neurons_dict[idx]["is_serialized"] = False
                neurons_dict[idx]["different_files"] = False
                neurons_dict[idx]["weight_file"] = self.onnx_dict["weight_file"]
                if idx == len(layers) - 1:
                    neurons_dict[idx]["last_layer"] = True
                    if bit_sizes[2] > 1:
                        neurons_dict[idx]["full_output"] = True
                    else:
                        neurons_dict[idx]["full_output"] = False
                else:
                    neurons_dict[idx]["last_layer"] = False
                    neurons_dict[idx]["full_output"] = False
                neurons_dict[idx]["w_bitwidth"] = bit_sizes[0]
                neurons_dict[idx]["o_bitwidth"] = bit_sizes[2]
                neurons_dict[idx]["handshake"] = self.onnx_dict["handshake"]
                neurons_dict[idx]["activation"] = "threshold"
                neurons_dict[idx]["sum_logic"] = self.onnx_dict["sum_logic"]
                neurons_dict[idx]["weight_logic"] = "no_loop"
                neurons_dict[idx]["num_stages"] = help.calculate_num_stages(input_widths[idx])

        return neurons_dict
    
    def create_iloader_dict(self):
        loader_dict = {}
        input_width = self.get_layer_input_widths()[0]
        input_size = self.get_bit_sizes()[1]
        loader_dict["templates_dir"] = self.templates_dir
        loader_dict["t_bitwidth"] = 8   # This might be provided in input by the user and it depends on the memory and on the bus available in hardware   
        loader_dict["input_width"] = input_width  # This is how many inputs the network has
        loader_dict["input_size"] = 8    # input_size as bitwidth # This can be ultimately decided by the user, as it is now, it takes the one from ONNX (in fact i changed now its manual)
        loader_dict["THRESHOLD"] = int(2**8/2)
        if input_size > 1:
            loader_dict["binarize"] = True      # Maybe change it to be always true
        else:
            loader_dict["binarize"] = False
        return loader_dict

################ Method that handles the creation of the dictionary for the VHDL type and constants file #################################

    def create_pkg_dict(self):
        pkg_dict = {}
        output_size = self.get_bit_sizes()[-1]
        weight_size = self.get_bit_sizes()[0]
        input_size = self.get_bit_sizes()[1]
        data_widths= self.get_data_widths()
        neurons = self.get_neuron_per_layer()
        pkg_dict["file_bitwidth"] = 8            # Bitwidth of values stored in file, it is different from the one stated in the ONNX model
        pkg_dict["o_bitwidth"] = output_size
        pkg_dict["w_bitwidth"] = weight_size
        pkg_dict["i_bitwidth"] = input_size
        if self.onnx_dict["is_serialized"] is True:
            layer_reuses = self.onnx_dict.get("layer_reuses", [])

  #          pkg_dict["bias_per_layer"] = help.generate_layer_offsets(max_len, self.onnx_dict["num_layers"])            
            pkg_dict["data_widths"] = data_widths
            pkg_dict["is_serialized"] = True
            pkg_dict["indexes_per_layer"] = [0] + data_widths[1:-1]
            if layer_reuses == "max":
                layer_reuses = [self.onnx_dict["num_layers"]]
            
            config_dict = [{} for _ in range(len(layer_reuses))]
            rem_array = []
            repeat_length = []
            offset = 0

            for i in range(len(layer_reuses)):
                count = layer_reuses[i]
                if self.onnx_dict["serialized_neurons"][i] == "max":
                    config_dict[i]["less_neurons"] = False
                else:
                    config_dict[i]["less_neurons"] = True 
                selected_layers = list(range(offset, offset + count))
                config_dict[i]["max_width"] = self.max_width_mem[i]
                if config_dict[i]["less_neurons"] == True:
                    sum = 0
                    for j in range(offset, offset + count):
                        if neurons[j] % self.fixed_neur_mem[i] == 0:
                            sum += (neurons[j] // self.fixed_neur_mem[i]) * self.fixed_neur_mem[i]
                        else:
                            sum += (neurons[j] // self.fixed_neur_mem[i] + 1) * self.fixed_neur_mem[i]
                    config_dict[i]["max_neurons"] = sum
                    generated_rows = self.get_padded_weight_columns(selected_layers, self.fixed_neur_mem[i], True ) 
                    flattened_array = [val for row in generated_rows for val in row]
                    config_dict[i]["generated_rows"] = flattened_array


                    config_dict[i]["bias_array"],_ = self.get_padded_biases(selected_layers, self.fixed_neur_mem[i], True)
                else:
                    config_dict[i]["max_neurons"] = self.max_neuron_mem[i] * len(selected_layers)
                    generated_rows = self.get_padded_weight_columns(selected_layers, self.max_neuron_mem[i], False)
                
                    flattened_array = [val for row in generated_rows for val in row]
                    config_dict[i]["generated_rows"] = flattened_array
                    config_dict[i]["bias_array"],_ = self.get_padded_biases(selected_layers, self.max_neuron_mem[i], False)
                config_dict[i]["weights_idx"] = self.get_weight_costants(config_dict[i]["max_width"], config_dict[i]["max_neurons"])    
                if config_dict[i]["less_neurons"] == True :
                    divider =  self.onnx_dict["serialized_neurons"][i]
                else:
                    divider = self.onnx_dict["true_serial_neurons"][i]
                for layer_idx in selected_layers:
                    num_neurons = self.onnx_dict["layers"][layer_idx]["layer_outputs"]
                    repeat_length.append(num_neurons // divider)
                    rem_array.append(num_neurons % divider)
                offset += count
            pkg_dict["config_dict"] = config_dict
   
            if all(not conf["less_neurons"] for conf in config_dict):
                pkg_dict["less_neurons"] = False
            else:
                pkg_dict["less_neurons"] = True
                pkg_dict["repeat_length"] = repeat_length
                pkg_dict["rem_array"] = rem_array
        else:
            pkg_dict["weights"] = self.get_all_weight_columns_flattened()
            pkg_dict["biases"] = self.get_flattened_biases()
            pkg_dict["is_serialized"] = False
        return pkg_dict
    
##########  Modify the parameters in here to change values of memory addresses in the process_controller   ###########

    def create_process_conrtoller_dict(self):
        pc_dict = {}
        data_widths = self.get_data_widths()
        pc_dict["handshake"] = self.onnx_dict["handshake"]
        pc_dict["output_neurons"] = self.get_neuron_per_layer()[-1]
        pc_dict["file_bitwidth"] = 8  # Always a power of 2
        pc_dict["counter_max"] = 30
        pc_dict["start_input"] = 0
        pc_dict["end_input"] = pc_dict["start_input"] + int(data_widths[0] / (32 / pc_dict["file_bitwidth"])) - 1 
        pc_dict["start_output"] = 25344
        pc_dict["end_output"] = pc_dict["start_output"] + data_widths[-1] - 1 
        return pc_dict


    def creat_top_level_dict(self):
        top_dict = {}
        top_dict["handshake"] = self.onnx_dict["handshake"]
        top_dict["output_neurons"] = self.get_neuron_per_layer()[-1]
        return top_dict

###########  Helps in creating a testbench for the starting net #############
#     
    def create_TB_dict(self):
        TB_dict ={}
        TB_dict["input_values"] = [255, 0, 0, 255, 255, 255, 0, 0, 255, 0, 0, 0, 0, 255, 0, 0, 255, 255, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 0, 255, 0, 255, 0, 0, 0, 255, 0, 255, 0, 0, 0, 255, 255, 255, 0, 0, 255, 0, 255, 255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 0, 255, 0, 0, 255]
        return TB_dict


def main():
    #Modify this to produce new networks 
    output_dir = input("Please enter the desired output directory name (default is 'New_network'): ") or "New_network" # Remember this is inside the result folder
    onnx_file_name = "dense_bam_8x8_trained.onnx"   # Here it accepts the Modify the name of the ONNX file to load 
    manager = Manager(onnx_file_name, output_dir) 


    neural_network= manager.create_NN_model_dict()
    layers = manager.create_layers_dict()
    neurons = manager.create_neurons_dict()
    i_loader = manager.create_iloader_dict()
    testbench = manager.create_TB_dict()
    pkg = manager.create_pkg_dict()
    proc_controller = manager.create_process_conrtoller_dict()
    top_level = manager.creat_top_level_dict()


    TopModel(neural_network, layers, neurons, manager.templates_dir, manager.final_dir)
    LoaderModel(i_loader, manager.templates_dir, manager.final_dir)
    PkgModel(pkg, manager.templates_dir, manager.final_dir) 
    TestBenchModel(testbench, manager.templates_dir, manager.final_dir) 
    ControllerModel(proc_controller, manager.templates_dir, manager.final_dir)
    MaxModel(top_level, manager.templates_dir, manager.final_dir)

if __name__ == "__main__":
    main()