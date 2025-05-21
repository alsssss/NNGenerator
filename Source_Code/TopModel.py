from jinja2 import Environment, FileSystemLoader
from LayerModel import LayerModel
import os

class TopModel:

    """ 
    This class receives the dictionaries for the neural nwtwork, the layers 
    and the neurons.
    It generates neural network vhdl files.
    Only the dictionaries for the layers and the neurons 
    are passed to the next class -> (LayerModel)
    It also receives the directory where templates are stored and the output 
    directory. 
    """

    def __init__(self, NN_dict, l_dict, n_dict, template_dir, final_dir):
        self.NN_dict = NN_dict
        self.l_dict = l_dict
        self.n_dict = n_dict
        template_file = "neural_network.vhd"
        output_file = self.NN_dict["network_name"] + ".vhd"
        self.generate_vhdl(template_dir, template_file, final_dir, output_file)
        self.generate_layers(template_dir, final_dir)

    def get_layers(self):
        if isinstance(self.l_dict, dict):
            layers = [layer for layer in self.l_dict.values() if isinstance(layer, dict)]
        elif isinstance(self.l_dict, list):
            layers = [layer for layer in self.l_dict if isinstance(layer, dict)]
        else:
            raise ValueError("Invalid layer format")
        return layers

    def get_neurons(self):
        layers = self.get_layers()
        neurons_by_layer = {}

        if isinstance(self.n_dict, list):
            neuron_cursor = 0  # tracks how many neurons we've consumed
            for idx, layer in enumerate(layers):
                if layer.get("is_serialized"):
                    count = 2 if layer.get("use_two") else 1
                else:
                    count = layer.get("neuron_count", 1)

                neurons_for_layer = self.n_dict[neuron_cursor : neuron_cursor + count]
                if len(neurons_for_layer) != count:
                    raise ValueError(f"Not enough neurons for layer {idx}. Expected {count}, got {len(neurons_for_layer)}.")
                neurons_by_layer[idx] = neurons_for_layer
                neuron_cursor += count
            if neuron_cursor != len(self.n_dict):
                raise ValueError("Unused neurons remain in neuron dictionary.")
        elif isinstance(self.n_dict, dict) and 'neur_idx' in self.n_dict:
            # Single neuron dict — treat as serialized, layer 0
            neurons_by_layer = {0: [self.n_dict]}
        elif isinstance(self.n_dict, dict):
            # Already grouped by layer index, use as-is
            for k, v in self.n_dict.items():
                neurons_by_layer[int(k)] = [v] if isinstance(v, dict) else v
        else:
            raise ValueError("Invalid neuron format.")
        return neurons_by_layer
        
    def generate_layers(self, template_dir, final_dir):
        layers = self.get_layers()               # List of layer dictionaries
        neurons_by_layer = self.get_neurons()     # Dict: layer_idx -> list of neurons

        for layer in layers:
            layer_idx = layer.get("layer_idx")
            if layer_idx is None:
                raise ValueError("Layer is missing 'layer_idx' key.")

            # Get the neuron list for this layer (either serialized or parallel)
            neuron_list = neurons_by_layer.get(layer_idx, [])

            if layer.get("is_serialized") is True:
                print(f"Generating serialized layer {layer_idx}")
            else:
                print(f"Generating parallel layer {layer_idx}")
            LayerModel(layer, neuron_list, template_dir, final_dir)
   
    def generate_vhdl(self, template_dir, template_file, output_dir, output_file):
        env = Environment(loader=FileSystemLoader(template_dir))
        template = env.get_template(template_file)
        vhdl_code = template.render(self.NN_dict)
        os.makedirs(output_dir, exist_ok=True)
        output_path = os.path.join(output_dir, output_file)

        with open(output_path, "w") as f:
            f.write(vhdl_code)
        print(f"VHDL file generated: {output_file}")



 #   def get_neurons(self):
 #       if isinstance(self.n_dict, dict):
 #           return {
 #               k: [neuron for neuron in v if isinstance(neuron, dict)]
 #               for k, v in self.n_dict.items()
 #               if isinstance(v, list)
 #           }
 #       else:
 #           raise ValueError("Invalid neuron format")
