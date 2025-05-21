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
    {%- if is_serialized is true and layer_count == 1 and handshake is true %}  
    signal ending_reg           : std_logic := '0';
    {%- endif %}
    {%- for i in range(layer_count - 1) %}
    signal layer_output_{{ i }} : std_logic_vector({{ layer_output_widths[i] - 1 }} downto 0) := (others => '0');
    {%- if handshake is true %}
    signal done_{{ i }}         : std_logic := '0';
    signal ending_reg           : std_logic := '0';
    {%- endif %}
    {%- endfor %}
    signal inp_out              : std_logic_vector({{ input_width - 1 }} downto 0) := (others => '0');
    signal ready                : std_logic := '0';

begin

    {%- if handshake is true %}
    ending  <= ending_reg;
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
            {%- if handshake is true %}
            done => ending_reg,
            {%- endif %}
            outputs => outputs
        );
    {%- endif %} 

end Structural;