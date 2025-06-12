import os
import math
from jinja2 import Environment, FileSystemLoader
import helper as help

class NeuronModel:
    def __init__(self, n_dict, template_dir, final_dir, data_width, weight_matrix_idx):
        """ 
        n_dict -> important data about the neuron
        data_width -> inputs of the neuron 
        It also receives the directory where templates are stored and the output 
        directory. 
        REMINDER --> ADD THE FOR_LOOP LOGIC IF NEEEDED
        """
        self.n_dict = n_dict
        if n_dict["is_serialized"] is True or n_dict["handshake"] is True:
            template_file = "neuron_with_states.vhd"  # Change this in neuron_with_states
        else :
            template_file = "neuron_with_bias.vhd"
        output_file = self.n_dict["name"] + "_" + f"{self.n_dict['neur_idx']}" + ".vhd"
        self.data_width = data_width
        self.weight_matrix_idx = weight_matrix_idx
        self.n_dict["bias_idx"] = weight_matrix_idx
        self.generate_weight_loading()
        self.addition_logic()
        self.activation_func()
        self.generate_vhdl(template_dir, template_file, final_dir, output_file)
        

    def info(self):
        return {
            "n_dict": self.n_dict,
        }
        
    def generate_weight_loading(self, checkpoints=None):
        dummy_lines=[]
        for i in range(self.n_dict["num_stages"]+1):
            for j in range(self.data_width):
                dummy_lines.append(f"stages({i}, {j}) <= (others => '0');")
        self.n_dict.update({"weight_rst":dummy_lines})    
        lines = []
        if checkpoints is None:
            checkpoints = []
        if self.n_dict["weight_logic"] == "if_logic":
            open_if_count=0

            for i in range(self.data_width):
                if self.n_dict["is_serialized"] is True:
                    indent = "    "                
                if i in checkpoints:
                    indent = "    " * open_if_count
                    if self.n_dict["is_serialized"] is True:
                        indent = indent + "    "
                    lines.append(f"{indent}if data_width-1 /= {i} then")
                    open_if_count += 1  # Increase the open if count (nesting level)
                lines.append(f"{indent}stages(0, {i}) <= resize(weights({i}), {self.n_dict['w_bitwidth']}) when inputs({i}) = '1' else (others => '0');")
                while open_if_count > 0:
                    if self.n_dict["is_serialized"] is True:
                        indent= "    " * (open_if_count - 1) + "    " 
                    else:
                        indent = "    " * (open_if_count - 1) + "    "
                    lines.append(f"{indent}end if;")
                    open_if_count -= 1


        elif self.n_dict["weight_logic"] == "no_loop":
            if self.n_dict["is_serialized"] is True:
                indent="    "
                for i in range(self.data_width):
                    if self.n_dict["weight_file"] is True:
                        lines.append(f"{indent}stages(0, {i}) <= resize(weight_matrix_{self.weight_matrix_idx}( weights_idx_{self.weight_matrix_idx}(start_weight + current_neuron) + {i} ), {self.n_dict['w_bitwidth']}) when inputs({self.data_width - i -1}) = '1' else (others => '0');")
#                        lines.append(f"{indent}stages_next(0, {i}) <= resize(weight_matrix_{self.weight_matrix_idx}( start_weight + current_neuron )({i}), {self.n_dict['w_bitwidth']}) when inputs({self.data_width - i -1}) = '1' else (others => '0');")
                    else:
                        lines.append(f"{indent}stages(0, {i}) <= resize(first_regs({i}), {self.n_dict['w_bitwidth']}) when inputs({self.data_width - i -1}) = '1' else (others => '0');")  
            else:
                if self.n_dict["handshake"] is True:
                    indent=""
                    for i in range(self.data_width):
                        if self.n_dict["weight_file"] is True:
                            lines.append(f"{indent}stages(0, {i}) <= resize(weights( start_weight + {i} ), {self.n_dict['w_bitwidth']}) when inputs({self.data_width - i -1}) = '1' else (others => '0');")
                        else:
                            lines.append(f"{indent}stages(0, {i}) <= resize(first_regs({i}), {self.n_dict['w_bitwidth']}) when inputs({self.data_width - i -1}) = '1' else (others => '0');")  
                else:
                    indent=""
                    for i in range(self.data_width):
                        if self.n_dict["weight_file"] is True:
                            lines.append(f"{indent}stages(0, {i}) <= resize(weights( start_weight + {i} ), {self.n_dict['w_bitwidth']}) when inputs({self.data_width - i -1}) = '1' else (others => '0');")
                        else:
                            lines.append(f"{indent}stages(0, {i}) <= resize(first_regs({i}), {self.n_dict['w_bitwidth']}) when inputs({self.data_width - i -1}) = '1' else (others => '0');")  

        self.n_dict.update({"weight_loading":lines})
        

    def addition_logic(self, checkpoints=None):
        if checkpoints is None:
            checkpoints = []
        else:
            checkpoints = [x + 2 for x in checkpoints]

        num_stages = self.n_dict["num_stages"]
        reduction_addition = []
        
        open_if_count = 0  # Count of open if blocks (outer if is open)
        
        if self.n_dict["sum_logic"] == "if_logic":
        # Iterate through stages (from 1 up to and including num_stages)
            for stage in range(1, num_stages + 1):
                step = 2 ** (stage - 1)
                
                # If this stage is a checkpoint, open a new nested if block
                if stage in checkpoints:
                    indent = "    " * open_if_count
                    if self.n_dict["is_serialized"] == True:
                        indent = indent + "    " 
                    reduction_addition.append(f"{indent}if stages({stage-2}, 0) /= stages({stage-1}, 0) then")
                    open_if_count += 1  # Increase the open if count (nesting level)
                
                # Generate all signal assignment lines for this stage,
                # at the current nesting level (inside all open if blocks)
                for j in range(self.data_width):
                    indent = "    " * open_if_count
                    if self.n_dict["is_serialized"] == True:
                        indent = indent + "    " 
                    if j % (2 ** stage) == 0:
                        if j + step < self.n_dict["data_width"]:
                            line = f"{indent}stages({stage}, {j}) <= stages({stage-1}, {j}) + stages({stage-1}, {j+step});"
                        else:
                            line = f"{indent}stages({stage}, {j}) <= stages({stage-1}, {j});"
                    else:
                        line = f"{indent}stages({stage}, {j}) <= (others => '0');"
                    reduction_addition.append(line)
            # After generating all stages, close all open if blocks
            while open_if_count > 0:
                indent = "    " * (open_if_count - 1)
                reduction_addition.append(f"{indent}end if;")
                open_if_count -= 1              

        elif self.n_dict["sum_logic"] == "no_loop":
            # Iterate through stages (from 1 up to and including num_stages)
            if self.n_dict["is_serialized"] == True:
                indent="    "
            else:
                indent=""
            for stage in range(1, num_stages + 1):
                step = 2 ** (stage - 1)                
                # Generate all signal assignment lines for this stage,
                # at the current nesting level (inside all open if blocks)
                for j in range(self.data_width):
                    if j % (2 ** stage) == 0:
                        if j + step < self.data_width:
                            line = f"{indent}stages({stage}, {j}) <= stages({stage-1}, {j}) + stages({stage-1}, {j+step});"
                        else:
                            line = f"{indent}stages({stage}, {j}) <= stages({stage-1}, {j});"
                    else:
                        line = f"{indent}stages({stage}, {j}) <= (others => '0');"
                    reduction_addition.append(line)

        elif self.n_dict["sum_logic"] == "state_mode":
            # Iterate through stages (from 1 up to and including num_stages)
            if self.n_dict["is_serialized"] == True:
                indent="    "
            else:
                indent=""
            for stage in range(1, num_stages + 1):
                step = 2 ** (stage - 1)                
                # Generate all signal assignment lines for this stage,
                # at the current nesting level (inside all open if blocks)
                for j in range(self.data_width):
                    if j % (2 ** stage) == 0:
                        if j + step < self.data_width:
                            line = "{}stages_next({{{{ i+1 }}}}, {}) <= stages({{{{ i }}}}, {}) + stages({{{{ i }}}}, {});".format(indent, j, j, j + step)
                        else:
                            line = "{}stages_next({{{{ i+1 }}}}, {}) <= stages({{{{ i }}}}, {});".format(indent, j, j)
                    else:
                        line = "{}stages_next({{{{ i+1 }}}}, {}) <= (others => '0');".format(indent, j)
                    reduction_addition.append(line)

        self.n_dict.update({"reduction_addition": reduction_addition})
        self.n_dict.update({"limit": self.data_width})
    

    """ 
        {%- if is_serialized is true and other_neuron is false %}
        {%- if full_output is true %}
        output_final <= output_reg_1;
        output_bit   <= output_reg_2; 
        {%- else %}
        output_bit   <= output_reg;
        {%- endif %}

        {%- elif is_serialized is true and other_neuron is true %}
        output_bit   <= output_reg;
        {%- else %}
        
        {%- if full_output is true %}
        output_final <= output_reg;
        {%- else %}
        output_bit   <= outpur_reg;
        {%- endif %}
        {%- endif %}
    """


    def activation_func(self):
        activation_logic=[]
        activation_type = self.n_dict["activation"]
        if self.n_dict["is_serialized"] == True and self.n_dict["handshake"] == False:
#          if self.n_dict["full_output"] == True:
#                line = f"if last_layer = '1' 
# then"
#                activation_logic.append(line)
            if self.n_dict["other_neuron"] == False and self.n_dict["full_output"] is True:
                line = f"output_reg_1_next <= sum;"
                activation_logic.append(line)
    #                line = f"    output_bit <= '0';"
    #                activation_logic.append(line)
    #                line = f"else"
    #                activation_logic.append(line)
                if activation_type == "ReLU":
                    line = f"output_reg_2_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "Sigmoid":
                    line = f"output_reg_2_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "Tanh":
                    line = f"output_reg_2_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "threshold":
                    line = f"output_reg_2_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                else:
                    line = f"output_reg_2_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                activation_logic.append(line)
                
            elif self.n_dict["other_neuron"] == False and self.n_dict["full_output"] is False: 
                if activation_type == "ReLU":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "Sigmoid":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "Tanh":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "threshold":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                else:
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                activation_logic.append(line)
            
            elif self.n_dict["other_neuron"] == True and self.n_dict["full_output"] is False: 
                if activation_type == "ReLU":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "Sigmoid":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "Tanh":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "threshold":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                else:
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                activation_logic.append(line)

            elif self.n_dict["other_neuron"] == True and self.n_dict["full_output"] is True:
                if self.n_dict["one_layer"] == True:
                    line = f"output_reg_next <= sum;"
                    activation_logic.append(line)
                else:
                    if activation_type == "ReLU":
                        line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                    elif activation_type == "Sigmoid":
                        line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                    elif activation_type == "Tanh":
                        line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                    elif activation_type == "threshold":
                        line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                    else:
                        line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                    activation_logic.append(line)

            else: 
                line = f"output_reg_next <= sum;"
                activation_logic.append(line)            

        elif self.n_dict["is_serialized"] == False and self.n_dict["handshake"] == False:
            if self.n_dict["full_output"] == True:
                line = f"output_final <= sum;"
                activation_logic.append(line)
            else:
                if activation_type == "ReLU":
                    line = f"output_bit <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "Sigmoid":
                    line = f"output_bit <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "Tanh":
                    line = f"output_bit <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "threshold":
                    line = f"output_bit <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                else:
                    line = f"output_bit <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                activation_logic.append(line)


        elif self.n_dict["is_serialized"] == True and self.n_dict["handshake"] == True:
            if self.n_dict["other_neuron"] == False and self.n_dict["full_output"] is True:
                line = f"output_reg_1_next <= sum;"
                activation_logic.append(line)
                if activation_type == "ReLU":
                    line = f"output_reg_2_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "Sigmoid":
                    line = f"output_reg_2_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "Tanh":
                    line = f"output_reg_2_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "threshold":
                    line = f"output_reg_2_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                else:
                    line = f"output_reg_2_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                activation_logic.append(line)       
            elif self.n_dict["other_neuron"] == False and self.n_dict["full_output"] is False: 
                if activation_type == "ReLU":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "Sigmoid":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "Tanh":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "threshold":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                else:
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                activation_logic.append(line)
            elif self.n_dict["other_neuron"] == True and self.n_dict["full_output"] is False: 
                if activation_type == "ReLU":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "Sigmoid":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "Tanh":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "threshold":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                else:
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                activation_logic.append(line)  
            elif self.n_dict["other_neuron"] == True and self.n_dict["full_output"] is True: 
                if self.n_dict["one_layer"] is True:
                    line = f"output_reg_next <= sum;"
                    activation_logic.append(line)  
                else:
                    if activation_type == "ReLU":
                        line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                    elif activation_type == "Sigmoid":
                        line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                    elif activation_type == "Tanh":
                        line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                    elif activation_type == "threshold":
                        line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                    else:
                        line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                    activation_logic.append(line)

        elif self.n_dict["handshake"] == True:
            if self.n_dict["full_output"] == True:
                line = f"output_reg_next <= sum;"
                activation_logic.append(line)
            else:
                if activation_type == "ReLU":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "Sigmoid":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "Tanh":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                elif activation_type == "threshold":
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                else:
                    line = f"output_reg_next <= '1' when sum > to_signed(0,  {self.n_dict['o_bitwidth']}) else '0';"
                activation_logic.append(line)

        self.n_dict.update({"activation_logic":activation_logic})

    def generate_vhdl(self, template_dir, template_file, output_dir, output_file):
        env = Environment(loader=FileSystemLoader(template_dir))
        template = env.get_template(template_file)
        vhdl_code = template.render(self.n_dict)
        os.makedirs(output_dir, exist_ok=True)
        output_path = os.path.join(output_dir, output_file)

        with open(output_path, "w") as f:
            f.write(vhdl_code)
        print(f"VHDL file generated: {output_file}")



"""def main():
    dummy_dict={}
    dummy_dict["name"] = "neuron"
    dummy_dict["data_width"] = 30
    dummy_dict["bitwidth"] = 32
    dummy_dict["num_stages"] = help.calculate_num_stages( dummy_dict["data_width"])
    dummy_dict["activation"] = "threshold"
    dummy_dict["sum_logic"] = "no_loop"
    dummy_dict["weight_logic"] = "no_loop"
    dummy_dict["weight_file"] = True
    dummy_dict["is_serialized"]= True
    dummy_dict["full_output"]= True
    dummy_dict["less_neurons"] = True
    dummy_dict["different_files"] = True

    model = NeuronModel(n_dict = dummy_dict,idx=2)
    model.generate_weight_loading()
    model.addition_logic([2,4])
    model.activation_func()
    current_dir = os.path.dirname(os.path.abspath(__file__))
    parent_dir = os.path.dirname(current_dir)  # One level up
    template_dir = os.path.join(parent_dir, "Templates")  # Example: ../templates_folder
    output_dir = os.path.join(parent_dir, "Results", "Tests")   


    model.generate_vhdl(
        template_dir=template_dir,
        template_file="neuron_with_bias.vhd",
        output_dir=output_dir,
        output_file="neuron_generated.vhd")
if __name__ == "__main__":
    main()"""  