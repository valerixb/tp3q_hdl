--
-- just a wrapper for the TX_HSSIO_test_intf created by the wizard,
-- so I can drop it onto the block design
--
-- latest rev sept 20 2023
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

entity HSSIO_TX is
  PORT (
    rst_seq_done : OUT STD_LOGIC;
    pll0_clkout0_80MHz : OUT STD_LOGIC;
    -- pll0_clkout1_80MHz_RIU : OUT STD_LOGIC;
    rst : IN STD_LOGIC;
    clk_160MHz : IN STD_LOGIC;
    riu_clk : IN STD_LOGIC;
    pll0_locked : OUT STD_LOGIC;
    tx_ch_p : OUT STD_LOGIC;
    data_from_fabric_tx_ch : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    tx_ch_n : OUT STD_LOGIC 
  );
end HSSIO_TX;

architecture Behavioral of HSSIO_TX is

COMPONENT TX_HSSIO_test_intf
  PORT (
    vtc_rdy_bsc7 : OUT STD_LOGIC;
    en_vtc_bsc7 : IN STD_LOGIC;
    dly_rdy_bsc7 : OUT STD_LOGIC;
    rst_seq_done : OUT STD_LOGIC;
    shared_pll0_clkoutphy_out : OUT STD_LOGIC;
    pll0_clkout0 : OUT STD_LOGIC;
    rst : IN STD_LOGIC;
    clk : IN STD_LOGIC;
    riu_clk : IN STD_LOGIC;
    pll0_locked : OUT STD_LOGIC;
    test_tx_ch_p : OUT STD_LOGIC;
    data_from_fabric_test_tx_ch_p : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    test_tx_ch_n : OUT STD_LOGIC 
  );
END COMPONENT;

begin

HSSIO_TX_instance : TX_HSSIO_test_intf
  PORT MAP (
    vtc_rdy_bsc7 => open,  -- not used in TX
    en_vtc_bsc7 => '0',  -- we don't need voltage and temperature calibration for TX (no delays used)
    dly_rdy_bsc7 => open,  -- not used in TX
    rst_seq_done => rst_seq_done,
    shared_pll0_clkoutphy_out => open,
    pll0_clkout0 => pll0_clkout0_80MHz,
    --pll0_clkout1 => pll0_clkout1_80MHz_RIU,
    rst => rst,
    clk => clk_160MHz,
    riu_clk => riu_clk,
    pll0_locked => pll0_locked,
    test_tx_ch_p => tx_ch_p,
    data_from_fabric_test_tx_ch_p => data_from_fabric_tx_ch,
    test_tx_ch_n => tx_ch_n
  );


end Behavioral;
