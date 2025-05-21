from jinja2 import Environment, FileSystemLoader
from NeuronModel import NeuronModel
import os

class LayerModel:

    """ 
    This class receives the dictionaries for the layers and the neurons.
    It generates layer vhdl files. 
    Only the dictionaries for the layers and the neurons are passed to 
    the next class -> (NeuronModel) 
    It also receives the directory where templates are stored and the output 
    directory. 
    """
   
    def __init__(self, l_dict, n_dict, template_dir, final_dir):
        self.l_dict = l_dict
        self.n_dict = n_dict
        if l_dict["is_serialized"] is True:
            template_file = "layer_with_states.vhd"
            output_file = self.l_dict["layer_name"] + ".vhd"
        else:
            template_file = "layer_all.vhd"
            output_file = self.l_dict["layer_name"] + "_" + f"{self.l_dict['layer_idx']}" + ".vhd"
        self.generate_vhdl(template_dir, template_file, final_dir, output_file)
        self.generate_neurons(template_dir, final_dir)


    def generate_neurons(self, template_dir, output_dir):
        if isinstance(self.n_dict, dict):
            NeuronModel(self.n_dict, template_dir, output_dir)
        elif isinstance(self.n_dict, list):
            # Multiple neurons
            for neuron_dict in self.n_dict:
                if isinstance(neuron_dict, dict):
                    print(f"Generating neuron_{neuron_dict['neur_idx']}")
                    if "max_data_width" in self.l_dict:
                            NeuronModel(neuron_dict, template_dir, output_dir, self.l_dict["max_data_width"], self.l_dict["layer_idx"])
                    else:
                        NeuronModel(neuron_dict, template_dir, output_dir, self.l_dict["data_width"], None)
                else:
                    raise ValueError("Invalid neuron entry: expected a dictionary.")
        else:
            raise ValueError("Neuron data must be a dictionary or a list of dictionaries.")

    def generate_vhdl(self, template_dir, template_file, output_dir, output_file):
        env = Environment(loader=FileSystemLoader(template_dir))
        env.globals['enumerate'] = enumerate
        template = env.get_template(template_file)
        vhdl_code = template.render(self.l_dict)
        os.makedirs(output_dir, exist_ok=True)
        output_path = os.path.join(output_dir, output_file)

        with open(output_path, "w") as f:
            f.write(vhdl_code)
        print(f"VHDL file generated: {output_file}")

