from jinja2 import Template
import json
import math

# Load JSON configuration
with open("neuron_config.json") as f:
    neuron_data = json.load(f)

# Compute number of stages (move logic out of VHDL)
num_stages = math.ceil(math.log2(neuron_data["num_inputs"]))
neuron_data["num_stages"] = num_stages

# Generate weight loading logic
weight_loading = [
    f"stages(0, {i}) <= weights({i}) when inputs({i}) = '1' else (others => '0');"
    for i in range(neuron_data["num_inputs"])
]
neuron_data["weight_loading"] = weight_loading

# Generate reduction addition logic
reduction_addition = []
for stage in range(1, num_stages + 1):
    step = 2**(stage - 1)
    for j in range(neuron_data["num_inputs"]):
        if j % (2**stage) == 0:
            if j + step < neuron_data["num_inputs"]:
                line = f"stages({stage}, {j}) <= stages({stage-1}, {j}) + stages({stage-1}, {j+step});"
            else:
                line = f"stages({stage}, {j}) <= stages({stage-1}, {j});"
        else:
            line = f"stages({stage}, {j}) <= (others => '0');"
        reduction_addition.append(line)
neuron_data["reduction_addition"] = reduction_addition

# Generate activation function logic
activation_type = neuron_data["activation_type"]
if activation_type == "ReLU":
    activation_logic = "output <= '1' when sum > to_signed(0, bitwidth) else '0';"
elif activation_type == "Sigmoid":
    activation_logic = "output <= '1' when sum > to_signed(0, bitwidth) else '0'; -- Approximate sigmoid"
elif activation_type == "Tanh":
    activation_logic = "output <= '1' when sum > to_signed(0, bitwidth) else '0';"
else:
    activation_logic = "output <= '1' when sum > to_signed(0, bitwidth) else '0'; -- Default linear activation"

neuron_data["activation_logic"] = activation_logic

# Load Jinja2 template
with open("neuron_template.vhd") as f:
    template = Template(f.read())

# Render VHDL file
vhdl_code = template.render(neuron_data)

# Save VHDL output
with open(f"{neuron_data['name']}.vhd", "w") as f:
    f.write(vhdl_code)

print(f"Generated {neuron_data['name']}.vhd")
