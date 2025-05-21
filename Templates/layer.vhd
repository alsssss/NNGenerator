library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Layer{{ layer_index }} is
    Port (
        clk : in std_logic;
        inputs : in signed(7 downto 0) array({{ neuron_count - 1 }} downto 0);
        outputs : out signed(7 downto 0) array({{ neuron_count - 1 }} downto 0)
    );
end Layer{{ layer_index }};

architecture Structural of Layer{{ layer_index }} is

-- Declare neuron components
{% for i in range(neuron_count) %}
component Neuron
    Port (
        clk : in std_logic;
        inputs : in signed(7 downto 0) array({{ neuron_count - 1 }} downto 0);
        output : out signed(7 downto 0)
    );
end component;
{% endfor %}

-- Internal signals
signal neuron_outputs : signed(7 downto 0) array({{ neuron_count - 1 }} downto 0);

begin

-- Instantiate neurons
{% for i in range(neuron_count) %}
Neuron{{ i }} : Neuron
    Port Map (
        clk => clk,
        inputs => inputs,
        output => neuron_outputs({{ i }})
    );
{% endfor %}

outputs <= neuron_outputs;

end Structural;