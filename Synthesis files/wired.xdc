set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

set_property PACKAGE_PIN C4 [get_ports serial_tx]
set_property IOSTANDARD LVCMOS33 [get_ports serial_tx]
set_property PACKAGE_PIN D4 [get_ports serial_rx]
set_property IOSTANDARD LVCMOS33 [get_ports serial_rx]
set_property PACKAGE_PIN E3 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]
set_property PACKAGE_PIN M18 [get_ports start]
set_property IOSTANDARD LVCMOS33 [get_ports start]
set_property PACKAGE_PIN P18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]
set_property PACKAGE_PIN H17 [get_ports led]
set_property IOSTANDARD LVCMOS33 [get_ports led]


create_clock -name clk_100mhz -period 10.0 [get_ports clk_100mhz]
