----------------------------------------------------------------------------------
-- testbench for 48/64 gearbox
--
-- watchdog timeout if timepix stops transmitting 
--
-- latest rev by valerix, oct 26 2023
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tb_48to64_watchdog is
--  Generic ( );
--  Port ( );
end tb_48to64_watchdog;

architecture Behavioral of tb_48to64_watchdog is

component gearbox_48_to_64 is
  generic(
    C_S_AXIS_TUSER_WIDTH  : integer	:= 16
    );
  port(
    clk                  : in std_logic;
    resetn               : in std_logic;
    watchdog_timeout     : in std_logic_vector(31 downto 0);
    --
    in_port_tready_out   : out std_logic;
    in_port_tdata_in     :  in std_logic_vector(47 downto 0);
    in_port_tvalid_in    :  in std_logic;
    --
    out_port_tready_in   :  in std_logic;
    out_port_tdata_out   : out std_logic_vector(63 downto 0);
    out_port_tvalid_out  : out std_logic;
    out_port_tlast_out   : out std_logic;
    out_port_tuser_out   : out std_logic_vector(C_S_AXIS_TUSER_WIDTH-1 downto 0);
    out_port_tkeep_out   : out std_logic_vector(7 downto 0);
    out_port_tstrb_out   : out std_logic_vector(7 downto 0)
	);
end component gearbox_48_to_64;

  constant clock_period: time := 6 ns;
  signal stop_the_clock: boolean;
  
  signal aclk                 : STD_LOGIC;
  signal aresetn              : STD_LOGIC;
  --
  signal in_port_tready_out   : std_logic;
  signal in_port_tdata_in     : std_logic_vector(47 downto 0);
  signal in_port_tvalid_in    : std_logic;
  --
  signal out_port_tready_in   : std_logic;
  signal out_port_tdata_out   : std_logic_vector(63 downto 0);
  signal out_port_tvalid_out  : std_logic;
  signal out_port_tlast_out   : std_logic;
  signal out_port_tuser_out   : std_logic_vector(15 downto 0);
  signal out_port_tkeep_out   : std_logic_vector(7 downto 0);
  signal out_port_tstrb_out   : std_logic_vector(7 downto 0);


begin

  gear48to64 : gearbox_48_to_64
    generic map(
      C_S_AXIS_TUSER_WIDTH  => 16
      )
    port map(
      clk                  => aclk,
      resetn               => aresetn,
      -- 160000 clock ticks at 160 MHz - 1ms
      -- use only 10 cycles as timeout for simulation
      watchdog_timeout     => std_logic_vector(to_unsigned(10,32)),
      --
      in_port_tready_out   => in_port_tready_out,
      in_port_tdata_in     => in_port_tdata_in,
      in_port_tvalid_in    => in_port_tvalid_in,
      --
      out_port_tready_in   => out_port_tready_in,
      out_port_tdata_out   => out_port_tdata_out,
      out_port_tvalid_out  => out_port_tvalid_out,
      out_port_tlast_out   => out_port_tlast_out,
      out_port_tuser_out   => out_port_tuser_out,
      out_port_tkeep_out   => out_port_tkeep_out,
      out_port_tstrb_out   => out_port_tstrb_out
      );

  stimulus: process
  begin

    aresetn            <= '0';
    in_port_tdata_in   <= (others=>'0');
    in_port_tvalid_in  <= '0';
    out_port_tready_in <= '1';

    wait for clock_period*10;
    aresetn <= '1';
    wait for clock_period*10;

    -- change states on falling edge of clock, to be ready for next rising edge
    -- not necessary because I start the clock LOW
    --wait for clock_period/2;
    
    -- Put test bench stimuli here
    -- TVALID=1, TREADY=1 -> normal operation
    in_port_tdata_in   <= x"060504030201";
    in_port_tvalid_in  <= '1';
    wait for clock_period;
    in_port_tdata_in   <= x"0C0B0A090807";
    wait for clock_period;
    in_port_tdata_in   <= x"1211100F0E0D";
    wait for clock_period;
    in_port_tdata_in   <= x"181716151413";
    wait for clock_period;
    in_port_tdata_in   <= x"000000000000";
    in_port_tvalid_in  <= '0';
    --
    -- timeout after the last
    wait for 15*clock_period;
    --
    -- another packet 
    in_port_tdata_in   <= x"060504030201";
    in_port_tvalid_in  <= '1';
    wait for clock_period;
    in_port_tdata_in   <= x"0C0B0A090807";
    wait for clock_period;
    in_port_tdata_in   <= x"1211100F0E0D";
    wait for clock_period;
    in_port_tdata_in   <= x"181716151413";
    wait for clock_period;
    in_port_tdata_in   <= x"000000000000";
    in_port_tvalid_in  <= '0';
    --
    -- timeout after the last
    wait for 15*clock_period;

    -- another packet; timeout after the first
    in_port_tdata_in   <= x"060504030201";
    in_port_tvalid_in  <= '1';
    wait for clock_period;
    in_port_tdata_in   <= x"000000000000";
    in_port_tvalid_in  <= '0';
    --
    -- 
    wait for 15*clock_period;

    -- another packet; timeout after the second
    in_port_tdata_in   <= x"060504030201";
    in_port_tvalid_in  <= '1';
    wait for clock_period;
    in_port_tdata_in   <= x"0C0B0A090807";
    wait for clock_period;
    in_port_tdata_in   <= x"000000000000";
    in_port_tvalid_in  <= '0';
    --
    -- 
    wait for 15*clock_period;

    -- another packet; timeout after the third
    in_port_tdata_in   <= x"060504030201";
    in_port_tvalid_in  <= '1';
    wait for clock_period;
    in_port_tdata_in   <= x"0C0B0A090807";
    wait for clock_period;
    in_port_tdata_in   <= x"1211100F0E0D";
    wait for clock_period;
    in_port_tdata_in   <= x"000000000000";
    in_port_tvalid_in  <= '0';
    --
    -- 
    wait for 15*clock_period;

    -- now again timeout after the third, but receiver not ready
    in_port_tdata_in   <= x"060504030201";
    in_port_tvalid_in  <= '1';
    wait for clock_period;
    in_port_tdata_in   <= x"0C0B0A090807";
    wait for clock_period;
    in_port_tdata_in   <= x"1211100F0E0D";
    wait for clock_period;
    in_port_tdata_in   <= x"000000000000";
    in_port_tvalid_in  <= '0';
    out_port_tready_in <= '0';
    --
    -- here the watchdog should be kept reset, because we still have 1 word to transmit
    wait for 15*clock_period;
    out_port_tready_in <= '1';
    wait for 3*clock_period;
    out_port_tready_in <= '0';
    -- here the watchdog should start
    wait for 15*clock_period;
    out_port_tready_in <= '1';
    wait for 3*clock_period;


    in_port_tvalid_in  <= '0';

    -- now wait for the SM to send out the packet
    wait for clock_period*25;

    
    stop_the_clock <= true;
    wait;
  end process;


  clocking: process
  begin
    while not stop_the_clock loop
      aclk <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;


end Behavioral;
