library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.TYPE_DEF.ALL;

entity {{ layer_name }}_{{ layer_idx }} is
    port (
        clk     : in std_logic;
        rst     : in std_logic;
        inputs  : in std_logic_vector({{ input_width - 1 }} downto 0);
        {%- if first_layer is true or handshake is true%}
        start   : in std_logic;
        {%- endif %}
        {%- if handshake is true%}
        done    : out std_logic;
        {%- endif %}        
        {%- if last_layer is true %}
        outputs : out output({{ output_width - 1 }} downto 0)
        {%- else %}
        outputs : out std_logic_vector({{ output_width -1 }} downto 0)
        {%- endif %}

    );
end {{ layer_name }}_{{ layer_idx }};

architecture Behavioral of {{ layer_name }}_{{ layer_idx }} is
    {%- if last_layer is true %}
    {%- if full_output is true %}
    signal neuron_outputs : output({{ output_width - 1 }} downto 0) := (others => ( others => '0'));
    {%- else %}
    signal neuron_outputs : std_logic_vector({{ output_width - 1 }} downto 0) := (others => '0');
    {%- endif %}
    {%- else %}
    signal neuron_outputs : std_logic_vector({{ output_width - 1 }} downto 0) := (others => '0');
    {%- endif %}
    signal released_inputs: std_logic_vector({{ input_width -1 }} downto 0 ) := (others => '0');
    {%- if handshake is true %}
    signal start_neurons : std_logic := '0';
    signal neuron_done_vector : std_logic_vector({{ output_width - 1 }} downto 0) := (others => '0');
    constant ALL_ONES : std_logic_vector( {{ output_width - 1 }} downto 0) := (others => '1');
    {%- endif %}
    
    
begin

    -- Neuron instantiations
    {%- if different_files is true %}
    {% set start = neuron_idx  %}
    {%- for i, j in neuron_pairs %}
    {%- set rev_j = neurons_idx -1 -j %}
    neuron_inst_{{ i }} : entity work.neuron_{{ i }}
        generic map (

--            num_stages     => {{ num_stages}}, 
            {%- if weight_file is true %}
            {%- if different_files is false %}
            bias_index     => {{ bias_indexes }},
            {%- endif %} 
            start_weight   => {{ start_weights[j] }},
            {%- endif %}
            DATA_WIDTH     => {{ data_width }}
        )
        port map (
            clk    => clk,
            rst    => rst,
            inputs => released_inputs,
            {%- if handshake is true %}
            start => start_neurons,
            done => neuron_done_vector({{ rev_j }}),
            {%- endif %}
            {%- if last_layer is true %}
            {%- if full_output is true %}
            output_final => neuron_outputs({{ rev_j }})
            {%- else %}
            output_bit => neuron_outputs({{ rev_j }})
            {%- endif %}
            {%- else %}
            output_bit => neuron_outputs({{ rev_j }})
            {%- endif %}
        );
    {%- endfor %}
    {%- else %}
    {%- for i in range(output_width) %}
    neuron_inst_{{ i }} : entity work.neuron_{{ layer_idx }}
        generic map ( 
            current_neuron => {{ i }},
--            num_stages     => {{ num_stages}}, 
            {%- if weight_file is true %}
            {%- if different_files is false %}
            bias_index     => {{ bias_indexes }},
            {%- endif %}  
            start_weight   => {{ start_weights[i] }},
            {%- endif %}
            DATA_WIDTH     => {{ data_width }}
        )
        port map (
            clk    => clk,
            rst    => rst,
            inputs => released_inputs,
            {%- if handshake is true %}
            start => start_neurons,
            done => neuron_done_vector({{ i }}),
            {%- endif %}            
            {%- if last_layer is true %}
            {%- if full_output is true %}
            output_final => neuron_outputs({{ output_width - i - 1 }})
            {%- else %}
            output_bit => neuron_outputs({{ output_width - i - 1 }})
            {%- endif %}
            {%- else %}
            output_bit => neuron_outputs({{ output_width - i - 1 }})
            {%- endif %}
        );
    {%- endfor %}
    {%- endif %}

    {%- if handshake is true %}
    PROCESS(clk, rst)
    BEGIN    
        if (rst = '1') then
            released_inputs <= (others => '0');
            start_neurons   <= '0';
            done            <= '0';
            {%- if last_layer is true %}
            outputs         <= (others => (others => '0'));
            {%- else %}
            outputs         <= (others => '0');
        {%- endif %}
		elsif (rising_edge(clk)) then
            done <= '0';
            if start='1' and start_neurons = '0' then
                released_inputs <= inputs;
                start_neurons   <= '1';
            elsif neuron_done_vector = ALL_ONES then
                start_neurons   <= '0';
                done            <= '1';
                outputs         <= neuron_outputs;
            end if;
        end if;
    end PROCESS;
    {%- elif first_layer is true %}
    PROCESS(clk, rst, start)
    BEGIN    
        if (rst = '1') then
            released_inputs <= (others => '0');
		elsif(rising_edge(clk)) THEN
            if start='1' then
                released_inputs <= inputs;
            end if;        
        end if;
    end PROCESS;
    outputs <= neuron_outputs;    
    {%- else %}
    released_inputs <= inputs; 
    outputs         <= neuron_outputs;    
    {%- endif %}
end architecture Behavioral;