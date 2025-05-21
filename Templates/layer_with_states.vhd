library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.TYPE_DEF.ALL;

entity {{ layer_name }} is
    generic(
        layer_number: natural{%- if layer_reuses | length >= 2 %};
        start_index : natural
        {%- endif %}
          -- I can change this to make it a costant changed by python (can keep this here if i would like multiple serialized layers with fixed deadlines)
    );

    Port (
        clk               : in std_logic;
        rst               : in std_logic;
        inputs            : in std_logic_vector ({{max_data_width-1}} downto 0);
        {%- if first_layer is true or handshake is true %}
        start             : in std_logic; -- '1' when inputs have been retrieved (might extend it to include weight and bias retrieval)
        {%- endif %}
        {%- if handshake is true %}
        done              : out std_logic;
        {%- endif %}
        {%- if full_output is true %}
        outputs           : out output ({{out_neuron_number - 1}} downto 0)
        {%- else %}
        outputs           : out std_logic_vector ({{ out_neuron_number - 1}} downto 0)
        {%- endif %}
--        finish            : out std_logic
    );
end {{ layer_name }};

architecture Behavioral of {{ layer_name }} is

    type state_type is (IDLE, INITIATE,{%- if less_neurons is true %} WAIT_N_DONE, CHECK_REPEAT, UPDATE_REPEAT, UPDATE_DONE,{%- else %} WAIT_L_DONE,{%- endif %}{%- if one_layer is false %} CLEAR_INPUTS, COPY_OUTPUTS,{%- endif %}{%- if one_layer is true and output_bit is true %} COPY_OUTPUTS,{%- endif %} COMPLETE, UPDATE_INDEXES, TERMINATE);
    signal state, next_state                      : state_type := IDLE;
    signal start_neuron, start_neuron_nxt         : std_logic := '0';
    signal connection_in, connection_in_nxt       : std_logic_vector({{ max_data_width - 1 }} downto 0) := (others => '0');

    {%- if less_neurons is true %}
    {%- if output_bit is true %}
    signal connection_out, connection_out_nxt     : std_logic_vector({{ max_neuron_number- 1 }} downto 0) := (others => '0');
    {%- endif %}
    {%- else %}
    {%- if output_bit is true %}
    signal connection_out                         : std_logic_vector({{ max_neuron_number- 1 }} downto 0) := (others => '0');
    {%- endif %}
    {%- endif %}
    
    signal start_weight, start_weight_nxt         : natural range 0 to {{ range_max - 1 }} := 0;
    signal bias_index, bias_index_nxt             : natural range 0 to {{ range_max - 1 }} := 0;
    
    {%- if less_neurons is true %}
    {%- if output_bit is true %}
    signal neuron_slice_out                       : std_logic_vector({{ fixed_neurons_num -1 }} downto 0) := (others => '0');
    {%- endif %}
    {%- if output_f is true %}
    signal output_part                            : output({{fixed_neurons_num -1}} downto 0) := (others => (others => '0' ));
    {%- endif %}
    signal neuron_slice_done                      : std_logic_vector({{ fixed_neurons_num -1}} downto 0) := (others => '0');
   
    signal overflow_counter, overflow_counter_nxt : natural range 0 to {{ max_overflow_count - 1 }} := 0;
    {%- endif %}
    signal layer_count, layer_count_nxt           : integer range 0 to layer_number := 0;
    signal last_layer, last_layer_nxt             : std_logic := '0';
    {%- if less_neurons is false %}
    signal neuron_done                            : std_logic_vector({{ max_neuron_number - 1 }} downto 0) := (others => '0');
    {%- endif %}

    {%- if less_neurons is true %}
    {%- if full_output is true %}
    signal outputs_cp, outputs_cp_nxt             : output({{ out_neuron_number - 1}} DOWNTO 0) := (others => (others => '0'));
    {%- endif %}
    {%- else %}
    {%- if full_output is true %}
    signal outputs_cp                             : output({{ out_neuron_number - 1}} downto 0) := (others => (others => '0')); 
    {%- endif %}
    {%- endif %}

    {%- if less_neurons is true %}
    constant ALL_ONES                             : std_logic_vector({{ fixed_neurons_num - 1 }} downto 0) := (others => '1');
    {%- else %}
    constant ALL_ONES                             : std_logic_vector({{ max_neuron_number - 1 }} downto 0) := (others => '1');
    {%- endif %}


begin

    -- === Neuron Instantiations ===
    {%- if less_neurons is true %}

    {%- for i in range(fixed_neurons_num) %}
    neuron_inst_{{ i }} : entity work.neuron_{{layer_idx}}
        generic map (
            current_neuron => {{ i }},
            data_width    => {{ max_data_width }}
        )
        port map (
            clk          => clk,
            rst          => rst,
            inputs       => connection_in,
            {%- if weight_file is false %}
            weights      => -- qui metti le cose giuste,
            biases       => -- qui metti le cose giuste,
            {%- else %}
            bias_index   => bias_index,
            start_weight => start_weight,
            {%- endif %}
            start        => start_neuron,
            done         => neuron_slice_done({{ i }}),
            {%- if output_f is true %}
            output_final => output_part({{ fixed_neurons_num - i - 1 }}){% if output_f and output_bit %},{% endif %}
            {%- endif %}
            {%- if output_bit is true %}
            output_bit   => neuron_slice_out({{ fixed_neurons_num - i - 1 }})
            {%- endif %}           
        );
    {%- endfor %}

 {%- else %}

{%- for i in range(out_neuron_number) %}
neuron_inst_{{ i }} : entity work.neuron_{{ neur_idx }}
    generic map (
        current_neuron => {{ i }},
        data_width     => {{ max_data_width }}
    )
    port map (
        clk          => clk,
        rst          => rst,
        inputs       => connection_in,
        {%- if weight_file is false %}
        weights      => -- weights 
        biases       => -- biases 
        {%- else %}
        bias_index   => bias_index,
        start_weight => start_weight,
        {%- endif %}
        start        => start_neuron,
        done         => neuron_done({{ i }}),
        {%- if output_f is true %}
        output_final => outputs_cp({{ out_neuron_number - i - 1 }}){% if output_f and output_bit %},{% endif %}
        {%- endif %}
        {%- if output_bit is true %}
        output_bit   => connection_out({{ max_neuron_number - i - 1 }})
        {%- endif %}
    );
{%- endfor %}

-- === Other Neurons (no output_final) ===
{%- for i in range(out_neuron_number, max_neuron_number) %}
neuron_inst_{{ i }} : entity work.neuron_{{ neur_idx + 1 }}
    generic map (
        current_neuron => {{ i }},
        data_width     => {{ max_data_width }}
    )
    port map (
        clk          => clk,
        rst          => rst,
        inputs       => connection_in,
        {%- if weight_file is false %}
--        weights      =>  weights,    This is for eventually loading weights from memory
--        biases       =>  biases,     This is for eventually loading weights from memory
        {%- else %}                         
        bias_index   => bias_index,
        start_weight => start_weight,
        {%- endif %}
        start        => start_neuron,
        done         => neuron_done({{ i }}),
        output_bit   => connection_out({{ max_neuron_number  - i - 1 }})
    );
{%- endfor %}
{%- endif %}

    -- === FSM Process ===

process(clk,rst)
begin
    if rst = '1' then
        state          <= IDLE;
        start_neuron   <= '0';
        connection_in  <= (others => '0');
        {%- if less_neurons is true %}
        {%- if output_bit is true %}
        connection_out <= (others => '0');
        {%- endif %}
        {%- endif %}

        layer_count  <= 0;
        last_layer   <= '0';
        start_weight <= 0;
        bias_index   <= 0;

        {%- if less_neurons is true %}
        {%- if full_output is true %}
        outputs_cp   <= (others => (others => '0'));
        {%- endif %}
        {%- endif %}

        {%- if less_neurons is true %}
        overflow_counter <= 0;
        {%- endif %}
        
        {%- if full_output is true %}
        outputs       <= (others => (others => '0'));
        {%- else %}
        outputs       <=  (others => '0');
        {%- endif %}

        {%- if handshake is true %}
        done          <= '0';
        {%- endif %}

    elsif rising_edge(clk) then 
        state            <= next_state;
        start_neuron     <= start_neuron_nxt;
        connection_in    <= connection_in_nxt;
        {%- if less_neurons is true %}
        {%- if output_bit is true %}
        connection_out   <= connection_out_nxt;
        {%- endif %}
        {%- endif %}

        layer_count      <= layer_count_nxt;
        last_layer       <= last_layer_nxt;
        start_weight     <= start_weight_nxt;
        bias_index       <= bias_index_nxt;

        {%- if less_neurons is true %}
        {%- if full_output is true %}
        outputs_cp       <= outputs_cp_nxt;
        {%- endif %}
        overflow_counter <= overflow_counter_nxt;
        {%- endif %}
        if state = TERMINATE then
            {%- if full_output is true %}
            outputs      <= outputs_cp;
            {%- else %}
            outputs      <= connection_in({{ data_widths[0] - 1 }} downto  {{ data_widths[0] - out_neuron_number }});
            {%- endif %}
        {%- if handshake is true %}
            done         <= '1';
        else
            done         <= '0';
        {%- endif %}
        end if;
    end if;
end process;


process(state, start, start_neuron, last_layer,{%- if less_neurons is true %} neuron_slice_done,{%- if output_bit is true %} neuron_slice_out,{%- endif %} overflow_counter, {%- if full_output is true %}outputs_cp, output_part,{%- endif %}{%- else %} neuron_done,{%- endif %} layer_count, inputs, bias_index, start_weight, connection_in {%- if output_bit is true %}, connection_out {%- endif %})

    variable tmp_state            : state_type;
    variable tmp_start_neuron     : std_logic;    
    variable tmp_connection_in    : std_logic_vector({{ max_data_width - 1 }} downto 0);
    {%- if less_neurons is true %}
    variable tmp_connection_out   : std_logic_vector({{ max_neuron_number - 1 }} downto 0);
    {%- endif %}
    variable tmp_layer_count      : integer range 0 to layer_number;
    variable tmp_last_layer       : std_logic;
    variable tmp_start_weight     : natural;
    variable tmp_bias_index       : natural;

    {%- if less_neurons is true %}
    {%- if full_output is true %}
    variable tmp_outputs_cp       : output({{ out_neuron_number - 1 }} downto 0);
    {%- endif %}
    {%- endif %}
 
    {%- if less_neurons is true %}
    variable tmp_overflow_counter : natural := 0; 
    {%- endif %}
begin 

    tmp_state            := state;
    tmp_start_neuron     := start_neuron;
    tmp_connection_in    := connection_in;

    {%- if less_neurons is true %}
    {%- if output_bit is true %}
    tmp_connection_out   := connection_out;
    {%- endif %}
    tmp_overflow_counter := overflow_counter; 
    {%- endif %}

    tmp_layer_count      := layer_count;
    tmp_last_layer       := last_layer;
    tmp_start_weight     := start_weight;
    tmp_bias_index       := bias_index;
    {%- if less_neurons is true %}
    {%- if full_output is true %}
    tmp_outputs_cp       := outputs_cp;    
    {%- endif %}
    {%- endif %}

    case state is 

        when IDLE =>
            if start = '1' then
                tmp_connection_in := inputs;
                tmp_state := INITIATE;
            end if;

        when INITIATE =>
            tmp_last_layer   := '1' when (layer_count + 1 = layer_number) else '0';
            tmp_start_neuron := '1';
            {%- if less_neurons is true %}
            tmp_state        := WAIT_N_DONE;
            {%- else %}
            tmp_state        := WAIT_L_DONE;
            {%- endif %}
        
        {%- if less_neurons is true %}
        
        when WAIT_N_DONE =>
            if neuron_slice_done = ALL_ONES then 
            tmp_start_neuron := '0';
            tmp_state := CHECK_REPEAT;
            else
            tmp_start_neuron := '1';
            tmp_state := WAIT_N_DONE;
            end if;

        when CHECK_REPEAT =>
            case layer_count is
            {%- for layer_idx, layer in enumerate(chosen_layers) %}
            {%- if not (full_output is true and loop.last) %}
                when {{ layer_idx }} =>
                    case overflow_counter is
                    {%- for step_idx, step in enumerate(layer) %}
                        when {{ step_idx }} =>
                            {%- if step.slice_type == "full" %}
                            tmp_connection_out({{ step.end_bit }} downto {{ step.start_bit }}) := neuron_slice_out;
                            tmp_state := {% if not loop.last %}UPDATE_REPEAT{% else %}UPDATE_DONE{% endif %};
                            {%- else %}
                            tmp_connection_out({{ step.end_bit }} downto {{ step.start_bit }}) := neuron_slice_out({{ step.partial_range[0] }} downto {{ step.partial_range[1] }});
                            tmp_state := UPDATE_DONE;
                            {%- endif %}
                    {%- endfor %}
                        when others =>
                            tmp_state := IDLE;
                    end case;
            {%- endif %}
            {%- endfor %}
                {%- if full_output is true %}
                when {{ chosen_layers | length - 1 }} =>
                    case overflow_counter is
                        {%- for r in range(last_repeats) %}
                        when {{ r }} =>
                            tmp_outputs_cp({{ out_neuron_number - 1 - r * fixed_neurons_num }} downto {{ out_neuron_number - (r + 1) * fixed_neurons_num }}) := output_part;
                            tmp_state := {% if last_remainder == 0 and r == last_repeats - 1 %}UPDATE_DONE{% else %}UPDATE_REPEAT{% endif %};
                        {%- endfor %}
                        {%- if last_remainder > 0 %}
                        when {{ last_repeats }} =>
                            tmp_outputs_cp({{ last_remainder - 1 }} downto 0) := output_part({{ fixed_neurons_num - 1 }} downto {{ fixed_neurons_num - last_remainder }});
                            tmp_state := UPDATE_DONE;
                        {%- endif %}
                        when others =>
                            tmp_state := IDLE;
                    end case;
                {%- endif %}
                when others =>
                    tmp_state := IDLE;
            end case;

        when UPDATE_REPEAT =>
            tmp_overflow_counter := overflow_counter + 1;
            tmp_start_weight     := start_weight + {{ fixed_neurons_num }};
            tmp_bias_index       := bias_index + {{ fixed_neurons_num }};
            tmp_state            := INITIATE;

        when UPDATE_DONE =>
            tmp_overflow_counter := 0;
            {%- if one_layer is true %}
            {%- if output_bit is true %}
            tmp_state := COPY_OUTPUTS;
            {%- else %}
            tmp_state := COMPLETE;
            {%- endif %}
            {%- else %}
            tmp_state := CLEAR_INPUTS;
            {%- endif %}
        {%- else %}
        

        when WAIT_L_DONE =>
            if neuron_done = ALL_ONES then 
                tmp_start_neuron := '0';
                {%- if one_layer is true and output_bit is true %}
                tmp_state        := COPY_OUTPUTS;
                {%- elif one_layer is true %}
                tmp_state        := COMPLETE;
                {%- else %}
                tmp_state        := CLEAR_INPUTS;
                {%- endif %}
            else 
                tmp_start_neuron := '1';
                tmp_state        := WAIT_L_DONE;
            end if;

        {%- endif %}

        {%- if one_layer is false %}

        when CLEAR_INPUTS =>
            tmp_connection_in := (others => '0');
            tmp_state := COPY_OUTPUTS;

        when COPY_OUTPUTS =>
            case layer_count is
            {%- set total_width = data_widths[0] %}
            {%- for idx in range(1, layer_number ) %}
                when {{ idx - 1 }} =>
                    tmp_connection_in({{ total_width - 1 }} downto {{ total_width - data_widths[idx] }}) := connection_out({{ max_neuron_number - 1 }} downto {{ max_neuron_number - data_widths[idx] }});
            {%- endfor %}
                when others =>
                    tmp_state := IDLE;
            end case;
            tmp_state := COMPLETE;
        {%- endif %}

        {%- if one_layer is true and output_bit is true %}
        
        when COPY_OUTPUTS =>
            {%- set total_width = data_widths[0] %}
            tmp_connection_in({{ total_width - 1 }} downto {{ total_width - out_neuron_number }}) := connection_out({{ max_neuron_number - 1 }} downto {{ max_neuron_number - out_neuron_number }});
            tmp_state := COMPLETE;
        {%- endif %}

        when COMPLETE =>
            if last_layer ='1' then
                tmp_layer_count := 0;
                tmp_state := TERMINATE;
            else
                tmp_layer_count := layer_count+1;
                tmp_state       := UPDATE_INDEXES;
            end if;

        when UPDATE_INDEXES => 
            {%- if less_neurons is true %}
            tmp_start_weight := start_weight + {{ fixed_neurons_num }};
            tmp_bias_index   := bias_index + {{ fixed_neurons_num }};
            {%- else %}
            tmp_start_weight := start_weight + {{ max_neuron_number }};
            tmp_bias_index   := bias_index + {{ max_neuron_number }};
            {%- endif %}
            tmp_state        := INITIATE;

        when TERMINATE => 
            tmp_last_layer  := '0';
            tmp_state       := IDLE;

        when others =>
            tmp_state := IDLE;
        end case;

        next_state           <= tmp_state;
        start_neuron_nxt     <= tmp_start_neuron;
        connection_in_nxt    <= tmp_connection_in;
        {%- if less_neurons is true %}
        {%- if output_bit is true %}
        connection_out_nxt   <= tmp_connection_out;
        {%- endif %}
        overflow_counter_nxt <= tmp_overflow_counter;
        {%- endif %}
        layer_count_nxt      <= tmp_layer_count;
        last_layer_nxt       <= tmp_last_layer;
        start_weight_nxt     <= tmp_start_weight;
        bias_index_nxt       <= tmp_bias_index;
        {%- if less_neurons is true %}
        {%- if full_output is true %}
        outputs_cp_nxt       <= tmp_outputs_cp;
        {%- endif %}
        {%- endif %}

    end process;


end Behavioral;



