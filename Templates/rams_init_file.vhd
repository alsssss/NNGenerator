library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity network_weights is
port(
clk     : in std_logic;
addr    : in std_logic_vector({{ addr_size - 1 }} downto 0);
dout    : out signed({{ word_size - 1 }} downto 0)
);
end network_weights;

architecture rtl of network_weights is

    type ram_type is array(0 to {{ end_RAM - 1 }}) of signed({{ word_size - 1 }} downto 0);
    signal RAM : ram_type := (
    {%- for i in range(end_RAM) %}
    {%- set val0 = ram_values[4*i + 0] if (4*i + 0) < ram_values|length else 0 %}
    {%- set val1 = ram_values[4*i + 1] if (4*i + 1) < ram_values|length else 0 %}
    {%- set val2 = ram_values[4*i + 2] if (4*i + 2) < ram_values|length else 0 %}
    {%- set val3 = ram_values[4*i + 3] if (4*i + 3) < ram_values|length else 0 %}
    {{ i }} =>  to_signed({{ val3 }}, {{ file_bitwidth }}) &
           to_signed({{ val2 }}, {{ file_bitwidth }}) &
           to_signed({{ val1 }}, {{ file_bitwidth }}) &
           to_signed({{ val0 }}, {{ file_bitwidth }}){% if not loop.last %},{% endif %}
                
    {%- endfor %}
    );
    attribute rom_style : string;
    attribute rom_style of RAM : signal is "block";

begin
    process(clk)
    begin
        if rising_edge(clk) then
                dout <= RAM(to_integer(unsigned(addr)));
        end if;
    end process;
end rtl;