import onnx
import pprint
import json
import sys
import numpy as np
from onnx import numpy_helper
from onnx import shape_inference

#"C:\\Users\\lxmit\\Downloads\\Michela_Variale_Msc_Thesis\\python\\generation_files_MNIST\\dense_bam_8x8_trained.onnx"

class ModelParser:
    def __init__(self, model_dir, model_file):
        self.dir = model_dir
        self.file = model_file

    
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

        for i, layer in enumerate(layers):
            layer_info = {}

            layer_info["layer_name"] = layer.name if layer.name else 'Unnamed'
    
            # Get weights and biases
            weight_name = layer.input[1]
            bias_name = layer.input[2] if len(layer.input) > 2 else None

            weights = initializers.get(weight_name, None)
            biases = initializers.get(bias_name, None)

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
            else:
                layer_info["weights_matrix"] = None

            # Store biases in a list
            if biases is not None:
                layer_info["biases"] = [{"neuron_idx": idx, "bias_value": b} for idx, b in enumerate(biases)]
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
            input_output_info["inputs"].append({"input_name": inp.name, "shape": shape})

        for out in model.graph.output:
            shape = [dim.dim_value for dim in out.type.tensor_type.shape.dim]
            input_output_info["outputs"].append({"output_name": out.name, "shape": shape})

        # Add input/output info to the dictionary
        network_details["inputs_outputs"] = input_output_info

        # Print the dictionary (optional, for debugging)
        #pprint.pprint(network_details)

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
            NN_model[layer_key] ={"layer_idx": counter, "layer_name":layer['layer_name']}
#            print(f"Layer: {layer['layer_name']}")
            if layer["weights_matrix"]:
                 NN_model[layer_key][weight_key] = np.matrix(layer["weights_matrix"])
#                 print(NN_model[layer_key][weight_key])
            else:
                NN_model[layer_key][weight_key] = 0
#                print("No weights matrix available")
            if layer["biases"]:
                NN_model[layer_key][bias_key] = np.array(layer["biases"])
#                print(NN_model[layer_key][bias_key])
            else:
                NN_model[layer_key][bias_key] = 0
#                print("No biases")
            if layer["activation_function"]:
                NN_model[layer_key][activation_key] = layer["activation_function"]
#                print(NN_model[layer_key][activation_key])
            else:
                NN_model[layer_key][activation_key] = "None"
#                print("No biases")
            

            counter += 1
        return (NN_model)
#        for node in model.graph.node:
#            print(node.op_type, node.name, node.input, node.output)
    #weights_matrix = network_details["layers"][0]["weights_matrix"]

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



model_dir = "C:\\Users\\lxmit\\Downloads\\Michela_Variale_Msc_Thesis\\python\\generation_files_MNIST"
model_file = "dense_bam_8x8_trained.onnx"

parser = ModelParser(model_dir, model_file)

Neural_dict=parser.parser()
print(Neural_dict)
#parser.write_data(network_details)
