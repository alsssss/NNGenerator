import onnx
import numpy as np
from onnx import numpy_helper
from onnx import shape_inference

# Load the ONNX model
model = onnx.load('dense_bam_8x8_trained.onnx')

# Initialize the variable
n_input=0
n_output=0
weights = {}
biases = {}
num_neur = {}
layer_count = 0

# Infer shapes
inferred_model = shape_inference.infer_shapes(model)

# To obtain input and output dimension
for input in inferred_model.graph.input:
    print(f"Dimensioni dell'input {input.name}:")
    for dim in input.type.tensor_type.shape.dim:
        if dim.HasField("dim_value"):
            n_input=dim.dim_value
            print(n_input, end=", ")
        elif dim.HasField("dim_param"):
            print(dim.dim_param, end=", ")
        else:
            print("?", end=", ")
    print()

for output in inferred_model.graph.output:
    print(f"Dimensioni dell'output {output.name}:")
    for dim in output.type.tensor_type.shape.dim:
        if dim.HasField("dim_value"):
            n_output=dim.dim_value
            print(n_output, end=", ")
        elif dim.HasField("dim_param"):
            print(dim.dim_param, end=", ")
        else:
            print("?", end=", ")
    print()

# Initialize vectors for the weights of the first and second layer
first_layer_weights = None
second_layer_weights = None

# Count the layers
layer_count = 0

for initializer in model.graph.initializer:
    numpy_array = numpy_helper.to_array(initializer)
    # Multiply by 100 and round to the nearest integer - uncomment if the weights are not int
    #numpy_array = np.round(numpy_array * 100).astype(int)
    # Check if it's a weight based on the tensor size
    if numpy_array.ndim == 2:  # weights are generally of size 2 (input x output)
        layer_count += 1
        if layer_count == 1:
            first_layer_weights = numpy_array
        elif layer_count == 2:
            second_layer_weights = numpy_array
            break  # break the loop after finding the weights of the second layer
    elif numpy_array.ndim==1:
         biases[initializer.name] = numpy_array
         num_neur[initializer.name] = len(numpy_array)  # Store the number of neurons for each layer





import os

# Crea il file VHDL
with open("config.vhdl", "w") as file:
    file.write("library IEEE;\n")
    file.write("use IEEE.STD_LOGIC_1164.ALL;\n")
    file.write("use IEEE.NUMERIC_STD.ALL;\n\n")
    file.write("package CONFIG is\n\n")
    file.write("\t-- int Arrays with Constants\n")
    file.write("\ttype constIntArray is ARRAY (natural range <>) of signed(7 downto 0);\n")
    file.write("\ttype struttura is ARRAY (natural range <>) of integer;\n\n")
    file.write(f"\tconstant DATA_WIDTHS: struttura (2 downto 0) := ( {n_output},{num_neur['fc1.bias']},{n_input});\n")
    file.write(f"\tconstant networkStructure : struttura (1 downto 0) := ({num_neur['fc2.bias']}, {num_neur['fc1.bias']});\n")
    file.write("\tconstant connnectionRange : struttura (3 downto 0) := (data_widths(2)+data_widths(1)+data_widths(0),data_widths(1)+data_widths(0),data_widths(0),0);\n\n")
    file.write(f"\tconstant number_weights : natural := DATA_WIDTHS(0)*networkStructure(0) + DATA_WIDTHS(1)*networkStructure(1);\n\n")
    file.write("\tconstant weights : constIntArray (0 to number_weights-1) := (")
    
    count2=0
     # Scrivi i pesi del first layer
    file.write("\t\t-- First layer\n")
    for i in range(first_layer_weights.shape[1]):
        for j in range(first_layer_weights.shape[0]):
            weight = int(first_layer_weights[j,i])
           
            file.write(f"\t\tto_signed({weight}, 8),\n")
            count2+=1

    print(count2)
    count=0
    # Scrivi i pesi del secondo layer
    file.write("\t\t-- Second layer\n")
    for i in range(second_layer_weights.shape[1]):
        for j in range(second_layer_weights.shape[0]):
            weight = int(second_layer_weights[j,i])
            if i == second_layer_weights.shape[1] - 1 and j == second_layer_weights.shape[0] - 1:
                file.write(f"\t\tto_signed({weight}, 8));\n")
            else:
                file.write(f"\t\tto_signed({weight}, 8),\n")
            count+=1

    print(count)
    # Scrivi i bias del primo e del secondo layer
    file.write("\tconstant biases : constIntArray (0 to networkStructure(1)+networkStructure(0)-1) := (\n")
    # Scrivi i bias del primo layer
    file.write("\t\t-- Bias del primo layer\n")
    
    for i, bias in enumerate(biases['fc1.bias']):
        biasi=int(bias)
        file.write(f"\t\tto_signed({biasi}, 8),\n")
     # Scrivi i bias del secondo layer
    file.write("\t\t-- Bias del secondo layer\n")
    for i, bias in enumerate(biases['fc2.bias']):
        biasi=int(bias)
        if i == len(biases['fc2.bias']) - 1:
            file.write(f"\t\tto_signed({biasi}, 8));\n")
        else:
            file.write(f"\t\tto_signed({biasi}, 8),\n")
        

    

   # Definition of the type COORDINATES
    file.write("type COORDINATES is array (0 to networkStructure(0), 0 to networkStructure'length - 1) of natural;\n")

   
    # Position of the starting weight of neurons in each layer
    file.write("constant positions: COORDINATES:= (\n")

    for i in range(num_neur["fc1.bias"]+1):
        if i < num_neur["fc2.bias"]+1:
            if i == num_neur["fc2.bias"]:
                file.write(f"\t\t(data_widths(0)*{i},data_widths(0)*24+data_widths(1)*{i}));\n")
            else:
                file.write(f"\t\t(data_widths(0)*{i},data_widths(0)*24+data_widths(1)*{i}),\n")
        else:
            if i == num_neur["fc1.bias"]:
                file.write(f"\t\t(data_widths(0)*{i},0));\n")
            else:
                file.write(f"\t\t(data_widths(0)*{i},0),\n")

    file.write(f"\tconstant bias_index: struttura(1 downto 0):=({num_neur['fc1.bias']},0);\n") 
    file.write("\ttype matrix is array (natural range <>, natural range <>) of signed(7 downto 0);\n")
    file.write("end CONFIG;\n")
