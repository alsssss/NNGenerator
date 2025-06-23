from jinja2 import Environment, FileSystemLoader
import os

class MaxModel:

    """ 
    Class needed to customize the Top level entity of the project
    """

    def __init__(self, top_level_dict, template_dir, final_dir):
        self.top_level_dict = top_level_dict
        template_file = "top.vhd"
        output_file = "top.vhd"
        self.generate_vhdl(template_dir, template_file, final_dir, output_file)

   
    def generate_vhdl(self, template_dir, template_file, output_dir, output_file):
        env = Environment(loader=FileSystemLoader(template_dir))
        template = env.get_template(template_file)
        vhdl_code = template.render(self.top_level_dict)
        os.makedirs(output_dir, exist_ok=True)
        output_path = os.path.join(output_dir, output_file)

        with open(output_path, "w") as f:
            f.write(vhdl_code)
        print(f"VHDL file generated: {output_file}")

