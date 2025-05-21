library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.config.all;

entity process_controller is
   generic(
         MEMORY_ADDR_SIZE: INTEGER :=16
   );
   Port (clk: in std_logic;
         rst: in std_logic;
         start_db:in std_logic;
         doa_memory: in std_logic_vector (31 downto 0 );
         nn_output: in output (0 TO data_widths(2)-1);
			nn_done: in std_logic;
         en_register: out std_logic;
         data_in_register: out unsigned (7 downto 0);
         ena_memory: out std_logic;
         wea_memory: out std_logic;
         dia_memory: out std_logic_vector (31 downto 0);
         mem_addr: out std_logic_vector (15 downto 0);
         finish: out std_logic
         );
end process_controller;

architecture Behavioral of process_controller is
    constant ADDR_COUNT_SIZE           : integer                                := MEMORY_ADDR_SIZE; -- The size of the memory address counter
    constant ADDR_COUNT_MIN            : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned(0, ADDR_COUNT_SIZE); -- Initial address of the memory
    constant ADDR_COUNT_UPLOAD_START   : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned(0, ADDR_COUNT_SIZE); -- First pixel address of the memory for the download image
    constant ADDR_COUNT_UPLOAD_END     : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned(15, ADDR_COUNT_SIZE); -- Last pixel address of the memory for the download image
    constant ADDR_COUNT_DOWNLOAD_START : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned(25344, ADDR_COUNT_SIZE); -- First pixel address of the memory for the upload image
    constant ADDR_COUNT_DOWNLOAD_END   : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned(25354, ADDR_COUNT_SIZE); -- Last pixel address of the memory for the upload image
    constant ADDR_COUNT_MAX            : unsigned(ADDR_COUNT_SIZE - 1 downto 0) := to_unsigned(65535, ADDR_COUNT_SIZE); -- Final address of the memory

    type state_type is (START, UPLOAD_B0, UPLOAD_B1, UPLOAD_B2, UPLOAD_B3, UPLOAD_WAIT, UPLOAD_CHECK, WAIT_FOR_OUTPUT, WRITE_OUTPUT, PROCESS_COMPLETED);
    signal state, state_next : state_type;

    --signal data_buffer, data_buffer_next : constIntArray (data_widths(2)-1 downto 0);
    signal addr_count, addr_count_next : unsigned(15 downto 0);
    signal counter,counter_next: integer range 0 to 30 ;
    signal output_count, output_count_next: integer range 0 to 9:=0;
    
    
 

begin
    mem_addr    <= std_logic_vector(addr_count);
    

    process(state, addr_count,doa_memory,start_db,counter,output_count)
    begin
        
        state_next         <= state;
        addr_count_next    <= addr_count;
        ena_memory         <= '0';
        wea_memory         <= '0';
        finish             <= '0';
        counter_next       <=  0;
        data_in_register   <= (others=>'0');
        output_count_next  <= 0;
        dia_memory         <= (others =>'0');
        en_register        <= '0';

        case state is
            when START =>
                --data_buffer_next <= (others => '0');
                if start_db  = '1' then
                addr_count_next  <= ADDR_COUNT_MIN;
                state_next       <= UPLOAD_WAIT;
                else 
                state_next <= START;
                end if;
           when UPLOAD_WAIT =>
                ena_memory <= '1';
                --en_register <= '1';
                
                state_next <= UPLOAD_B0;
           when UPLOAD_B0 =>
                 ena_memory          <= '1';
                 en_register         <= '1';
                data_in_register     <= unsigned(doa_memory (7 downto 0));
                state_next           <= UPLOAD_B1;
           when UPLOAD_B1 =>
                 ena_memory          <= '1';
                 en_register         <= '1';
                data_in_register     <= unsigned(doa_memory (15 downto 8));
                state_next           <= UPLOAD_B2;
           when UPLOAD_B2 =>
                 ena_memory          <= '1';
                 en_register         <= '1';
                 data_in_register     <= unsigned(doa_memory (23 downto 16));
                 state_next           <= UPLOAD_B3;
           when UPLOAD_B3 =>
                 ena_memory          <= '1';
                 en_register         <= '1';
                 data_in_register     <= unsigned(doa_memory (31 downto 24));
                 addr_count_next <= addr_count + 1;
                 state_next           <= UPLOAD_CHECK;
             when UPLOAD_CHECK =>  
                 if (addr_count = ADDR_COUNT_UPLOAD_END+1) then
                    ena_memory <= '0';
                    en_register <= '0';
                    state_next <= WAIT_FOR_OUTPUT;
                else
                    ena_memory      <= '1';
                    en_register     <= '0';
                    
                    state_next      <= UPLOAD_B0;
                end if;
            when WAIT_FOR_OUTPUT =>
                if counter = 30 then
                    addr_count_next <= ADDR_COUNT_DOWNLOAD_START;
                    state_next <= WRITE_OUTPUT; -- Go to WRITE_OUTPUT after 30 clock cycles
                else
                    counter_next <= counter + 1;
                    state_next <= WAIT_FOR_OUTPUT;
                end if;
            when WRITE_OUTPUT => 
                if (addr_count = ADDR_COUNT_DOWNLOAD_END) then
                    state_next <= PROCESS_COMPLETED;
                else
                    ena_memory          <= '1';
                    wea_memory          <= '1';
                    dia_memory          <=  std_logic_vector(nn_output (output_count));
                    output_count_next <= output_count+1;
                    addr_count_next <= addr_count + 1;
                    state_next      <= WRITE_OUTPUT;
                end if;
           when PROCESS_COMPLETED =>
                    ena_memory          <= '0';
                    wea_memory          <= '0';
                    finish              <= '1';
            when others =>
                state_next <= state;
        end case;
    end process;
process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state       <= START;
                addr_count  <= (others => '0');
                output_count <= 0;
                counter <= 0;
            else
                state       <= state_next;
                addr_count  <= addr_count_next;
                output_count<= output_count_next;
                counter     <=counter_next;
            end if;
        end if;
    end process;
end Behavioral;