from jinja2 import Environment, FileSystemLoader
import os

class PkgModel:

    """ 
    This class receives the dictionary for the package containing important types and costants.
    It generates a vhdl package.
    It also receives the directory where templates are stored and the output 
    directory. 
    """

    def __init__(self, pkg_dict, template_dir, final_dir):
        self.pkg_dict = pkg_dict
        template_file = "config.vhd"
        output_file = "TYPE_DEF.vhd"
        if self.pkg_dict["is_serialized"] == True:
            self.extract_weights()
            self.extract_biases()
        self.generate_vhdl(template_dir, template_file, final_dir, output_file)


    def extract_weights(self):
        config_lists = self.pkg_dict["config_dict"]
        for config in config_lists:
            list = config["generated_rows"]
            config["generated_rows"] = self.wrap_weights_into_signed(list)

    def wrap_weights_into_signed(self, weight_data):
        bitwidth = self.pkg_dict['file_bitwidth']

        # If it's a list of lists, flatten it
        if any(isinstance(w, (list, tuple)) for w in weight_data):
            flat_list = [int(float(val)) for sublist in weight_data for val in sublist]
        else:
            flat_list = [int(float(val)) for val in weight_data]

        # Return a list of VHDL-formatted strings
        return [f"to_signed({val}, {bitwidth})" for val in flat_list]
   
  #  def wrap_weights_into_signed(self, list):
  #      bitwidth = self.pkg_dict['file_bitwidth']
  #      wrapped_rows = []
  #      for row in matrix:
  #          formatted_values = ", ".join(f"to_signed({int(val)}, {bitwidth})" for val in row)
  #          wrapped_rows.append(formatted_values)  # Each row is now a flat VHDL string
  #      return wrapped_rows  # Not a string, but a list of row strings
    
    def extract_biases(self):
        config_lists = self.pkg_dict["config_dict"]
        for config in config_lists:
            values = config["bias_array"]
            config["bias_array"] = self.wrap_bias_into_signed(values)


    def wrap_bias_into_signed(self, bias_data):
        bitwidth = self.pkg_dict['file_bitwidth']

        if any(isinstance(b, (list, tuple)) for b in bias_data):
            flat_list = [int(float(val)) for sublist in bias_data for val in sublist]
        else:
            flat_list = [int(float(val)) for val in bias_data]
        return [f"to_signed({val}, {bitwidth})" for val in flat_list]
   

    def pack_8bit_to_32bit_bitvector(data_8bit):

        # Pad with zeros if needed
        while len(data_8bit) % 4 != 0:
            data_8bit.append(0)

        packed_bitvectors = []
        for i in range(0, len(data_8bit), 4):
            # Convert each byte to 8-bit binary string
            bits = ''.join(f"{b:08b}" for b in data_8bit[i:i+4])
            packed_bitvectors.append(bits)
        return packed_bitvectors




    def generate_vhdl(self, template_dir, template_file, output_dir, output_file):
        env = Environment(loader=FileSystemLoader(template_dir))
        template = env.get_template(template_file)
        vhdl_code = template.render(self.pkg_dict)
        os.makedirs(output_dir, exist_ok=True)
        output_path = os.path.join(output_dir, output_file)

        with open(output_path, "w") as f:
            f.write(vhdl_code)
        print(f"VHDL file generated: {output_file}")