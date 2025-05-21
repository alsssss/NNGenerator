library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.TYPE_DEF.ALL;

entity input_loader is

    port (
        clk         : in std_logic;
        rst         : in std_logic;
        enable      : in std_logic;
        inputs      : in unsigned ({{ t_bitwidth - 1 }} downto 0);  -- t_bitwidth/input_size (1, 8, 16,...) is the number of words passed
        ready       : out std_logic;
        inp_out     : out std_logic_vector ({{ input_width -1 }} downto 0)
    );
end input_loader;

architecture Behavioral of input_loader is
    signal internal_temp : std_logic_vector ({{ input_width-1 }} downto 0) := (others => '0');
    {%- set result = input_width / (t_bitwidth // input_size) %}
    signal count         : natural range 0 to {{ result | int }} := 0;
    signal done          : std_logic := '0';
    signal ready_reg     : std_logic := '0'; 

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
            {%- set bits_per_cycle = t_bitwidth // input_size %}
                count      <= 0;
                ready_reg  <= '0';
                internal_temp <= (others => '0');
            elsif enable = '1' then
                {%- for i in range(bits_per_cycle) %}
                if (internal_temp'high - count * {{ bits_per_cycle }} + {{ i }}) >= 0 then
                    {%- if binarize %}
                    if inputs({{ input_size*i+input_size-1 }} downto {{ input_size*i }}) > to_unsigned({{ THRESHOLD }}, {{input_size}}) then
                        internal_temp( internal_temp'high - count * {{ bits_per_cycle }} + {{ i }}) <= '1';
                    else
                        internal_temp( internal_temp'high - count * {{ bits_per_cycle }} + {{ i }}) <= '0';
                    end if;
                    {%- else %}
                    internal_temp( internal_temp'high - count * {{ bits_per_cycle }} + {{ i }}) <= inputs({{ input_size*i+input_size-1 }}); -- store msb or modify for full data
                    {%- endif %}
                end if;
                {%- endfor %}
                {%- set max_cycles =  input_width  // bits_per_cycle %}
                if count = {{ max_cycles - 1 }} then
                    ready_reg  <= '1';
                    done       <= '1';
                else
                    count <= count + 1;
                end if;
            elsif done = '1' then 
                ready_reg <= '0';
                done      <= '0';
            end if;
        end if;
    end process;

    ready <= ready_reg;
    inp_out <= internal_temp;           

end Behavioral;

