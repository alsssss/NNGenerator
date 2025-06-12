from jinja2 import Environment, FileSystemLoader
import os

class MemoryModel:
    
    def __init__(self, memory_dict, template_dir, final_dir):
        self.memory_dict = memory_dict
        template_file_1 = "rams_init_file.vhd"
        template_file_2 = "rom_control.vhd"
        output_file_1 = "network_weights.vhd"
        output_file_2 = "rom_control.vhd"
        self.generate_vhdl(template_dir, template_file_1, final_dir, output_file_1)
        self.generate_vhdl(template_dir, template_file_2, final_dir, output_file_2)
    
    def generate_vhdl(self, template_dir, template_file, output_dir, output_file):
        env = Environment(loader=FileSystemLoader(template_dir))
        env.globals['enumerate'] = enumerate
        template = env.get_template(template_file)
        vhdl_code = template.render(self.memory_dict)
        os.makedirs(output_dir, exist_ok=True)
        output_path = os.path.join(output_dir, output_file)

        with open(output_path, "w") as f:
            f.write(vhdl_code)
        print(f"VHDL file generated: {output_file}")
