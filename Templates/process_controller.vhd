library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.TYPE_DEF.all;

entity process_controller is
    generic(
        MEMORY_ADDR_SIZE  : INTEGER :=16
    );
    Port (
        clk               : in std_logic;
        rst               : in std_logic;
        start_db          : in std_logic;
        doa_memory        : in std_logic_vector (31 downto 0 );
        nn_output         : in output (0 to {{ output_neurons - 1 }}); -- This is needed beacause UART send lsb first
        {%- if handshake is true %}
		nn_done           : in std_logic;
        {%- endif %}
        en_register       : out std_logic;
        data_loader_reg   : out unsigned ({{ file_bitwidth - 1 }} downto 0);
        ena_memory        : out std_logic;
        wea_memory        : out std_logic;
        dia_memory        : out std_logic_vector (31 downto 0);
        mem_addr          : out std_logic_vector (15 downto 0);
        finish            : out std_logic
        );
end process_controller;

architecture Behavioral of process_controller is
    constant ADDR_COUNT_SIZE           : integer                                := MEMORY_ADDR_SIZE; -- The size of the memory address counter
    constant ADDR_COUNT_MIN            : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned(0, ADDR_COUNT_SIZE); -- Initial address of the memory
    constant ADDR_COUNT_UPLOAD_START   : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned({{ start_input }}, ADDR_COUNT_SIZE); -- First pixel address of the memory for the download image
    constant ADDR_COUNT_UPLOAD_END     : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned({{ end_input }}, ADDR_COUNT_SIZE); -- Last pixel address of the memory for the download image
    constant ADDR_COUNT_DOWNLOAD_START : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned({{ start_output }}, ADDR_COUNT_SIZE); -- First pixel address of the memory for the upload image
    constant ADDR_COUNT_DOWNLOAD_END   : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned({{ end_output }}, ADDR_COUNT_SIZE); -- Last pixel address of the memory for the upload image
    constant ADDR_COUNT_MAX            : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned(65535, ADDR_COUNT_SIZE); -- Final address of the memory

    type state_type is (START, UPLOAD_B0, UPLOAD_B1, UPLOAD_B2, UPLOAD_B3, UPLOAD_WAIT, UPLOAD_CHECK, WAIT_FOR_OUTPUT, WRITE_OUTPUT, PROCESS_COMPLETED);
    signal state, state_next : state_type;

    signal addr_count, addr_count_next : unsigned(15 downto 0);
    {%- if handshake is false %}
    signal counter,counter_next: integer range 0 to {{ counter_max }};
    {%- endif %}
    signal output_count, output_count_next: integer range 0 to {{ output_neurons - 1 }} := 0;
    

begin
    
    mem_addr <= std_logic_vector(addr_count);
    
    process(state, addr_count, doa_memory, start_db,{%- if handshake is true %} nn_done,{%- else %} counter,{%- endif %} output_count)
    begin
        
        state_next         <= state;
        addr_count_next    <= addr_count;
        ena_memory         <= '0';
        wea_memory         <= '0';
        finish             <= '0';
        {%- if handshake is false %}
        counter_next       <=  0;
        {%- endif %}
        data_loader_reg    <= (others=>'0');
        output_count_next  <= 0;
        dia_memory         <= (others =>'0');
        en_register        <= '0';

        case state is
            when START =>
                --data_buffer_next <= (others => '0');
                if start_db  = '1' then
                addr_count_next    <= ADDR_COUNT_MIN;
                state_next         <= UPLOAD_WAIT;
                else 
                state_next         <= START;
                end if;

            when UPLOAD_WAIT =>
                ena_memory         <= '1';
                --en_register      <= '1'; 
                state_next <= UPLOAD_B0;

            when UPLOAD_B0 =>
                ena_memory        <= '1';
                en_register       <= '1';
                data_loader_reg   <= unsigned(doa_memory ({{ file_bitwidth - 1 }} downto 0));
                state_next        <= UPLOAD_B1;

            when UPLOAD_B1 =>
                ena_memory        <= '1';
                en_register       <= '1';
                data_loader_reg   <= unsigned(doa_memory ({{ 2*file_bitwidth - 1 }} downto {{ file_bitwidth }}));
                state_next        <= UPLOAD_B2;

            when UPLOAD_B2 =>
                ena_memory        <= '1';
                en_register       <= '1';
                data_loader_reg   <= unsigned(doa_memory ({{ 3*file_bitwidth - 1 }} downto {{ 2*file_bitwidth }}));
                state_next        <= UPLOAD_B3;
 
            when UPLOAD_B3 =>
                ena_memory        <= '1';
                en_register       <= '1';
                data_loader_reg   <= unsigned(doa_memory ({{ 4*file_bitwidth - 1 }} downto {{ 3*file_bitwidth }}));
                addr_count_next   <= addr_count + 1;
                state_next        <= UPLOAD_CHECK;

            when UPLOAD_CHECK =>  
                if (addr_count = ADDR_COUNT_UPLOAD_END+1) then
                    ena_memory    <= '0';
                    en_register   <= '0';
                    state_next    <= WAIT_FOR_OUTPUT;
                else
                    ena_memory    <= '1';
                    en_register   <= '0';
                    state_next    <= UPLOAD_B0;
                end if;

            when WAIT_FOR_OUTPUT =>
                {%- if handshake is true %}
                if nn_done = '1' then
                {%- else %}
                if counter = 30 then
                {%- endif %}
                    addr_count_next   <= ADDR_COUNT_DOWNLOAD_START;
                    state_next        <= WRITE_OUTPUT; 
                else
                    {%- if handshake is false %}
                    counter_next      <= counter + 1;
                    {%- endif %}
                    state_next        <= WAIT_FOR_OUTPUT;
                end if;

            when WRITE_OUTPUT => 
                if (addr_count = ADDR_COUNT_DOWNLOAD_END) then
                    state_next        <= PROCESS_COMPLETED;
                else
                    ena_memory        <= '1';
                    wea_memory        <= '1';
                    dia_memory        <=  std_logic_vector(nn_output(output_count));
                    output_count_next <= output_count+1;
                    addr_count_next   <= addr_count + 1;
                    state_next        <= WRITE_OUTPUT;
                end if;

            when PROCESS_COMPLETED =>
                    ena_memory        <= '0';
                    wea_memory        <= '0';
                    finish            <= '1';

            when others =>
                state_next            <= state;
        end case;
    end process;
process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state           <= START;
                addr_count      <= (others => '0');
                output_count    <= 0;
                {%- if handshake is false %}
                counter         <= 0;
                {%- endif %}
            else
                state           <= state_next;
                addr_count      <= addr_count_next;
                output_count    <= output_count_next;
                {%- if handshake is false %}
                counter         <=counter_next;
                {%- endif %}
            end if;
        end if;
    end process;
end Behavioral;