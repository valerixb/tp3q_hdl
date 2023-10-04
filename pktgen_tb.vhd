----------------------------------------------------------------------------------
-- testbench for UDP packet generator v1.0
-- 
-- latest rev by valerix, jan 16 2023
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pktgen_tb is
--  Port ( );
end pktgen_tb;

architecture Behavioral of pktgen_tb is

  COMPONENT udppktgen_v1_0
    GENERIC (
      C_M00_AXIS_TDATA_WIDTH : INTEGER;
      C_M00_AXIS_START_COUNT : INTEGER
    );
    PORT (
      txstrobe : IN STD_LOGIC;
      m00_axis_aclk : IN STD_LOGIC;
      m00_axis_aresetn : IN STD_LOGIC;
      m00_axis_tvalid : OUT STD_LOGIC;
      m00_axis_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      m00_axis_tstrb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      m00_axis_tlast : OUT STD_LOGIC;
      m00_axis_tready : IN STD_LOGIC
    );
  END COMPONENT udppktgen_v1_0;

  signal    txstrobe : STD_LOGIC;
  signal    m00_axis_aclk : STD_LOGIC;
  signal    m00_axis_aresetn : STD_LOGIC;
  signal    m00_axis_tvalid : STD_LOGIC;
  signal    m00_axis_tdata : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal    m00_axis_tstrb : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal    m00_axis_tlast : STD_LOGIC;
  signal    m00_axis_tready : STD_LOGIC;

  constant clock_period: time := 6 ns;
  signal stop_the_clock: boolean;

begin

dut : udppktgen_v1_0
    GENERIC MAP (
      C_M00_AXIS_TDATA_WIDTH => 64,
      C_M00_AXIS_START_COUNT => 32
    )
    PORT MAP (
      txstrobe => txstrobe,
      m00_axis_aclk => m00_axis_aclk,
      m00_axis_aresetn => m00_axis_aresetn,
      m00_axis_tvalid => m00_axis_tvalid,
      m00_axis_tdata => m00_axis_tdata,
      m00_axis_tstrb => m00_axis_tstrb,
      m00_axis_tlast => m00_axis_tlast,
      m00_axis_tready => m00_axis_tready
    );

  stimulus: process
  begin

    m00_axis_aresetn <= '0';
    txstrobe <= '0';
    m00_axis_tready <= '1';
    wait for clock_period*10;
    m00_axis_aresetn <= '1';
    wait for clock_period*10;

    -- change states on falling edge of clock, to be ready for next rising edge
    -- not necessary because I start the clock LOW
    --wait for clock_period/2;
    
    -- Put test bench stimuli code here

    -- allow the state machine to give the initial delay
    m00_axis_tready <= '0';
    wait for clock_period*50;
    -- trigger
    txstrobe <= '1';
    wait for clock_period*2;
    --wait for clock_period;
    --m00_axis_tready <= '0';
    wait for clock_period;
    m00_axis_tready <= '1';
    wait for clock_period;
    txstrobe <= '0';


    -- wait a bit, then give a second trigger
    wait for clock_period*50;
    -- trigger
    txstrobe <= '1';
    wait for clock_period*2;
    txstrobe <= '0';

    -- now wait for the SM to send out the packet
    wait for clock_period*50;
    
    stop_the_clock <= true;
    wait;
  end process;

  clocking: process
  begin
    while not stop_the_clock loop
      m00_axis_aclk <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;

end Behavioral;

