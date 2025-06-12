library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rom_control is
    port (
        clk               : in  std_logic;
        rst               : in  std_logic;
        start             : in  std_logic;
        ram_dout          : in  signed({{ word_size - 1 }} downto 0); 
        input_break       : in  natural;
        neuron_break      : in  natural;
        ram_addr          : out std_logic_vector({{ addr_size - 1 }} downto 0);
        neuron_in_data    : out signed({{ file_bitwidth - 1 }} downto 0);
        neuron_in_index   : out natural;
        load_enable       : out std_logic_vector({{ inferred_neurons_max - 1 }} downto 0);
        done              : out std_logic
    );
end entity;

architecture Behavioral of rom_control is
    type state_type is (IDLE, DUMMY, READ, SPLIT_0, SPLIT_1, SPLIT_2, SPLIT_3, CHECK, COMPLETE);
    signal state, state_next : state_type := IDLE;

    signal addr_counter, addr_counter_next : natural range 0 to {{ end_RAM - 1 }} := 0;
    signal input_idx, inp_idx_next         : natural range 0 to {{ data_per_neuron_max }} := 0;
    signal neuron_idx, neuron_idx_next     : natural range 0 to {{ inferred_neurons_max }} := 0;
    signal byte_cnt, byte_cnt_next         : natural range 0 to {{ data_per_neuron_max }} := 0; 
    
    signal load_enable_temp                : std_logic_vector({{ inferred_neurons_max - 1 }} downto 0) := (others => '0');
    signal temp_word                       : signed ({{ word_size - 1 }} downto 0) := (others => '0');
    signal temp_data                       : signed({{ file_bitwidth - 1 }} downto 0);
    signal flag_temp                       : std_logic := '0';

begin

    ram_addr        <= std_logic_vector(to_unsigned(addr_counter, {{ addr_size }}));
    neuron_in_data  <= temp_data;
    neuron_in_index <= input_idx;
    load_enable     <= load_enable_temp;
    done <= flag_temp;


    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state           <= IDLE;
                addr_counter    <= 0;
                temp_word       <= (others => '0');
                neuron_idx      <= 0;
                input_idx       <= 0;
                byte_cnt        <= 0;
            else
                state           <= state_next;
                addr_counter    <= addr_counter_next;
                neuron_idx      <= neuron_idx_next;
                input_idx       <= inp_idx_next;
                byte_cnt        <= byte_cnt_next;
                if state = READ then 
                    temp_word       <= ram_dout;
                end if;
            end if;
        end if;
    end process;

    
    process(state, start, addr_counter, neuron_idx, input_idx, byte_cnt, input_break, neuron_break, temp_word)
    begin
        state_next         <= state;
        addr_counter_next  <= addr_counter;
        neuron_idx_next    <= neuron_idx;
        inp_idx_next       <= input_idx;
        byte_cnt_next      <= byte_cnt;
        temp_data          <= (others => '0');
        load_enable_temp   <= (others => '0');
        flag_temp          <= '0';


        case state is
            when IDLE =>
                if start  = '1' then
                    neuron_idx_next    <=    0;
                    inp_idx_next       <=    0;
                    byte_cnt_next      <=    0;
                    state_next         <= READ;
                end if;

            when READ  =>
                state_next         <= SPLIT_0;

            when SPLIT_0 =>
                load_enable_temp(neuron_idx)     <= '1';
                if byte_cnt < input_break then
                    temp_data                    <= temp_word(7 downto 0);
                    if byte_cnt < input_break-1 then
                        inp_idx_next             <= input_idx + 1;
                    else 
                        flag_temp                <= '1';
                    end if;
                    byte_cnt_next                <= byte_cnt + 1;
                    state_next                   <= SPLIT_1;
                else 
                    state_next                   <= CHECK;
                end if;


            when SPLIT_1 =>
                load_enable_temp(neuron_idx)     <= '1';
                if byte_cnt < input_break then
                    temp_data                    <= temp_word(15 downto 8);
                    if byte_cnt < input_break-1 then
                        inp_idx_next             <= input_idx + 1;
                    else 
                        flag_temp                <= '1';
                    end if;
                    byte_cnt_next                <= byte_cnt + 1;
                    state_next                   <= SPLIT_2;
                else 
                    state_next                   <= CHECK;
                end if;

            when SPLIT_2 =>
                load_enable_temp(neuron_idx)     <= '1';
                if byte_cnt < input_break then
                    temp_data                    <= temp_word(23 downto 16);
                    if byte_cnt < input_break-1 then
                        inp_idx_next             <= input_idx + 1;
                    else 
                        flag_temp                <= '1';
                    end if;
                    byte_cnt_next                <= byte_cnt + 1;
                    state_next                   <= SPLIT_3;
                else 
                    state_next                   <= CHECK;
                end if;
 
            when SPLIT_3 =>
                    load_enable_temp(neuron_idx)  <= '1';
                    temp_data                    <= temp_word(31 downto 24);
                    byte_cnt_next                <= byte_cnt + 1;
                    if byte_cnt < input_break-1 then
                        inp_idx_next             <= input_idx + 1;
                    else 
                        flag_temp                <= '1';
                    end if;
                    state_next                   <= CHECK;


            when CHECK =>
                if byte_cnt = input_break then
                    if neuron_idx < neuron_break - 1 then

                        neuron_idx_next   <= neuron_idx + 1;
                        byte_cnt_next     <= 0;
                        inp_idx_next      <= 0;
                        state_next        <= DUMMY;
                    else

                        flag_temp         <= '1';
                        state_next        <= COMPLETE;
                    end if;
                else
                    state_next            <= DUMMY;
                end if;
                
                if addr_counter < {{ end_RAM - 1 }} then
                    addr_counter_next     <= addr_counter + 1;
                end if;

            when DUMMY => 
                state_next <= READ;

            when COMPLETE =>
                flag_temp  <= '1';
                state_next <= IDLE;

            when others =>
                state_next <= IDLE;
        end case;
    end process;

end Behavioral;
