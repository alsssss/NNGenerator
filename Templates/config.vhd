library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package TYPE_DEF is

	-- Type Definitions
	type output is array (natural range <>) of signed({{ o_bitwidth - 1 }} downto 0);
	{%- if weight_file is true %}
	{%- if is_serialized is false %}
	type stored is array (natural range <>) of signed({{ file_bitwidth - 1 }} downto 0);
	{%- endif %}
	{%- if is_serialized is true %}
	{%- for config in config_dict %}
	type matrix_array_{{ loop.index0 }} is array (0 to {{ config.generated_rows|length - 1 }}) of signed({{ file_bitwidth -1 }} downto 0);
	type bias_{{ loop.index0 }} is array (0 to {{ config.max_neurons - 1 }}) of signed({{ file_bitwidth - 1 }} downto 0);
    type indexes_{{ loop.index0 }} is array(0 to {{ config.weights_idx|length - 1 }}) of natural;
	{%- endfor %}
		
	-- Important constants of the net
	
	{%- if is_serialized is true %}
	{%- for config in config_dict %}
	constant weights_idx_{{ loop.index0 }} : indexes_{{ loop.index0 }} := (
	{%- for idx in config.weights_idx %}
    {{ idx }}{{ "," if not loop.last else "" }}
    {%- endfor %}
	);
	{%- endfor %}
	{%- endif %}

	{%- for config in config_dict %}
	constant biases_{{ loop.index0 }} : bias_{{ loop.index0 }} := (
		{%- for val in config.bias_array %}
		{{ val }}{% if not loop.last %}, {% endif %}
		{%- endfor %}
	);
	{%- endfor %}

	{%- for config in config_dict %}
	constant weight_matrix_{{ loop.index0 }} : matrix_array_{{ loop.index0 }} := (
    {%- for rows in config.generated_rows %}
    (
    {{ rows }}
    ){% if not loop.last %},{% endif %}
    {%- endfor %}
	);
	{%- endfor %}
    {%- else %}
	--Important constants of the net

	constant weights : stored (0 to {{ weights|length - 1 }}) :=(
		{%- for w in weights %}
		to_signed({{ w }}, {{ file_bitwidth }}){% if not loop.last %},{% endif %}
		{%- endfor %}
	);

	constant biases : stored ( 0 to {{ biases|length - 1 }}) := (
		{%- for b in biases %}
		to_signed({{ b }}, {{ file_bitwidth }}){% if not loop.last %},{% endif %}
		{%- endfor %}
	);
	{%- endif %}
	{%- endif %}
	
end TYPE_DEF;