library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.TYPE_DEF.ALL;

entity {{ name }}_{{ neur_idx }} is

    generic ( 
        {%- if different_files is false %}
        {%- if is_serialized is true %}
        current_neuron : natural range 0 to {{ neuron_number }};
        {%- else %}
        current_neuron : natural;
        {%- endif %}
        {%- endif %}
        {%- if is_serialized is false %}
        {%- if weight_file is true %}
        {%- if different_files is false%}
        bias_index     : natural; 
        {%- endif %}
        start_weight   : natural;
        {%- endif %}
        {%- endif %}     
        data_width     : natural
    );

    Port (
        clk          : in std_logic;
        rst          : in std_logic;
        inputs       : in std_logic_vector( data_width - 1 downto 0);

        {%- if is_serialized is true %}
        {%- if weight_file is false %}
        load_en      : in std_logic;
        input_idx    : in natural;
        data         : in signed(7 downto 0);
        done_load    : in std_logic;
        {%- else %}
        bias_index   : in natural;
        start_weight : in natural;
        {%- endif %}
        {%- endif %}

        {%- if is_serialized is false %}
        {%- if weight_file is false %}
        load_en      : in std_logic;
        input_idx    : in natural;
        data         : in signed(7 downto 0);
        done_load    : in std_logic;
        {%- endif %}
        {%- endif %}   

        start        : in std_logic;
        done         : out std_logic;
        {%- if is_serialized is true %}
        {%- if full_output is true %}

        {%- if other_neuron is false %}
        output_final : out signed({{o_bitwidth-1}} downto 0);
        output_bit   : out std_logic   
        {%- else %}
        {%- if one_layer is true %}
        output_final : out signed({{ o_bitwidth - 1 }} downto 0)
        {%- else %}
        output_bit : out std_logic
        {%- endif %}
        {%- endif %}

        {%- else %}
        output_bit : out std_logic        
        {%- endif %}

        {%- else %}
        {%- if full_output is true %}
        output_final :  out signed({{o_bitwidth-1}} downto 0)
        {%- else %}
        output_bit : out std_logic
        {%- endif %}
        {%- endif %}
    );
end entity {{ name }}_{{neur_idx}};


architecture Behavioral of {{ name }}_{{neur_idx}} is
    type state_type is (IDLE, LOAD, {%- if weight_file is false %} BINARIZE, {%- endif %}{% for i in range(num_stages) %} COMPUTE_STAGE_{{ i }}, {% endfor %} ADD_BIAS, ACTIVATE, FINISH);
    signal current_state, next_state : state_type := IDLE;

    {%- if is_serialized is true and other_neuron is false %}
    {%- if full_output is true %}
    signal output_reg_1, output_reg_1_next : signed({{ o_bitwidth - 1 }} downto 0) := (others => '0');
    signal output_reg_2, output_reg_2_next : std_logic := '0';
    {%- else %}
    signal output_reg, output_reg_next     : std_logic := '0';
    {%- endif %}

    {%- elif is_serialized is true and other_neuron is true %}
    {%- if full_output is true %}
    {%- if one_layer is true %}
    signal output_reg, output_reg_next     : signed({{ o_bitwidth - 1 }} downto 0) := (others => '0');
    {%- else %}
    signal output_reg, output_reg_next     : std_logic := '0';
    {%- endif %}
    {%- else %} 
    signal output_reg, output_reg_next     : std_logic := '0';
    {%- endif %}

    {%- else %}
    {%- if full_output is true %}
    signal output_reg, output_reg_next     : signed({{ o_bitwidth-1 }} downto 0) := (others => '0');
    {%- else %}
    signal output_reg, output_reg_next     : std_logic := '0';
    {%- endif %}
    {%- endif %}

    signal done_reg, done_reg_next         : std_logic := '0';

    type matrix_type is array ( 0 to {{ num_stages }}, 0 to data_width-1 ) of signed({{w_bitwidth-1}} downto 0);
    {%- if weight_file is false %}
    type reg_bank is array (0 to data_width) of signed(7 downto 0);
    signal first_regs                      : reg_bank := (others => (others => '0'));
    {%- endif %}
    signal stages, stages_next             : matrix_type := (others => (others => (others => '0')));
    signal sum                             : signed( {{ w_bitwidth - 1 }} downto 0) := (others => '0');

begin

    -- State register
    process(clk{%- if is_serialized is false and weight_file is true %}, rst {%- endif %})
    begin

        {%-if is_serialized is false and weight_file is true %}
        if rst = '1' then
            current_state <= IDLE;
            sum           <= (others => '0');
            {%- if weight_file is false %}
            first_regs    <= (others => (others => '0'));
            {%- endif %}
            stages        <= (others => (others => (others => '0')));
            done_reg      <= '0';
            {%- if is_serialized is true and other_neuron is false %}
            {%- if full_output is true %}
            output_reg_1  <= (others => '0');
            output_reg_2  <= '0';
            {%- else %}
            output_reg    <= '0';
            {%- endif %}

            {%- elif is_serialized is true and other_neuron is true %}
            {%- if full_output is true %}
            {%- if one_layer is true %}
            output_reg    <= (others => '0');
            {%- else %}
            output_reg    <= '0';
            {%- endif %}
            {%- else %}
            output_reg    <= '0';
            {%- endif %}

            {%- else %}

            {%- if full_output is true %}
            output_reg    <= (others => '0');
            {%- else %}
            output_reg    <= '0';
            {%- endif %}
            {%- endif %}

        elsif rising_edge(clk) then
            
            current_state <= next_state;
            stages <= stages_next;
            done_reg <= done_reg_next;

            {%- if is_serialized is true and other_neuron is false %}
            {%- if full_output is true %}
            output_reg_1 <= output_reg_1_next;
            output_reg_2 <= output_reg_2_next;
            {%- else %}
            output_reg   <= output_reg_next;
            {%- endif %}

            {%- elif is_serialized is true and other_neuron is true %}
            output_reg <= output_reg_next;
            {%- else %}

            {%- if full_output is true %}
            output_reg <= output_reg_next;
            {%- else %}
            output_reg <= output_reg_next;
            {%- endif %}
            {%- endif %}

            {%- if weight_file is true %}
            if current_state = LOAD then
                {%- for line in weight_loading %}
                {{ line }}
                {%- endfor %}
            end if;

            if current_state = ADD_BIAS then
            {%- if is_serialized is true %}
                sum <= stages({{num_stages}}, 0) + resize(biases_{{ bias_idx }}({%- if different_files is true %}{{neur_idx}}{%- else %} bias_index + current_neuron{%- endif %}), {{w_bitwidth}});
            {%- else %}
                sum <= stages({{num_stages}}, 0) + resize(biases({%- if different_files is true %}{{neur_idx}}{%- else %} bias_index + current_neuron{%- endif %}), {{w_bitwidth}});
            {%- endif %}
            end if;
            
            {%- else %}
            
            if current_state = LOAD then
                if load_en = '1' then
                    first_regs(input_idx) <= data;
                end if;
            end if;

            if current_state = BINARIZE then 
                {%- for line in weight_loading %}
                {{ line }}
                {%- endfor %}
            end if;

            if current_state = ADD_BIAS then
                sum <= stages({{num_stages}}, 0) + resize(first_regs(data_width), {{w_bitwidth}});                
            end if;
            {%- endif %}
        end if;
    
        {%- else %}

        if rising_edge(clk) then 

            if rst = '1' then
                current_state <= IDLE;
                sum           <= (others => '0');
                {%- if weight_file is false %}
                first_regs    <= (others => (others => '0'));
                {%- endif %}
                stages        <= (others => (others => (others => '0')));
                done_reg      <= '0';
                {%- if is_serialized is true and other_neuron is false %}
                {%- if full_output is true %}
                output_reg_1  <= (others => '0');
                output_reg_2  <= '0';
                {%- else %}
                output_reg    <= '0';
                {%- endif %}

                {%- elif is_serialized is true and other_neuron is true %}
                {%- if full_output is true %}
                {%- if one_layer is true %}
                output_reg    <= (others => '0');
                {%- else %}
                output_reg    <= '0';
                {%- endif %}
                {%- else %}
                output_reg    <= '0';
                {%- endif %}

                {%- else %}

                {%- if full_output is true %}
                output_reg    <= (others => '0');
                {%- else %}
                output_reg    <= '0';
                {%- endif %}
                {%- endif %}
            else

                current_state <= next_state;
                stages <= stages_next;
                done_reg <= done_reg_next;

                {%- if is_serialized is true and other_neuron is false %}
                {%- if full_output is true %}
                output_reg_1 <= output_reg_1_next;
                output_reg_2 <= output_reg_2_next;
                {%- else %}
                output_reg   <= output_reg_next;
                {%- endif %}

                {%- elif is_serialized is true and other_neuron is true %}
                output_reg <= output_reg_next;
                {%- else %}

                {%- if full_output is true %}
                output_reg <= output_reg_next;
                {%- else %}
                output_reg <= output_reg_next;
                {%- endif %}
                {%- endif %}

                {%- if weight_file is true %}
                if current_state = LOAD then
                    {%- for line in weight_loading %}
                    {{ line }}
                    {%- endfor %}
                end if;

                if current_state = ADD_BIAS then
                {%- if is_serialized is true %}
                    sum <= stages({{num_stages}}, 0) + resize(biases_{{ bias_idx }}({%- if different_files is true %}{{neur_idx}}{%- else %} bias_index + current_neuron{%- endif %}), {{w_bitwidth}});
                {%- else %}
                    sum <= stages({{num_stages}}, 0) + resize(biases({%- if different_files is true %}{{neur_idx}}{%- else %} bias_index + current_neuron{%- endif %}), {{w_bitwidth}});
                {%- endif %}
                end if;
                
                {%- else %}
                
                if current_state = LOAD then
                    if load_en = '1' then
                        first_regs(input_idx) <= data;
                    end if;
                end if;

                if current_state = BINARIZE then 
                    {%- for line in weight_loading %}
                    {{ line }}
                    {%- endfor %}
                end if;

                if current_state = ADD_BIAS then
                    sum <= stages({{num_stages}}, 0) + resize(first_regs(data_width), {{w_bitwidth}});                
                end if;
                {%- endif %}
            end if;
        end if;
    {%- endif %}
    end process;

    -- Next state logic 
    process(current_state, start,{%-if is_serialized is true %}{%- if weight_file is false %}load_en, done_load, input_idx, data,{%- endif %}{%- else %}{%- if weight_file is false %}load_en, done_load, input_idx, data,{%- endif %}{%- endif %}stages, sum, {%- if is_serialized is true and other_neuron is false %}{%- if full_output is true %}output_reg_1, output_reg_2{%- else %}output_reg{%- endif %}{%- elif is_serialized is true and other_neuron is true %}output_reg{%- else %}{%- if full_output is true %}output_reg{%- else %}output_reg{%- endif %}{%- endif %}, done_reg)
    begin
        next_state <= current_state;
        stages_next <= stages;
        done_reg_next <= done_reg;
        {%- if is_serialized is true and other_neuron is false %}
        {%- if full_output is true %}
        output_reg_1_next <= output_reg_1;
        output_reg_2_next <= output_reg_2;
        {%- else %}
        output_reg_next   <= output_reg;
        {%- endif %}

        {%- elif is_serialized is true and other_neuron is true %}
        output_reg_next <= output_reg;
        {%- else %}

        {%- if full_output is true %}
        output_reg_next <= output_reg;
        {%- else %}
        output_reg_next <= output_reg;
        {%- endif %}
        {%- endif %}

        case current_state is
            when IDLE =>
                if start = '1' then
                    next_state <= LOAD; 
                end if;

            {%- if weight_file is true %}

            when LOAD =>
                next_state <= COMPUTE_STAGE_0;
            {%- else %}

            when LOAD =>
                if load_en = '1' then 
                    if done_load = '1' then 
                        next_state <= BINARIZE;
                    end if;
                end if;

            when BINARIZE =>
                next_state <= COMPUTE_STAGE_0;
            {%- endif %}

            {% for i in range(num_stages) %}
            when COMPUTE_STAGE_{{ i }} =>
                {%- for line in reduction_addition %}
                {%- if loop.index0 >= i*limit and loop.index0 <= (i+1)*limit-1 %}
                {{ line | replace("{{ i+1 }}", (i+1)|string) | replace("{{ i }}", (i)|string) }}
                {%- endif %}
                {%- endfor %}
                {% if loop.last %}
                next_state <= ADD_BIAS;
                {% else %}
                next_state <= COMPUTE_STAGE_{{ i+1 }};
                {% endif %}
            {% endfor %}

            when ADD_BIAS =>
                next_state <= ACTIVATE;

            when ACTIVATE =>
                {%- for line in activation_logic %}
                {{line}}
                {%- endfor %}
                done_reg_next <= '1';
                next_state <= FINISH;

            when FINISH =>
                if start = '0' then
                done_reg_next <= '0';
                next_state <= IDLE;
                else
                done_reg_next <= '1';
                next_state <= FINISH;
                end if;

            when others =>
                next_state <= IDLE;
        end case;
    end process;
    
    done <= done_reg;


    {%- if is_serialized is true and other_neuron is false %}
    {%- if full_output is true %}
    output_final <= output_reg_1;
    output_bit   <= output_reg_2; 
    {%- else %}
    output_bit   <= output_reg;
    {%- endif %}

    {%- elif is_serialized is true and other_neuron is true %}
    {%- if full_output is true %}
    {%- if one_layer is true %}
    output_final <= output_reg;
    {%- else %}
    output_bit   <= output_reg;
    {%- endif %}
    {%- else %}
    output_bit <= output_reg;
    {%- endif %}

    {%- else %}

    {%- if full_output is true %}
    output_final <= output_reg;
    {%- else %}
    output_bit   <= output_reg;
    {%- endif %}
    {%- endif %}


end Behavioral;


 