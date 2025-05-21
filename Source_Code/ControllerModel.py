from jinja2 import Environment, FileSystemLoader
import os

class ControllerModel:

    """ 
    Class needed to customize parameters of the process controller
    """

    def __init__(self, pc_dict, template_dir, final_dir):
        self.pc_dict = pc_dict
        template_file = "process_controller.vhd"
        output_file = "process_controller.vhd"
        self.generate_vhdl(template_dir, template_file, final_dir, output_file)

   
    def generate_vhdl(self, template_dir, template_file, output_dir, output_file):
        env = Environment(loader=FileSystemLoader(template_dir))
        template = env.get_template(template_file)
        vhdl_code = template.render(self.pc_dict)
        os.makedirs(output_dir, exist_ok=True)
        output_path = os.path.join(output_dir, output_file)

        with open(output_path, "w") as f:
            f.write(vhdl_code)
        print(f"VHDL file generated: {output_file}")

