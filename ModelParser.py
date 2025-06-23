import onnx
import json
import yaml
import numpy as np
from onnx import numpy_helper
from onnx import shape_inference

class ModelParser:
    def __init__(self, model_dir, model_file):
        self.dir = model_dir
        self.file = model_file
        self.model={}

    
    def parser(self):
        # Dictionary to store the network information
        network_details = {}
        NN_model={}
        # Load the ONNX model
        model = onnx.load(self.dir + "\\" + self.file)
        model = onnx.shape_inference.infer_shapes(model)

        # Extract graph nodes and initializers
        nodes = model.graph.node
        initializers = {init.name: onnx.numpy_helper.to_array(init) for init in model.graph.initializer}

        input_to_nodes = {}
        for node in nodes:
            for input_name in node.input:
                if input_name not in input_to_nodes:
                    input_to_nodes[input_name] = []
                input_to_nodes[input_name].append(node)
        
        # List of all layers (Gemm and MatMul are typically used for Dense layers)
        layers = [node for node in nodes if node.op_type == 'Gemm' or node.op_type == 'MatMul']

        # Store number of layers in the dictionary
        network_details["num_layers"] = len(layers)

        # Store details of each layer
        layer_details = []
        used_biases = set()
        for i, layer in enumerate(layers):
            layer_info = {}

            layer_info["layer_idx"] = i
            layer_info["layer_name"] = layer.name if layer.name else 'Unnamed'
    
            # Get weights and biases
            weight_name = layer.input[1]
            bias_name = layer.input[2] if len(layer.input) > 2 else None

            weights = initializers.get(weight_name, None)

            if bias_name:
                biases = initializers.get(bias_name, None)
                if bias_name:
                    used_biases.add(bias_name)
            else:
                biases = None

                for name in initializers:
                    if "bias" in name and name not in used_biases:  # Look for bias-related names
                        biases = initializers[name]
                        bias_name = name
                        used_biases.add(name)
                        break

            # Store input and output neurons' dimensions
            if weights is not None:
                input_dim, output_dim = weights.shape
                layer_info["layer_inputs"] = input_dim
                layer_info["layer_outputs"] = output_dim
            else:
                layer_info["input_neurons"] = None
                layer_info["output_neurons"] = None

            if biases is not None:
                layer_info["biases_per_neuron"] = len(biases)
            else:
                layer_info["biases_per_neuron"] = None

            # Store weights in a matrix form (2D array)
            if weights is not None:
                layer_info["weights_matrix"] = weights.tolist()  # Convert the numpy array to a Python list
                layer_info["weights_dtype"] = str(weights.dtype)
            else:
                layer_info["weights_matrix"] = None

            # Store biases in a list
            if biases is not None:
                layer_info["biases"] = [{"neuron_idx": idx, "bias_value": b} for idx, b in enumerate(biases.tolist())]
                layer_info["biases_dtype"] = str(biases.dtype)
            else:
                layer_info["biases"] = None

            activation_function = self.find_activation_function(layer.output[0], input_to_nodes)
            layer_info["activation_function"] = activation_function if activation_function else "None"

            # Add layer details to the list
            layer_details.append(layer_info)

        # Add layer details to the network dictionary
        network_details["layers"] = layer_details

        # Extra info for model inputs and outputs
        input_output_info = {
            "inputs": [],
            "outputs": []
        }

        for inp in model.graph.input:
            shape = [dim.dim_value for dim in inp.type.tensor_type.shape.dim]
            dtype = onnx.helper.tensor_dtype_to_np_dtype(inp.type.tensor_type.elem_type)
            input_output_info["inputs"].append({"input_name": inp.name, "shape": shape, "type":str(dtype)})

        for out in model.graph.output:
            shape = [dim.dim_value for dim in out.type.tensor_type.shape.dim]
            dtype = onnx.helper.tensor_dtype_to_np_dtype(out.type.tensor_type.elem_type)
            input_output_info["outputs"].append({"output_name": out.name, "shape": shape, "type":str(dtype)})
            
        network_details["inputs_outputs"] = input_output_info

        with open('network_details.json', 'w') as json_file:
            json.dump(network_details, json_file, indent=4)
        
        counter=1
        np.set_printoptions(precision=1, formatter={'float_kind':'{:0.1f}'.format})
        NN_model["layer_quantity"] = len(layers)
        for layer in network_details["layers"]:
            layer_key = "layer_" + str(counter)
            weight_key = "w_matrix_" + str(counter)
            bias_key = "b_array_" + str(counter)
            activation_key = "activation_function_" + str(counter)
            NN_model[layer_key] = {"layer_idx": counter, "layer_name":layer['layer_name']}

            if layer["weights_matrix"]:
                 NN_model[layer_key][weight_key] = {'Values' :np.matrix(layer["weights_matrix"]).tolist(), 'type': layer['weights_dtype']}
            else:
                NN_model[layer_key][weight_key] = 0
            if layer["biases"]:
                NN_model[layer_key][bias_key] = {'Values' :np.array(layer["biases"]).tolist(), 'type': layer['biases_dtype']} 
            else:
                NN_model[layer_key][bias_key] = 0
            if layer["activation_function"]:
                NN_model[layer_key][activation_key] = layer["activation_function"]
            else:
                NN_model[layer_key][activation_key] = "None"
            counter += 1
        for i, node in enumerate(nodes):
            node_key="node_" + str(i)
            network_details[node_key]= node.op_type
        self.model=network_details
        with open('json_files/network_details.json', 'w') as json_file:
            json.dump(self.model, json_file, indent=4)



    def hyperM_function(self):
   
        with open('json_files/network_details.json', "r") as f:
                existing_data = json.load(f)

        with open('json_files/user_config.yaml', "r") as f:
                user_data = yaml.safe_load(f)

        merged = {**existing_data, **user_data}

        with open("json_files/network_details.json", "w") as f:
            json.dump(merged, f, indent=4)

        self.model=merged
        print(f"Data saved to {'json_files/network_details.json'}.")

    """ Uncomment the following code section to enable input from terminal

    def hyperM_function(self):
        hyper_prm = {}
        
        # Chice between serialized / fully-paraller network
        is_fully_parallel = input("Does the neural network need to be fully-parallel? [y/n]: ").strip().lower()
        hyper_prm["is_serialized"] = is_fully_parallel == "n"
        
        # Customize serialization
        if hyper_prm["is_serialized"]:
            layer_s = input("Enter how many layers to serialize [default = 1]: ").strip()
            layer_s = int(layer_s) if layer_s else 1  #  1 if empty
            if layer_s > self.model["num_layers"]:
                raise ValueError(f"Error: You can't use more layers than the ones you have in the model.")
            hyper_prm["serial_layers"] = layer_s
            if layer_s > 1 :
                layer_r = []
                neuron_s_list = []
                print("How many times do you need to reuse the same layer? [Press enter after each number you input]: \n")
                count=0
                while count < layer_s:
                    user_input = input().strip()
                    if user_input == "":
                        break  
                    try:
                        value = int(user_input)  
                        layer_r.append(value) 
                        count = count + 1
                    except ValueError:
                        print("Please enter a valid integer.")
                total = sum(layer_r)
                if total != self.model["num_layers"]:
                    raise ValueError(f"Error: You can't use more layers than the ones you have in the model.")
                else:
                    hyper_prm["layer_reuses"] = layer_r
                print("Neurons to serialize for each of the serialized layers [Press enter after each number you input] [Default = max]: \n")
                count=0
                while count < layer_s:
                    user_input = input().strip()  
                    try:
                        if user_input == "":
                            value="max"
                        else:
                            value = int(user_input)  
                        neuron_s_list.append(value) 
                        count = count + 1
                    except ValueError:
                        print("Please enter a valid integer.")
                count=0
                if all(isinstance(item, str) for item in neuron_s_list):
                    hyper_prm["serialized_neurons"] = neuron_s_list
                else:
                    for idx, value in enumerate(layer_r):
                        for i in range(count, count + value):
                            current_layer_dict = self.model["layers"][i]
                            if isinstance(neuron_s_list[idx], int):
                                if current_layer_dict["layer_outputs"] < neuron_s_list[idx]:
                                    raise ValueError(
                                        f"Value exceeds the number of neurons in layer {count}. "
                                        f"Please enter ≤ {current_layer_dict['layer_outputs']}."
                                    )
                        count += value
                    hyper_prm["serialized_neurons"] = neuron_s_list
            else: 
                hyper_prm["layer_reuses"] = "max"
                neuron_s = input("Neurons to serialize [Default = max]: ").strip() or ["max"]
                if neuron_s != ["max"]:
                    neuron_s = [int(neuron_s)]
                hyper_prm["serialized_neurons"] = neuron_s
            hyper_prm["different_files"] = None
        else :
        # Customize fully_parallel
             different_files = input("Do you want each neuron to have a separate file? [y/n]: ").strip().lower()
             hyper_prm["different_files"] = different_files == "y"
             hyper_prm["serial_layers"] = None
             hyper_prm["serialized_neurons"] = None
             hyper_prm["layer_reuses"] = None
        # Weight management preference
        weight_mode = input("Do you want weights and biases to be loaded from memory? [y/n]: ").strip().lower()
        hyper_prm["weight_file"] = weight_mode == 'n'
        # Load existing data and update it with new parameters
        try:
            with open('json_files/network_details.json', "r") as f:
                existing_data = json.load(f)
        except FileNotFoundError:
            existing_data = {}  # Initialize if file doesn't exist
        existing_data.update(hyper_prm)
        # Save updated data back to JSON file
        with open('json_files/network_details.json', "w") as f:
            json.dump(existing_data, f, indent=4)
        self.model=existing_data
        print(f"Data saved to {'json_files/network_details.json'}.")
    """
        

    def find_activation_function(self, tensor_name, input_to_nodes):
        # Follow nodes that consume the tensor_name
        visited = set()

        while tensor_name in input_to_nodes and tensor_name not in visited:
            visited.add(tensor_name)
            nodes = input_to_nodes[tensor_name]

            # Assume first node (typically safe)
            node = nodes[0]

            if node.op_type in ['Relu', 'Sigmoid', 'Tanh', 'Softmax', 'LeakyRelu', 'Elu', 'Selu', 'PRelu', 'ThresholdedRelu']:
                return node.op_type

            # If not an activation, follow its output
            if node.output:
                tensor_name = node.output[0]
            else:
                break

        return None


# Create an instance of ModelParser with the directory and model file path
#model_dir = "C:\\Users\\lxmit\\Downloads\\Michela_Variale_Msc_Thesis\\python\\generation_files_MNIST"
#model_file = "dense_bam_8x8_trained.onnx"

# Instantiate the ModelParser class
#parser = ModelParser(model_dir, model_file)

# Parse the ONNX model and save the details to 'network_details.json'
#Neural_dict=parser.parser()
#parser.hyperM_function()
#parser.write_data(network_details)
