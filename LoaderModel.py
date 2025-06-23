from jinja2 import Environment, FileSystemLoader
import os

class LoaderModel:

    """ 
    This class receives the dictionary for the input loader.
    It generates the input loader vhdl file.
    It also receives the directory where templates are stored and the output 
    directory. 
    """

    def __init__(self, loader_dict, template_dir, final_dir):
        self.loader_dict = loader_dict
        template_file = "input_loader.vhd"
        output_file = "input_loader.vhd"
        self.generate_vhdl(template_dir, template_file, final_dir, output_file)

   
    def generate_vhdl(self, template_dir, template_file, output_dir, output_file):
        env = Environment(loader=FileSystemLoader(template_dir))
        template = env.get_template(template_file)
        vhdl_code = template.render(self.loader_dict)
        os.makedirs(output_dir, exist_ok=True)
        output_path = os.path.join(output_dir, output_file)

        with open(output_path, "w") as f:
            f.write(vhdl_code)
        print(f"VHDL file generated: {output_file}")

