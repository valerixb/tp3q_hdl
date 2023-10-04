--
-- just a wrapper for the 8 lanes RX_HSSIO for timepix A created by the wizard,
-- so I can drop it onto the block design
--
-- latest rev sept 19 2023
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TPA_RX_channels is
  Port(
    dly_rdy                 : OUT STD_LOGIC;
    rst_seq_done            : OUT STD_LOGIC;
    rst                     :  IN STD_LOGIC;
    clk_160MHz              :  IN STD_LOGIC;
    riu_clk                 :  IN STD_LOGIC;
    pll0_locked             : OUT STD_LOGIC;
    ------------
    N_delay_value           :  IN STD_LOGIC_VECTOR(8 downto 0);
    N_delay_value_readback  : OUT STD_LOGIC_VECTOR(8 downto 0);
    P_delay_value_readback  : OUT STD_LOGIC_VECTOR(8 downto 0);
    delay_load              :  IN STD_LOGIC;
    vtc_enable              :  IN STD_LOGIC;
    ------------
    fifo_rd_clk             :  IN STD_LOGIC;
    fifo0_valid              : OUT STD_LOGIC;
    fifo1_valid              : OUT STD_LOGIC;
    fifo2_valid              : OUT STD_LOGIC;
    fifo3_valid              : OUT STD_LOGIC;
    fifo4_valid              : OUT STD_LOGIC;
    fifo5_valid              : OUT STD_LOGIC;
    fifo6_valid              : OUT STD_LOGIC;
    fifo7_valid              : OUT STD_LOGIC;
    ------------
    riu_rd_data             : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    riu_valid               : OUT STD_LOGIC;
    riu_nibble_sel          :  IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    riu_addr                :  IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    riu_wr_data             :  IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    riu_wr_en               :  IN STD_LOGIC;
    ------------
    TPA0P                   :  IN STD_LOGIC;
    rx_ch0_buf_p            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA0N                   :  IN STD_LOGIC;
    rx_ch0_buf_n            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    ------------
    TPA1P                   :  IN STD_LOGIC;
    rx_ch1_buf_p            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA1N                   :  IN STD_LOGIC;
    rx_ch1_buf_n            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    ------------
    TPA2P                   :  IN STD_LOGIC;
    rx_ch2_buf_p            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA2N                   :  IN STD_LOGIC;
    rx_ch2_buf_n            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    ------------
    TPA3P                   :  IN STD_LOGIC;
    rx_ch3_buf_p            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA3N                   :  IN STD_LOGIC;
    rx_ch3_buf_n            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    ------------
    TPA4P                   :  IN STD_LOGIC;
    rx_ch4_buf_p            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA4N                   :  IN STD_LOGIC;
    rx_ch4_buf_n            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    ------------
    TPA5P                   :  IN STD_LOGIC;
    rx_ch5_buf_p            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA5N                   :  IN STD_LOGIC;
    rx_ch5_buf_n            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    ------------
    TPA6P                   :  IN STD_LOGIC;
    rx_ch6_buf_p            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA6N                   :  IN STD_LOGIC;
    rx_ch6_buf_n            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    ------------
    TPA7P                   :  IN STD_LOGIC;
    rx_ch7_buf_p            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA7N                   :  IN STD_LOGIC;
    rx_ch7_buf_n            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
end TPA_RX_channels;

architecture Behavioral of TPA_RX_channels is

COMPONENT TPA_HSSIO_RX
  PORT (
    rx_cntvaluein_26 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_cntvalueout_26 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_ce_26 : IN STD_LOGIC;
    rx_inc_26 : IN STD_LOGIC;
    rx_load_26 : IN STD_LOGIC;
    rx_en_vtc_26 : IN STD_LOGIC;
    rx_cntvaluein_27 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_cntvalueout_27 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_ce_27 : IN STD_LOGIC;
    rx_inc_27 : IN STD_LOGIC;
    rx_load_27 : IN STD_LOGIC;
    rx_en_vtc_27 : IN STD_LOGIC;
    rx_cntvaluein_32 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_cntvalueout_32 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_ce_32 : IN STD_LOGIC;
    rx_inc_32 : IN STD_LOGIC;
    rx_load_32 : IN STD_LOGIC;
    rx_en_vtc_32 : IN STD_LOGIC;
    rx_cntvaluein_33 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_cntvalueout_33 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_ce_33 : IN STD_LOGIC;
    rx_inc_33 : IN STD_LOGIC;
    rx_load_33 : IN STD_LOGIC;
    rx_en_vtc_33 : IN STD_LOGIC;
    rx_cntvaluein_36 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_cntvalueout_36 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_ce_36 : IN STD_LOGIC;
    rx_inc_36 : IN STD_LOGIC;
    rx_load_36 : IN STD_LOGIC;
    rx_en_vtc_36 : IN STD_LOGIC;
    rx_cntvaluein_37 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_cntvalueout_37 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_ce_37 : IN STD_LOGIC;
    rx_inc_37 : IN STD_LOGIC;
    rx_load_37 : IN STD_LOGIC;
    rx_en_vtc_37 : IN STD_LOGIC;
    rx_cntvaluein_39 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_cntvalueout_39 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_ce_39 : IN STD_LOGIC;
    rx_inc_39 : IN STD_LOGIC;
    rx_load_39 : IN STD_LOGIC;
    rx_en_vtc_39 : IN STD_LOGIC;
    rx_cntvaluein_40 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_cntvalueout_40 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_ce_40 : IN STD_LOGIC;
    rx_inc_40 : IN STD_LOGIC;
    rx_load_40 : IN STD_LOGIC;
    rx_en_vtc_40 : IN STD_LOGIC;
    rx_cntvaluein_41 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_cntvalueout_41 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_ce_41 : IN STD_LOGIC;
    rx_inc_41 : IN STD_LOGIC;
    rx_load_41 : IN STD_LOGIC;
    rx_en_vtc_41 : IN STD_LOGIC;
    rx_cntvaluein_42 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_cntvalueout_42 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_ce_42 : IN STD_LOGIC;
    rx_inc_42 : IN STD_LOGIC;
    rx_load_42 : IN STD_LOGIC;
    rx_en_vtc_42 : IN STD_LOGIC;
    rx_cntvaluein_43 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_cntvalueout_43 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_ce_43 : IN STD_LOGIC;
    rx_inc_43 : IN STD_LOGIC;
    rx_load_43 : IN STD_LOGIC;
    rx_en_vtc_43 : IN STD_LOGIC;
    rx_cntvaluein_44 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_cntvalueout_44 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_ce_44 : IN STD_LOGIC;
    rx_inc_44 : IN STD_LOGIC;
    rx_load_44 : IN STD_LOGIC;
    rx_en_vtc_44 : IN STD_LOGIC;
    rx_cntvaluein_45 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_cntvalueout_45 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_ce_45 : IN STD_LOGIC;
    rx_inc_45 : IN STD_LOGIC;
    rx_load_45 : IN STD_LOGIC;
    rx_en_vtc_45 : IN STD_LOGIC;
    rx_cntvaluein_46 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_cntvalueout_46 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_ce_46 : IN STD_LOGIC;
    rx_inc_46 : IN STD_LOGIC;
    rx_load_46 : IN STD_LOGIC;
    rx_en_vtc_46 : IN STD_LOGIC;
    rx_cntvaluein_47 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_cntvalueout_47 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_ce_47 : IN STD_LOGIC;
    rx_inc_47 : IN STD_LOGIC;
    rx_load_47 : IN STD_LOGIC;
    rx_en_vtc_47 : IN STD_LOGIC;
    rx_cntvaluein_48 : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_cntvalueout_48 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_ce_48 : IN STD_LOGIC;
    rx_inc_48 : IN STD_LOGIC;
    rx_load_48 : IN STD_LOGIC;
    rx_en_vtc_48 : IN STD_LOGIC;
    rx_clk : IN STD_LOGIC;
    fifo_rd_clk_26 : IN STD_LOGIC;
    fifo_rd_clk_27 : IN STD_LOGIC;
    fifo_rd_clk_32 : IN STD_LOGIC;
    fifo_rd_clk_33 : IN STD_LOGIC;
    fifo_rd_clk_36 : IN STD_LOGIC;
    fifo_rd_clk_37 : IN STD_LOGIC;
    fifo_rd_clk_39 : IN STD_LOGIC;
    fifo_rd_clk_40 : IN STD_LOGIC;
    fifo_rd_clk_41 : IN STD_LOGIC;
    fifo_rd_clk_42 : IN STD_LOGIC;
    fifo_rd_clk_43 : IN STD_LOGIC;
    fifo_rd_clk_44 : IN STD_LOGIC;
    fifo_rd_clk_45 : IN STD_LOGIC;
    fifo_rd_clk_46 : IN STD_LOGIC;
    fifo_rd_clk_47 : IN STD_LOGIC;
    fifo_rd_clk_48 : IN STD_LOGIC;
    fifo_rd_en_26 : IN STD_LOGIC;
    fifo_rd_en_27 : IN STD_LOGIC;
    fifo_rd_en_32 : IN STD_LOGIC;
    fifo_rd_en_33 : IN STD_LOGIC;
    fifo_rd_en_36 : IN STD_LOGIC;
    fifo_rd_en_37 : IN STD_LOGIC;
    fifo_rd_en_39 : IN STD_LOGIC;
    fifo_rd_en_40 : IN STD_LOGIC;
    fifo_rd_en_41 : IN STD_LOGIC;
    fifo_rd_en_42 : IN STD_LOGIC;
    fifo_rd_en_43 : IN STD_LOGIC;
    fifo_rd_en_44 : IN STD_LOGIC;
    fifo_rd_en_45 : IN STD_LOGIC;
    fifo_rd_en_46 : IN STD_LOGIC;
    fifo_rd_en_47 : IN STD_LOGIC;
    fifo_rd_en_48 : IN STD_LOGIC;
    fifo_empty_26 : OUT STD_LOGIC;
    fifo_empty_27 : OUT STD_LOGIC;
    fifo_empty_32 : OUT STD_LOGIC;
    fifo_empty_33 : OUT STD_LOGIC;
    fifo_empty_36 : OUT STD_LOGIC;
    fifo_empty_37 : OUT STD_LOGIC;
    fifo_empty_39 : OUT STD_LOGIC;
    fifo_empty_40 : OUT STD_LOGIC;
    fifo_empty_41 : OUT STD_LOGIC;
    fifo_empty_42 : OUT STD_LOGIC;
    fifo_empty_43 : OUT STD_LOGIC;
    fifo_empty_44 : OUT STD_LOGIC;
    fifo_empty_45 : OUT STD_LOGIC;
    fifo_empty_46 : OUT STD_LOGIC;
    fifo_empty_47 : OUT STD_LOGIC;
    fifo_empty_48 : OUT STD_LOGIC;
    riu_rd_data_bg2 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    riu_valid_bg2 : OUT STD_LOGIC;
    riu_addr_bg2 : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    riu_nibble_sel_bg2 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    riu_wr_data_bg2 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    riu_wr_en_bg2 : IN STD_LOGIC;
    riu_rd_data_bg3 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    riu_valid_bg3 : OUT STD_LOGIC;
    riu_addr_bg3 : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    riu_nibble_sel_bg3 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    riu_wr_data_bg3 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    riu_wr_en_bg3 : IN STD_LOGIC;
    dly_rdy_bsc4 : OUT STD_LOGIC;
    dly_rdy_bsc5 : OUT STD_LOGIC;
    dly_rdy_bsc6 : OUT STD_LOGIC;
    dly_rdy_bsc7 : OUT STD_LOGIC;
    rst_seq_done : OUT STD_LOGIC;
    shared_pll0_clkoutphy_out : OUT STD_LOGIC;
    pll0_clkout0 : OUT STD_LOGIC;
    rst : IN STD_LOGIC;
    clk : IN STD_LOGIC;
    riu_clk : IN STD_LOGIC;
    pll0_locked : OUT STD_LOGIC;
    TPA0P : IN STD_LOGIC;
    data_to_fabric_TPA0P : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA0N : IN STD_LOGIC;
    data_to_fabric_TPA0N : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA1P : IN STD_LOGIC;
    data_to_fabric_TPA1P : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA1N : IN STD_LOGIC;
    data_to_fabric_TPA1N : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA7P : IN STD_LOGIC;
    data_to_fabric_TPA7P : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA7N : IN STD_LOGIC;
    data_to_fabric_TPA7N : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA6P : IN STD_LOGIC;
    data_to_fabric_TPA6P : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA6N : IN STD_LOGIC;
    data_to_fabric_TPA6N : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA5P : IN STD_LOGIC;
    data_to_fabric_TPA5P : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA5N : IN STD_LOGIC;
    data_to_fabric_TPA5N : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA4P : IN STD_LOGIC;
    data_to_fabric_TPA4P : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA4N : IN STD_LOGIC;
    data_to_fabric_TPA4N : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA3P : IN STD_LOGIC;
    data_to_fabric_TPA3P : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA3N : IN STD_LOGIC;
    data_to_fabric_TPA3N : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA2P : IN STD_LOGIC;
    data_to_fabric_TPA2P : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    TPA2N : IN STD_LOGIC;
    data_to_fabric_TPA2N : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) 
  );
END COMPONENT;

signal fifo_empty_26, fifo_empty_27, fifo_empty_32, fifo_empty_33,
       fifo_empty_36, fifo_empty_37, fifo_empty_39, fifo_empty_40,
       fifo_empty_41, fifo_empty_42, fifo_empty_43, fifo_empty_44,
       fifo_empty_45, fifo_empty_46, fifo_empty_47, fifo_empty_48 : std_logic; 
signal fifo0_valid_buf, fifo1_valid_buf, fifo2_valid_buf, fifo3_valid_buf,
       fifo4_valid_buf, fifo5_valid_buf, fifo6_valid_buf, fifo7_valid_buf : std_logic;
signal dly_rdy_bsc4, dly_rdy_bsc5, dly_rdy_bsc6, dly_rdy_bsc7 : std_logic;
signal data_to_fabric_TPA0P, data_to_fabric_TPA0N,
       data_to_fabric_TPA1P, data_to_fabric_TPA1N,
       data_to_fabric_TPA2P, data_to_fabric_TPA2N,
       data_to_fabric_TPA3P, data_to_fabric_TPA3N,
       data_to_fabric_TPA4P, data_to_fabric_TPA4N,
       data_to_fabric_TPA5P, data_to_fabric_TPA5N,
       data_to_fabric_TPA6P, data_to_fabric_TPA6N,
       data_to_fabric_TPA7P, data_to_fabric_TPA7N : std_logic_vector(7 downto 0);


begin

fifo0_valid <= fifo0_valid_buf;
fifo1_valid <= fifo1_valid_buf;
fifo2_valid <= fifo2_valid_buf;
fifo3_valid <= fifo3_valid_buf;
fifo4_valid <= fifo4_valid_buf;
fifo5_valid <= fifo5_valid_buf;
fifo6_valid <= fifo6_valid_buf;
fifo7_valid <= fifo7_valid_buf;

aggregate_signals: process(riu_clk, rst)
  begin
    if(rising_edge(riu_clk)) then
      if(rst='1') then
        fifo0_valid_buf <= '0';
        fifo1_valid_buf <= '0';
        fifo2_valid_buf <= '0';
        fifo3_valid_buf <= '0';
        fifo4_valid_buf <= '0';
        fifo5_valid_buf <= '0';
        fifo6_valid_buf <= '0';
        fifo7_valid_buf <= '0';
        dly_rdy         <= '0';
      else
        fifo0_valid_buf <= fifo_empty_26 nor fifo_empty_27;
        fifo1_valid_buf <= fifo_empty_32 nor fifo_empty_33;
        fifo2_valid_buf <= fifo_empty_47 nor fifo_empty_48;
        fifo3_valid_buf <= fifo_empty_45 nor fifo_empty_46;
        fifo4_valid_buf <= fifo_empty_43 nor fifo_empty_44;
        fifo5_valid_buf <= fifo_empty_41 nor fifo_empty_42;
        fifo6_valid_buf <= fifo_empty_39 nor fifo_empty_40;
        fifo7_valid_buf <= fifo_empty_36 nor fifo_empty_37;
        ---
        dly_rdy <= dly_rdy_bsc4 and dly_rdy_bsc5 and dly_rdy_bsc6 and dly_rdy_bsc7;
        
        -- fifo valid will have 1 clk cycle latency, so we align data out
        rx_ch0_buf_p <= data_to_fabric_TPA0P;
        rx_ch0_buf_n <= data_to_fabric_TPA0N;
        rx_ch1_buf_p <= data_to_fabric_TPA1P;
        rx_ch1_buf_n <= data_to_fabric_TPA1N;
        rx_ch2_buf_p <= data_to_fabric_TPA2P;
        rx_ch2_buf_n <= data_to_fabric_TPA2N;
        rx_ch3_buf_p <= data_to_fabric_TPA3P;
        rx_ch3_buf_n <= data_to_fabric_TPA3N;
        rx_ch4_buf_p <= data_to_fabric_TPA4P;
        rx_ch4_buf_n <= data_to_fabric_TPA4N;
        rx_ch5_buf_p <= data_to_fabric_TPA5P;
        rx_ch5_buf_n <= data_to_fabric_TPA5N;
        rx_ch6_buf_p <= data_to_fabric_TPA6P;
        rx_ch6_buf_n <= data_to_fabric_TPA6N;
        rx_ch7_buf_p <= data_to_fabric_TPA7P;
        rx_ch7_buf_n <= data_to_fabric_TPA7N;
      end if;
    end if;
  end process aggregate_signals;


TPA_HSSIO_RX_instance : TPA_HSSIO_RX
  PORT MAP (
    --- ch 0 ---
    rx_cntvaluein_26 => "000000000",
    rx_cntvalueout_26 => P_delay_value_readback,
    rx_ce_26 => '0',
    rx_inc_26 => '0',
    rx_load_26 => '0', -- P side has fixed 0 delay
    rx_en_vtc_26 => '0', -- we don't need voltage and temp calib for RX delays of "P" line, as it's always 0
    rx_cntvaluein_27 => N_delay_value,
    rx_cntvalueout_27 => N_delay_value_readback,
    rx_ce_27 => '0',
    rx_inc_27 => '0',
    rx_load_27 => delay_load,
    rx_en_vtc_27 => vtc_enable,
    --- ch 1 ---
    rx_cntvaluein_32 => "000000000",
    rx_cntvalueout_32 => open,
    rx_ce_32 => '0',
    rx_inc_32 => '0',
    rx_load_32 => '0', -- P side has fixed 0 delay
    rx_en_vtc_32 => '0', -- we don't need voltage and temp calib for RX delays of "P" line, as it's always 0
    rx_cntvaluein_33 => N_delay_value,
    rx_cntvalueout_33 => open,
    rx_ce_33 => '0',
    rx_inc_33 => '0',
    rx_load_33 => delay_load,
    rx_en_vtc_33 => vtc_enable,
    --- ch 7 ---
    rx_cntvaluein_36 => "000000000",
    rx_cntvalueout_36 => open,
    rx_ce_36 => '0',
    rx_inc_36 => '0',
    rx_load_36 => '0', -- P side has fixed 0 delay
    rx_en_vtc_36 => '0', -- we don't need voltage and temp calib for RX delays of "P" line, as it's always 0
    rx_cntvaluein_37 => N_delay_value,
    rx_cntvalueout_37 => open,
    rx_ce_37 => '0',
    rx_inc_37 => '0',
    rx_load_37 => delay_load,
    rx_en_vtc_37 => vtc_enable,
    --- ch 6 ---
    rx_cntvaluein_39 => "000000000",
    rx_cntvalueout_39 => open,
    rx_ce_39 => '0',
    rx_inc_39 => '0',
    rx_load_39 => '0', -- P side has fixed 0 delay
    rx_en_vtc_39 => '0', -- we don't need voltage and temp calib for RX delays of "P" line, as it's always 0
    rx_cntvaluein_40 => N_delay_value,
    rx_cntvalueout_40 => open,
    rx_ce_40 => '0',
    rx_inc_40 => '0',
    rx_load_40 => delay_load,
    rx_en_vtc_40 => vtc_enable,
    --- ch 5 ---
    rx_cntvaluein_41 => "000000000",
    rx_cntvalueout_41 => open,
    rx_ce_41 => '0',
    rx_inc_41 => '0',
    rx_load_41 => '0', -- P side has fixed 0 delay
    rx_en_vtc_41 => '0', -- we don't need voltage and temp calib for RX delays of "P" line, as it's always 0
    rx_cntvaluein_42 => N_delay_value,
    rx_cntvalueout_42 => open,
    rx_ce_42 => '0',
    rx_inc_42 => '0',
    rx_load_42 => delay_load,
    rx_en_vtc_42 => vtc_enable,
    --- ch 4 ---
    rx_cntvaluein_43 => "000000000",
    rx_cntvalueout_43 => open,
    rx_ce_43 => '0',
    rx_inc_43 => '0',
    rx_load_43 => '0', -- P side has fixed 0 delay
    rx_en_vtc_43 => '0', -- we don't need voltage and temp calib for RX delays of "P" line, as it's always 0
    rx_cntvaluein_44 => N_delay_value,
    rx_cntvalueout_44 => open,
    rx_ce_44 => '0',
    rx_inc_44 => '0',
    rx_load_44 => delay_load,
    rx_en_vtc_44 => vtc_enable,
    --- ch 3 ---
    rx_cntvaluein_45 => "000000000",
    rx_cntvalueout_45 => open,
    rx_ce_45 => '0',
    rx_inc_45 => '0',
    rx_load_45 => '0', -- P side has fixed 0 delay
    rx_en_vtc_45 => '0', -- we don't need voltage and temp calib for RX delays of "P" line, as it's always 0
    rx_cntvaluein_46 => N_delay_value,
    rx_cntvalueout_46 => open,
    rx_ce_46 => '0',
    rx_inc_46 => '0',
    rx_load_46 => delay_load,
    rx_en_vtc_46 => vtc_enable,
    --- ch 2 ---
    rx_cntvaluein_47 => "000000000",
    rx_cntvalueout_47 => open,
    rx_ce_47 => '0',
    rx_inc_47 => '0',
    rx_load_47 => '0', -- P side has fixed 0 delay
    rx_en_vtc_47 => '0', -- we don't need voltage and temp calib for RX delays of "P" line, as it's always 0
    rx_cntvaluein_48 => N_delay_value,
    rx_cntvalueout_48 => open,
    rx_ce_48 => '0',
    rx_inc_48 => '0',
    rx_load_48 => delay_load,
    rx_en_vtc_48 => vtc_enable,
    ---
    rx_clk => clk_160MHz,
    fifo_rd_clk_26 => fifo_rd_clk,
    fifo_rd_clk_27 => fifo_rd_clk,
    fifo_rd_clk_32 => fifo_rd_clk,
    fifo_rd_clk_33 => fifo_rd_clk,
    fifo_rd_clk_36 => fifo_rd_clk,
    fifo_rd_clk_37 => fifo_rd_clk,
    fifo_rd_clk_39 => fifo_rd_clk,
    fifo_rd_clk_40 => fifo_rd_clk,
    fifo_rd_clk_41 => fifo_rd_clk,
    fifo_rd_clk_42 => fifo_rd_clk,
    fifo_rd_clk_43 => fifo_rd_clk,
    fifo_rd_clk_44 => fifo_rd_clk,
    fifo_rd_clk_45 => fifo_rd_clk,
    fifo_rd_clk_46 => fifo_rd_clk,
    fifo_rd_clk_47 => fifo_rd_clk,
    fifo_rd_clk_48 => fifo_rd_clk,
    fifo_rd_en_26 => fifo0_valid_buf,
    fifo_rd_en_27 => fifo0_valid_buf,
    fifo_rd_en_32 => fifo1_valid_buf,
    fifo_rd_en_33 => fifo1_valid_buf,
    fifo_rd_en_36 => fifo7_valid_buf,
    fifo_rd_en_37 => fifo7_valid_buf,
    fifo_rd_en_39 => fifo6_valid_buf,
    fifo_rd_en_40 => fifo6_valid_buf,
    fifo_rd_en_41 => fifo5_valid_buf,
    fifo_rd_en_42 => fifo5_valid_buf,
    fifo_rd_en_43 => fifo4_valid_buf,
    fifo_rd_en_44 => fifo4_valid_buf,
    fifo_rd_en_45 => fifo3_valid_buf,
    fifo_rd_en_46 => fifo3_valid_buf,
    fifo_rd_en_47 => fifo2_valid_buf,
    fifo_rd_en_48 => fifo2_valid_buf,
    fifo_empty_26 => fifo_empty_26,
    fifo_empty_27 => fifo_empty_27,
    fifo_empty_32 => fifo_empty_32,
    fifo_empty_33 => fifo_empty_33,
    fifo_empty_36 => fifo_empty_36,
    fifo_empty_37 => fifo_empty_37,
    fifo_empty_39 => fifo_empty_39,
    fifo_empty_40 => fifo_empty_40,
    fifo_empty_41 => fifo_empty_41,
    fifo_empty_42 => fifo_empty_42,
    fifo_empty_43 => fifo_empty_43,
    fifo_empty_44 => fifo_empty_44,
    fifo_empty_45 => fifo_empty_45,
    fifo_empty_46 => fifo_empty_46,
    fifo_empty_47 => fifo_empty_47,
    fifo_empty_48 => fifo_empty_48,
    --- RIU for bytegropup 2 ---
    riu_rd_data_bg2 => riu_rd_data,
    riu_valid_bg2 => riu_valid,
    riu_addr_bg2 => riu_addr,
    riu_nibble_sel_bg2 => riu_nibble_sel,
    riu_wr_data_bg2 => riu_wr_data,
    riu_wr_en_bg2 => riu_wr_en,
    --- RIU for bytegropup 3 (unused) ---
    riu_rd_data_bg3 => open,
    riu_valid_bg3 => open,
    riu_addr_bg3 => "000000",
    riu_nibble_sel_bg3 => "01",
    riu_wr_data_bg3 => "0000000000000000",
    riu_wr_en_bg3 => '0',
    ---
    dly_rdy_bsc4 => dly_rdy_bsc4,
    dly_rdy_bsc5 => dly_rdy_bsc5,
    dly_rdy_bsc6 => dly_rdy_bsc6,
    dly_rdy_bsc7 => dly_rdy_bsc7,
    ---
    rst_seq_done => rst_seq_done,
    shared_pll0_clkoutphy_out => open,
    pll0_clkout0 => open,
    rst => rst,
    clk => clk_160MHz,
    riu_clk => riu_clk,
    pll0_locked => pll0_locked,
    ---
    TPA0P => TPA0P,
    data_to_fabric_TPA0P => data_to_fabric_TPA0P,
    TPA0N => TPA0N,
    data_to_fabric_TPA0N => data_to_fabric_TPA0N,
    TPA1P => TPA1P,
    data_to_fabric_TPA1P => data_to_fabric_TPA1P,
    TPA1N => TPA1N,
    data_to_fabric_TPA1N => data_to_fabric_TPA1N,
    TPA7P => TPA7P,
    data_to_fabric_TPA7P => data_to_fabric_TPA7P,
    TPA7N => TPA7N,
    data_to_fabric_TPA7N => data_to_fabric_TPA7N,
    TPA6P => TPA6P,
    data_to_fabric_TPA6P => data_to_fabric_TPA6P,
    TPA6N => TPA6N,
    data_to_fabric_TPA6N => data_to_fabric_TPA6N,
    TPA5P => TPA5P,
    data_to_fabric_TPA5P => data_to_fabric_TPA5P,
    TPA5N => TPA5N,
    data_to_fabric_TPA5N => data_to_fabric_TPA5N,
    TPA4P => TPA4P,
    data_to_fabric_TPA4P => data_to_fabric_TPA4P,
    TPA4N => TPA4N,
    data_to_fabric_TPA4N => data_to_fabric_TPA4N,
    TPA3P => TPA3P,
    data_to_fabric_TPA3P => data_to_fabric_TPA3P,
    TPA3N => TPA3N,
    data_to_fabric_TPA3N => data_to_fabric_TPA3N,
    TPA2P => TPA2P,
    data_to_fabric_TPA2P => data_to_fabric_TPA2P,
    TPA2N => TPA2N,
    data_to_fabric_TPA2N => data_to_fabric_TPA2N
  );


end Behavioral;
