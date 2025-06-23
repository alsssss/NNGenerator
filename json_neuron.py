import json

def modify_json(json_filename, name=None, inputs=None, activation=None, bias=None):
    """
    Args:
        json_filename (str): The name of the JSON file.
        name (str, optional): Name of the neuron.
        inputs (int, optional): Number of inputs to the neuron.
        activation (str, optional): Activation function (relu, sigmoid, linear).
        bias (bool, optional): Whether the neuron has a bias term.
    """

    # Load existing JSON file if it exists, otherwise start with default values
    try:
        with open(json_filename, 'r') as file:
            data = json.load(file)
    except FileNotFoundError:
        print(f"File {json_filename} not found. Creating a new JSON file.")
        data = {"neuron": {}}

    # Update fields only if new values are provided
    if name is not None:
        data["neuron"]["name"] = name
    if inputs is not None:
        data["neuron"]["inputs"] = inputs
    if activation is not None:
        data["neuron"]["activation"] = activation
    if bias is not None:
        data["neuron"]["bias"] = bias

    # Save the modified JSON back to file
    with open(json_filename, 'w') as file:
        json.dump(data, file, indent=4)

    print(f"JSON file {json_filename} updated successfully!")

# Data to be written to the JSON file
data = {
    "neuron": {
        "name": "Michela_neuron",
        "inputs": 4,
        "activation": "threshold",
        "bias": True
    }
}

# Specify the file name
filename = "neuron_config.json"

# Open the file in write mode and write the JSON data
with open(filename, 'w') as json_file:
    json.dump(data, json_file, indent=4)  # 'indent=4' makes the output pretty

print(f"JSON file {filename} created successfully!")