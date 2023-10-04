--
-- just a wrapper for the RX_HSSIO_test_intf created by the wizard,
-- so I can drop it onto the block design
--
-- latest rev may 22 2023
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

entity HSSIO_RX is
  Port(
    dly_rdy                 : OUT STD_LOGIC;
    rst_seq_done            : OUT STD_LOGIC;
    rst                     :  IN STD_LOGIC;
    clk_160MHz              :  IN STD_LOGIC;
    riu_clk                 :  IN STD_LOGIC;
    pll0_locked             : OUT STD_LOGIC;
    inferred_bitslice_port  :  IN STD_LOGIC;
    ------------
    N_delay_value           :  IN STD_LOGIC_VECTOR(8 downto 0);
    N_delay_value_readback  : OUT STD_LOGIC_VECTOR(8 downto 0);
    P_delay_value_readback  : OUT STD_LOGIC_VECTOR(8 downto 0);
    delay_load              :  IN STD_LOGIC;
    vtc_enable              :  IN STD_LOGIC;
    ------------
    fifo_rd_clk             :  IN STD_LOGIC;
    fifo_valid              : OUT STD_LOGIC;
    ------------
    riu_rd_data             : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    riu_valid               : OUT STD_LOGIC;
    riu_nibble_sel          :  IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    riu_addr                :  IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    riu_wr_data             :  IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    riu_wr_en               :  IN STD_LOGIC;
    ------------
    rx_ch1_p                :  IN STD_LOGIC;
    rx_ch1_buf_p            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rx_ch1_n                :  IN STD_LOGIC;
    rx_ch1_buf_n            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) 
  );
end HSSIO_RX;

architecture Behavioral of HSSIO_RX is

COMPONENT RX_HSSIO_test_intf
  PORT (
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
    fifo_rd_clk_47 : IN STD_LOGIC;
    fifo_rd_clk_48 : IN STD_LOGIC;
    fifo_rd_en_47 : IN STD_LOGIC;
    fifo_rd_en_48 : IN STD_LOGIC;
    fifo_empty_47 : OUT STD_LOGIC;
    fifo_empty_48 : OUT STD_LOGIC;
    riu_rd_data_bg3 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    riu_valid_bg3 : OUT STD_LOGIC;
    riu_addr_bg3 : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    riu_nibble_sel_bg3 : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    riu_wr_data_bg3 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    riu_wr_en_bg3 : IN STD_LOGIC;
    dly_rdy_bsc7 : OUT STD_LOGIC;
    rst_seq_done : OUT STD_LOGIC;
    shared_pll0_clkoutphy_out : OUT STD_LOGIC;
    pll0_clkout0 : OUT STD_LOGIC;
    rst : IN STD_LOGIC;
    clk : IN STD_LOGIC;
    riu_clk : IN STD_LOGIC;
    pll0_locked : OUT STD_LOGIC;
    bg3_pin6_nc : IN STD_LOGIC;
    rx_ch1_p : IN STD_LOGIC;
    data_to_fabric_rx_ch1_p : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rx_ch1_n : IN STD_LOGIC;
    data_to_fabric_rx_ch1_n : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) 
  );
END COMPONENT;

signal fifo_empty_47, fifo_empty_48, fifo_valid_buf : std_logic;
signal data_to_fabric_rx_ch1_p, data_to_fabric_rx_ch1_n : STD_LOGIC_VECTOR(7 DOWNTO 0);

begin

fifo_valid <= fifo_valid_buf;

aggregate_fifo_empty: process(riu_clk, rst)
  begin
    if(rising_edge(riu_clk)) then
      if(rst='1') then
        fifo_valid_buf <= '0';
      else
        fifo_valid_buf <= fifo_empty_47 nor fifo_empty_48;
        -- fifo valid will have 1 clk cycle latency, so we align data out
        rx_ch1_buf_p <= data_to_fabric_rx_ch1_p;
        rx_ch1_buf_n <= data_to_fabric_rx_ch1_n;
      end if;
    end if;
  end process aggregate_fifo_empty;


HSSIO_RX_instance : RX_HSSIO_test_intf
  PORT MAP (
    rx_cntvaluein_47          => "000000000",
    rx_cntvalueout_47         => P_delay_value_readback,
    rx_ce_47                  => '0',
    rx_inc_47                 => '0',
    rx_load_47                => '0', -- P side has fixed 0 delay
    rx_en_vtc_47              => '0', -- we don't need voltage and temp calib for RX delays of "P" line, as it's always 0
    rx_cntvaluein_48          => N_delay_value,
    rx_cntvalueout_48         => N_delay_value_readback,
    rx_ce_48                  => '0',
    rx_inc_48                 => '0',
    rx_load_48                => delay_load,
    --rx_en_vtc_48              => '1', -- we need voltage and temp calib for RX delays of "N" line
    -- voltage and temp calib enabled at startup, but must be put to 0 when loading new delays
    rx_en_vtc_48              => vtc_enable, 
    rx_clk                    => clk_160MHz,
    -------------
    fifo_rd_clk_47            => fifo_rd_clk,
    fifo_rd_clk_48            => fifo_rd_clk,
    fifo_rd_en_47             => fifo_valid_buf,
    fifo_rd_en_48             => fifo_valid_buf,
    fifo_empty_47             => fifo_empty_47,
    fifo_empty_48             => fifo_empty_48,
    -------------
    riu_rd_data_bg3           => riu_rd_data,
    riu_valid_bg3             => riu_valid,
    riu_addr_bg3              => riu_addr,
    --riu_nibble_sel_bg3        => "10",
    riu_nibble_sel_bg3        => riu_nibble_sel,
    riu_wr_data_bg3           => riu_wr_data,
    riu_wr_en_bg3             => riu_wr_en,
    -------------
    dly_rdy_bsc7              => dly_rdy,
    rst_seq_done              => rst_seq_done,
    shared_pll0_clkoutphy_out => open,
    pll0_clkout0              => open,
    rst                       => rst,
    clk                       => clk_160MHz,
    riu_clk                   => riu_clk,
    -------------
    pll0_locked               => pll0_locked,
    bg3_pin6_nc               => inferred_bitslice_port,  -- see PG188 page 9
    rx_ch1_p                  => rx_ch1_p,
    data_to_fabric_rx_ch1_p   => data_to_fabric_rx_ch1_p,
    rx_ch1_n                  => rx_ch1_n,
    data_to_fabric_rx_ch1_n   => data_to_fabric_rx_ch1_n
  );

end Behavioral;
