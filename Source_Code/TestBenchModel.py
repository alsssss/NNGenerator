from jinja2 import Environment, FileSystemLoader
import os

class TestBenchModel:

    """ 
    This class just helps me get data correctly formatted for the testbenches.
    The file it outputs must not be used in a project, just the data inside.
    """

    def __init__(self, TB_dict, template_dir, unused_dir):
        self.TB_dict = TB_dict
        template_file = "testbench.vhd"
        output_file = "network_TB.vhd"
        self.generate_vhdl(template_dir, template_file, unused_dir, output_file)

   
    def generate_vhdl(self, template_dir, template_file, output_dir, output_file):
        env = Environment(loader=FileSystemLoader(template_dir))
        template = env.get_template(template_file)
        vhdl_code = template.render(self.TB_dict)
        os.makedirs(output_dir, exist_ok=True)
        output_path = os.path.join(output_dir, output_file)

        with open(output_path, "w") as f:
            f.write(vhdl_code)
        print(f"VHDL file generated: {output_file}")

