#
# constraint file for timepix streaming project
#
# latest rev: nov 22 2023
#


## enable SFP tx by forcing 1 from design
set_property PACKAGE_PIN A12 [get_ports {sfp_tx_en[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sfp_tx_en[0]}]

#sfp0
#set_property LOC GTHE4_CHANNEL_X1Y12 [get_cells {xxv_subsys_i/xxv_ethernet_0/inst/i_xxv_subsys_xxv_ethernet_0_0_gt/inst/gen_gtwizard_gthe4_top.xxv_subsys_xxv_ethernet_0_0_gt_gtwizard_gthe4_inst/gen_gtwizard_gthe4.gen_channel_container[1].gen_enabled_channel.gthe4_channel_wrapper_inst/channel_inst/gthe4_channel_gen.gen_gthe4_channel_inst[0].GTHE4_CHANNEL_PRIM_INST}]
set_property PACKAGE_PIN D2 [get_ports {gt_serial_grx_p[0]}]
set_property PACKAGE_PIN E4 [get_ports {gt_serial_gtx_p[0]}]

#USER_MGT_SI570_CLOCK2_C_P
set_property PACKAGE_PIN C8 [get_ports gt_refclk_p]
# GT refclk frequency is already declared inside the xxv IP (10/25G ethernet)
#create_clock -period 6.400 -name gt_ref_clk [get_ports gt_refclk_p]


# begin constraints taken from CSO example ------------------------------------------------------
# remarks by valerix, not xilinx, so they might be wrong

# looks like general false path to clock domain crossing flip-flops; I comment them out; they should be automatic
#set_false_path -to [get_cells -hierarchical -filter {NAME =~ */i_*_axi_if_top/*/i_*_syncer/*meta_reg*}]
#set_false_path -to [get_cells -hierarchical -filter {NAME =~ */i_*_SYNC*/*stretch_reg*}]

# set max delay of 1 clock tick at 156.25 MHz = 6.4 ns between data clocked with 10Geth TX and RX recovered clock,
# to avoid misalignment between TX and RX bits; I comment it out for now: TX and RX are independent and I'l actually not use
# (much of) the RX channel
#set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] 6.400
#set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] 6.400

# set max delay of 1 clock tick of respective clocks (156.25 MHz = 6.4 ns ; 125 MHz = 8 ns) between data clocked with xxv TX/RX clkc and PL 125 MHz clock
# CSO example uses 100 MHz, 125 MHz and 300 MHz for PL; I use 150 MHz and 300 MHz
# I try to comment these out for now
#set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks clk_pl_0] 6.400
#set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks clk_pl_0] 6.400
#set_max_delay -datapath_only -from [get_clocks clk_pl_0] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] 8.000
#set_max_delay -datapath_only -from [get_clocks clk_pl_0] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] 8.000

# set max delay of 1 clock tick of respective clocks (100 MHz = 10 ns ; 125 MHz = 8 ns) between data clocked with PL 125 and 100 MHz clocks
# CSO example uses 100 MHz, 125 MHz and 300 MHz for PL; I use 150 MHz and 300 MHz
# I try to comment these out for now
#set_max_delay -datapath_only -from [get_clocks clk_pl_0] -to [get_clocks clk_pl_1] 8.000
#set_max_delay -datapath_only -from [get_clocks clk_pl_1] -to [get_clocks clk_pl_0] 10.000

# set max delay of 1 clock tick of respective clocks (156.25 MHz = 6.4 ns ; 100 MHz = 10 ns) between data clocked with xxv TX/RX clkc and PL 100 MHz clock
# CSO example uses 100 MHz, 125 MHz and 300 MHz for PL; I use 150 MHz and 300 MHz
# I try to comment these out for now
#set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks clk_pl_1] 6.400
#set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks clk_pl_1] 6.400
#set_max_delay -datapath_only -from [get_clocks clk_pl_1] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] 10.000
#set_max_delay -datapath_only -from [get_clocks clk_pl_1] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] 10.000

# this is some constraint for the 300 MHz clock, but I don't understand it: -from and -to ends are the same;
# maybe they wanted to put it between the MMCM input and output, not between the output ant itself.
# Anyway, I comment it out.
#set_max_delay -from [get_clocks -of_objects [get_pins xxv_subsys_i/clk_wiz_0/inst/mmcme4_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins xxv_subsys_i/clk_wiz_0/inst/mmcme4_adv_inst/CLKOUT0]] 3.300

# end constraints taken from CSO example --------------------------------------------------------


# async clock groups

# 150 MHz to xxv TX/RX clocks
set_clock_groups -name clk_async0 -asynchronous -group [get_clocks -of_objects [get_nets project_1_i/PSsubsys/clk_wiz_0/clk_out1]] -group [get_clocks -include_generated_clocks -of_objects [get_nets project_1_i/HW10GEth/xxv_ethernet_0/tx_clk_out_0]]
set_clock_groups -name clk_async1 -asynchronous -group [get_clocks -of_objects [get_nets project_1_i/PSsubsys/clk_wiz_0/clk_out1]] -group [get_clocks -include_generated_clocks -of_objects [get_nets project_1_i/HW10GEth/xxv_ethernet_0/rx_clk_out_0]]

# 300 MHz to xxv TX/RX clocks
set_clock_groups -name clk_async2 -asynchronous -group [get_clocks -of_objects [get_nets project_1_i/PSsubsys/clk_wiz_0/clk_out2]] -group [get_clocks -include_generated_clocks -of_objects [get_nets project_1_i/HW10GEth/xxv_ethernet_0/tx_clk_out_0]]
set_clock_groups -name clk_async3 -asynchronous -group [get_clocks -of_objects [get_nets project_1_i/PSsubsys/clk_wiz_0/clk_out2]] -group [get_clocks -include_generated_clocks -of_objects [get_nets project_1_i/HW10GEth/xxv_ethernet_0/rx_clk_out_0]]

# it should not be necessary to put an async clause to 100MHz ZUPS PL clock0, because it's used only as MMCM input.


# HSSIO clocking from fabric
#set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets project_1_i/txclk1]
#set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets {project_1_i/ext_clk_mngr/txclk_bufg/U0/BUFG_O[0]}]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets {project_1_i/ext_clk_mngr/div_by_2/U0/BUFGCE_O[0]}]

#set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets project_1_i/rxclk]
#set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets {project_1_i/ext_clk_mngr/rxclk_bufg/U0/BUFG_O[0]}]
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets {project_1_i/ext_clk_mngr/div_by_2_to160MHz/U0/BUFGCE_O[0]}]

## declare Si570 frequencies; 160 MHz => 6.25 ns
#create_clock -period 6.250 -name RxSi570 -waveform {0.000 3.125} [get_ports FMC_HPC0_CLK0_M2C_P]
#create_clock -period 6.250 -name TxSi570 -waveform {0.000 3.125} [get_ports USER_SI570_P]
# declare Si570 frequencies; 320 MHz => 3.125 ns
create_clock -period 3.125 -name RxSi570 -waveform {0.000 1.563} [get_ports FMC_HPC0_CLK0_M2C_P]
create_clock -period 3.125 -name TxSi570 -waveform {0.000 1.563} [get_ports USER_SI570_P]
#set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks "TxSi570"] -group [get_clocks -include_generated_clocks "RxSi570"]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks RxSi570]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks TxSi570]


# declare RIU clock asynchronous from TX HSSIO PLL0 CLKOUT0: they have the same freq but not the same phase.
#set_clock_groups -name tx_riu -asynchronous -group [get_clocks -of_objects [get_pins {project_1_i/ext_clk_mngr/div_by_2/U0/USE_BUFGCE_DIV2.GEN_BUFGCE_DIV2[0].BUFGCE_DIV2_I/O}]] -group [get_clocks -of_objects [get_pins {project_1_i/diagnostic_HSSIO_TX/HSSIO_TX_0/U0/HSSIO_TX_instance/inst/top_inst/bs_ctrl_top_inst/BITSLICE_CTRL[2].bs_ctrl_inst/RX_DIV4_CLK_Q}]]
#set_clock_groups -name tx_riu -asynchronous -group [get_clocks -of_objects [get_pins {project_1_i/ext_clk_mngr/div_by_2/U0/USE_BUFGCE_DIV2.GEN_BUFGCE_DIV2[0].BUFGCE_DIV2_I/O}]] -group [get_clocks -of_objects [get_pins {project_1_i/diagnostic_HSSIO_TX/HSSIO_TX_0/U0/HSSIO_TX_instance/inst/top_inst/bs_ctrl_top_inst/BITSLICE_CTRL[7].bs_ctrl_inst/RX_DIV4_CLK_Q}]]
set_clock_groups -name tx_riu -asynchronous -group [get_clocks -of_objects [get_pins {project_1_i/ext_clk_mngr/div_by_4/U0/USE_BUFGCE_DIV2.GEN_BUFGCE_DIV2[0].BUFGCE_DIV2_I/O}]] -group [get_clocks -of_objects [get_pins {project_1_i/diagnostic_HSSIO_TX/HSSIO_TX_0/U0/HSSIO_TX_instance/inst/top_inst/bs_ctrl_top_inst/BITSLICE_CTRL[7].bs_ctrl_inst/RX_DIV4_CLK_Q}]]

# specify IO standard for inferred pin slice; no need to drive anything, but the HSSIO wizard needs it
#set_property PULLDOWN true [get_ports inferred_bitslice_port_0]
#set_property IOSTANDARD LVCMOS18 [get_ports inferred_bitslice_port_0]
#set_clock_groups -name rx_riu -asynchronous -group [get_clocks -of_objects [get_pins project_1_i/HSSIO_RX_0/U0/HSSIO_RX_instance/inst/top_inst/clk_rst_top_inst/clk_scheme_inst/GEN_PLL_IN_IP_USP.plle4_adv_pll0_inst/CLKOUT1]] -group [get_clocks RxSi570]


set_property DIFF_TERM_ADV TERM_100 [get_ports {FMC_HPC0_CLK0_M2C_P[0]}]

set_property PULLDOWN true [get_ports {FMC_HPC0_CLK0_M2C_P[0]}]
set_property PULLUP true [get_ports {FMC_HPC0_CLK0_M2C_N[0]}]
#set_property PULLDOWN true [get_ports test_rx_ch1_p]
#set_property PULLUP true [get_ports test_rx_ch1_n]
set_property PULLDOWN true [get_ports TPA0P]
set_property PULLUP true [get_ports TPA0N]
set_property PULLDOWN true [get_ports TPA1P]
set_property PULLUP true [get_ports TPA1N]
set_property PULLDOWN true [get_ports TPA2P]
set_property PULLUP true [get_ports TPA2N]
set_property PULLDOWN true [get_ports TPA3P]
set_property PULLUP true [get_ports TPA3N]
set_property PULLDOWN true [get_ports TPA4P]
set_property PULLUP true [get_ports TPA4N]
set_property PULLDOWN true [get_ports TPA5P]
set_property PULLUP true [get_ports TPA5N]
set_property PULLDOWN true [get_ports TPA6P]
set_property PULLUP true [get_ports TPA6N]
set_property PULLDOWN true [get_ports TPA7P]
set_property PULLUP true [get_ports TPA7N]

set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]
