library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.TYPE_DEF.ALL;


entity {{ network_name }} is
    port (
        clk     : in std_logic;
        rst     : in std_logic;
        enable  : in std_logic;
        inputs  : in unsigned({{ t_bitwidth - 1 }} downto 0);
        {%- if handshake is true %}
        ending  : out std_logic;
        {%- endif %}
        outputs : out output({{ output_width - 1 }} downto 0)
    );
end {{ network_name }};

architecture Structural of {{ network_name }} is

    -- Intermediate signals
    {%- if handshake is true  %}  
    signal ending_reg            : std_logic := '0';
    {%- endif %}
    {%- for i in range(layer_count - 1) %}
    signal layer_output_{{ i }}  : std_logic_vector({{ layer_output_widths[i] - 1 }} downto 0) := (others => '0');
    {%- if handshake is true %}
    signal done_{{ i }}          : std_logic := '0';
    {%- endif %}
    {%- endfor %}
    signal inp_out               : std_logic_vector({{ input_width - 1 }} downto 0) := (others => '0');
    signal ready                 : std_logic := '0';
    {%- if weight_file is false %}

    {%- if layer_count > 1 %}
    {%- for i in range(layer_count) %}
    signal start_ROM_{{ i }}     : std_logic;
    signal NEURON_INPUTS_{{ i }} : natural;
    signal NEURON_NUM_{{ i }}    : natural;
    {%- endfor %}
    {%- endif %}
    signal start_ROM             : std_logic;
    signal out_ROM               : signed (31 downto 0);  -- The memory i use always has a 32 bit word
    signal addr_ROM              : std_logic_vector({{ addr_size - 1 }} downto 0);
    signal input_break           : natural;
    signal neuron_break          : natural;
    signal neuron_w              : signed(7 downto 0);    -- Also when using memory i always assume 8 bit values
    signal input_idx             : natural;
    signal load_n                : std_logic_vector({{ inferred_neurons_max - 1 }} downto 0);
    signal done_load             : std_logic;     
    {%- endif %}



begin

    {%- if handshake is true %}
    ending  <= ending_reg;
    {%- endif %}

    {%- if weight_file is false and layer_count > 1 %}
    start_ROM <=
    {%- for i in range(layer_count) -%}
        start_ROM_{{ i }}{{ ' or ' if not loop.last else '' }}
    {%- endfor %};
  
    select_layer : process(clk, rst)
    begin
        if rst = '1' then
            input_break  <= 0;
            neuron_break <= 0;
        elsif rising_edge(clk) then
        {%- for i in range(layer_count) %}
            {%- if i == 0 %}
            if start_ROM_{{ i }} = '1' then
            {%- else %}
            elsif start_ROM_{{ i }} = '1' then
            {%- endif %}
                input_break  <= NEURON_INPUTS_{{ i }};
                neuron_break <= NEURON_NUM_{{ i }};
        {%- endfor %}
            else
                input_break  <= input_break;
                neuron_break <= neuron_break;
            end if;
        end if;
    end process select_layer;
    {%- endif %}

    input_loader_inst : entity work.input_loader
        port map(
        clk   => clk,
        rst   => rst,
        enable => enable,
        inputs => inputs,
        ready => ready,
        inp_out => inp_out
    );

    {%- if weight_file is false %}
    rom_inst : entity work.network_weights
        port map(
        clk   => clk,
        addr  => addr_ROM,
        dout  => out_ROM
    );

    rom_control_inst : entity work.rom_control
        port map(
        clk             => clk,
        rst             => rst,
        start           => start_ROM,
        ram_dout        => out_ROM,
        input_break     => input_break,
        neuron_break    => neuron_break,
        ram_addr        => addr_ROM,
        neuron_in_data  => neuron_w,
        neuron_in_index => input_idx,
        load_enable     => load_n,
        done            => done_load
    );

    {%- endif %}

    {%- if layer_count > 1 %}
    -- Layer 0: Takes input from the network
    {{ layer_names[0] }}_inst : entity work.{{ layer_names[0] }}
        {%- if layer_generics[0] %}
        generic map (
            {%- for g_name, g_value in layer_generics[0].items() %}
            {{ g_name }} => {{ g_value }}{% if not loop.last %}, {% endif %}
            {%- endfor %}
        )
        {%- endif %}
        port map (
            clk     => clk,
            rst     => rst,
            inputs  => inp_out,
            start   => ready,
            {%- if weight_file is false %}
            input_idx => input_idx,
            neuron_data => neuron_w,
            load_n => load_n,
            done_load => done_load,
            req_ROM => start_ROM_0,
            input_break => NEURON_INPUTS_0,
            neuron_break => NEURON_NUM_0,
            {%- endif %}
            {%- if handshake is true %}
            done => done_0,
            {%- endif %}
            outputs => layer_output_0
        );

    -- Intermediate layers
    {% for i in range(1, layer_count - 1) %}
    {{ layer_names[i] }}_inst : entity work.{{ layer_names[i] }}
        {%- if layer_generics[i] %}
        generic map (
            {%- for g_name, g_value in layer_generics[i].items() %}
            {{ g_name }} => {{ g_value }}{% if not loop.last %}, {% endif %}
            {%- endfor %}
        )
        {%- endif %}
        port map (
            clk     => clk,
            rst     => rst,
            inputs  => layer_output_{{ i - 1 }},
            {%- if handshake is true %}
            start => done_{{ i - 1 }},
            {%- endif %}
            {%- if weight_file is false %}
            input_idx => input_idx,
            neuron_data => neuron_w,
            load_n => load_n,
            done_load => done_load,
            req_ROM => start_ROM_{{i}},
            input_break => NEURON_INPUTS_{{ i }},
            neuron_break => NEURON_NUM_{{ i }},
            {%- endif %}
            {%- if handshake is true %}
            done => done_{{ i }},
            {%- endif %}
            outputs => layer_output_{{ i }}
        );
    {% endfor %}

    -- Final layer connects to network output
    {{ layer_names[-1] }}_inst : entity work.{{ layer_names[-1] }}
        {%- if layer_generics[-1] %}
        generic map (
            {%- for g_name, g_value in layer_generics[-1].items() %}
            {{ g_name }} => {{ g_value }}{% if not loop.last %}, {% endif %}
            {%- endfor %}
        )
        {%- endif %}
        port map (
            clk     => clk,
            rst     => rst,
            inputs  => layer_output_{{ layer_count - 2 }},
            {%- if handshake is true %}
            start => done_{{ layer_count - 2 }},
            {%- endif %}
            {%- if weight_file is false %}
            input_idx => input_idx,
            neuron_data => neuron_w,
            load_n => load_n,
            done_load => done_load,
            req_ROM => start_ROM_{{ layer_count - 1 }},
            input_break => NEURON_INPUTS_{{ layer_count - 1 }},
            neuron_break => NEURON_NUM_{{ layer_count - 1}},
            {%- endif %}
            {%- if handshake is true %}
            done => ending_reg,
            {%- endif %}            
            outputs => outputs
        );
    {%- else %}

    {{ layer_names[0] }}_inst : entity work.{{ layer_names[0] }}
        {%- if layer_generics[0] %}
        generic map (
            {%- for g_name, g_value in layer_generics[0].items() %}
            {{ g_name }} => {{ g_value }}{% if not loop.last %}, {% endif %}
            {%- endfor %}
        )
        {%- endif %}
        port map (
            clk     => clk,
            rst     => rst,
            inputs  => inp_out,
            start   => ready,
            {%- if weight_file is false %}
            input_idx => input_idx,
            neuron_data => neuron_w,
            load_n => load_n,
            done_load => done_load,
            req_ROM => start_ROM,
            input_break => input_break,
            neuron_break => neuron_break,
            {%- endif %}
            {%- if handshake is true %}
            done => ending_reg,
            {%- endif %}
            outputs => outputs
        );
    {%- endif %} 


end Structural;