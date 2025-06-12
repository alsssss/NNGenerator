library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.ALL;
use work.TYPE_DEF.ALL;

entity {{ name }}_{{ neur_idx }} is
    generic (
        {%- if different_files is false %}
        current_neuron : natural;
        {%- endif %}
        {%- if is_serialized is false %}
--        num_stages     : natural;
        {%- if weight_file is true %}
        {%- if different_files is false%}
        bias_index     : natural; 
        {%- endif %}
        start_weight   : natural;
        {%- endif %}
        {%- endif %}     
        data_width     : natural 
    );
    port (
        clk          : in std_logic;
        rst          : in std_logic;
        inputs       : in std_logic_vector(data_width-1 downto 0);
        {%- if weight_file is false %}
        weights      : in weight(data_width-1 downto 0);
        biases       : in bias(data_width-1 downto 0);
        {%- else %}
        {%- if is_serialized is true %}
        bias_index     : in natural; 
        start_weight   : in natural;
        {%- endif %}
        {%- endif %}
        {%- if is_serialized is true %}
        start        : in std_logic;
        {%- if full_output is true%}
        last_layer   : in std_logic;
        {%- endif %}
        done         : out std_logic;
        {%- else %}
        {%- if handshake is true %}
        start        : in std_logic;
        done         : out std_logic;
        {%- endif %}
        {%- endif %}        
        {%- if last_layer is true %}
        {%- if full_output is true %}
        output_final : out signed({{o_bitwidth-1}} downto 0)
        {%- else %}
        output_bit       : out std_logic
        {%- endif %}
        {%- else %}
        {%- if full_output is true %}
        output_final : out signed({{o_bitwidth-1}} downto 0);
        {%- else %}
        output_bit       : out std_logic
        {%- endif %}
        {%- endif %}
    );
end entity {{ name }}_{{neur_idx}};

architecture Behavioral of {{ name }}_{{neur_idx}} is
    {%- if handshake is true %}
    type state_type is (IDLE, COMPUTE, DONE);
    {%- endif %}
    type matrix_type is array ( 0 to {{ num_stages }}, 0 to data_width-1 ) of signed({{w_bitwidth-1}} downto 0);
    signal stages : matrix_type := (others => (others => (others => '0')));
    signal sum    : signed({{w_bitwidth - 1}} downto 0);
    {%- if handshake is true %}
    variable state : state_type := IDLE;
    {%- endif %}

begin

    process (clk, rst)
    begin
        if rst = '1' then
            sum <= (others => '0');
            {%- if last_layer is true %}
            {%- if full_output is true %}
            output_final  <= (others => '0');
            {%- else %}
            output_bit <= '0';
            {%- endif %}
            {%- else %}
            {%- if full_output is true %}
            output_final  <= (others => '0');
            {%- else %}
            output_bit <= '0';
            {%- endif %}
            {%- endif %}
            {%- for line in weight_rst %}
            {{ line }}
            {%- endfor %}
        elsif rising_edge(clk) then
            {%- if is_serialized is true or handshake is true %}
            if start ='1' then
            {%- endif %}
            -- Load initial values (weights)
            {%- for line in weight_loading %}
            {{ line }}
            {%- endfor %}

            -- Perform reduction addition
            {%- for line in reduction_addition %}
            {{ line }}
            {%- endfor %}

            -- Add the bias
            sum <= stages({{num_stages}}, 0) + resize(biases({%- if different_files is true %}{{neur_idx}}{%- else %} bias_index + current_neuron{%- endif %}), {{w_bitwidth}});

            -- Activation function
            {%- for line in activation_logic %}
            {{line}}
            {%- endfor %}
            {%- if is_serialized is true or handshake is true %}
            done <= '1';
            end if;
            {%- endif %}
        end if;
    end process;

end Behavioral;
