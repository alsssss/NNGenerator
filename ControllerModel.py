from jinja2 import Environment, FileSystemLoader
import os

class ControllerModel:

    """ 
    This class handles the customization of the parameters related to the 
    process controller and controller entities of the design.
    """

    def __init__(self, control_dict, template_dir, final_dir):
        self.control_dict = control_dict
        template_file_1 = "process_controller.vhd"
        output_file_1 = "process_controller.vhd"
        template_file_2 = "controller.vhd"
        output_file_2 = "controller.vhd"        
        self.generate_vhdl(template_dir, template_file_1, final_dir, output_file_1)
        self.generate_vhdl(template_dir, template_file_2, final_dir, output_file_2)

   
    def generate_vhdl(self, template_dir, template_file, output_dir, output_file):
        env = Environment(loader=FileSystemLoader(template_dir))
        template = env.get_template(template_file)
        vhdl_code = template.render(self.control_dict)
        os.makedirs(output_dir, exist_ok=True)
        output_path = os.path.join(output_dir, output_file)

        with open(output_path, "w") as f:
            f.write(vhdl_code)
        print(f"VHDL file generated: {output_file}")

