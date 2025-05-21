library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.ALL;
use work.type_def.ALL;

entity {{ name }} is
    generic (
        data_width : integer := {{ data_width }};
        bitwidth   : integer := {{ bitwidth }};
        num_inputs : integer := {{ num_inputs }}
    );
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        inputs: in  std_logic_vector(data_width-1 downto 0);
        output: out std_logic
    );
end entity {{ name }};

architecture Behavioral of {{ name }} is

    type matrix_type is array (0 to {{ num_stages }}, 0 to num_inputs-1) of signed(bitwidth-1 downto 0);
    signal stages: matrix_type;
    signal sum   : signed(bitwidth-1 downto 0);

begin

    process (clk, rst)
    begin
        if rst = '1' then
            sum <= (others => '0');
            output <= '0';
        elsif rising_edge(clk) then
            -- Load initial values
            {% for line in weight_loading %}
            {{ line }}
            {% endfor %}

            -- Perform addition
            {% for line in reduction_addition %}
            {{ line }}
            {% endfor %}

            -- Activation function
            {{ activation_logic }}
        end if;
    end process;

end Behavioral;
