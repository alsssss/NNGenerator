----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.05.2025 14:49:34
-- Design Name: 
-- Module Name: Network_TB - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use work.TYPE_DEF.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Network_TB is
--  Port ( );
end Network_TB;

architecture Behavioral of Network_TB is

component neural_network
    port (
        clk     : in std_logic;
        rst     : in std_logic;
        enable  : in std_logic;
        inputs  : in unsigned(7 downto 0);
        outputs : out output(9 downto 0)
    );
end component;

signal clk_TB : std_logic := '0';
signal rst_TB : std_logic := '0';
signal enable_TB : std_logic := '0';
signal inputs_TB : unsigned(7 downto 0) := (others => '0');
signal outputs_TB : output (9 downto 0) := (others => (others => '0'));
signal weights_signal : stored(0 to 1775);

constant clk_period : time := 50 ns;

begin

UUT: neural_network
PORT map(
    clk => clk_TB,
    rst => rst_TB,
    enable => enable_TB,
    inputs => inputs_TB,
    outputs => outputs_TB
);

clk_process :process
begin
    clk_TB <= '0';
    wait for clk_period/2;
    clk_TB <= '1';
    wait for clk_period/2;
end process;

reset_proc: process
begin
    rst_TB <= '1';
    wait for clk_period;
    rst_TB <= '0';
    wait;
end process;

process
begin
    weights_signal <= weights;
    wait;
end process;

stim_proc: process
begin
    enable_TB <= '0';
    wait for 2*clk_period;

    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(255, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    
        enable_TB <= '1';
        inputs_TB <= to_unsigned(0, 8);
        wait for clk_period;
        enable_TB <= '0';
        wait for clk_period;
    

    wait;
end process;