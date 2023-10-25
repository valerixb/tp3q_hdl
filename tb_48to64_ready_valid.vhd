----------------------------------------------------------------------------------
-- testbench for 48/64 gearbox
--
-- TREADY/TVALID management check 
--
-- latest rev by valerix, oct 24 2023
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

entity tb_48to64_ready_valid is
--  Generic ( );
--  Port ( );
end tb_48to64_ready_valid;

architecture Behavioral of tb_48to64_ready_valid is

component gearbox_48_to_64 is
  generic(
    C_S_AXIS_TUSER_WIDTH  : integer	:= 16
    );
  port(
    clk                  : in std_logic;
    resetn               : in std_logic;
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
    --
    -- TVALID=1, TREADY=0
    in_port_tdata_in   <= x"060504030201";
    out_port_tready_in  <= '0';
    wait for clock_period;
    in_port_tdata_in   <= x"060504030201";
    wait for clock_period;
    in_port_tdata_in   <= x"060504030201";
    out_port_tready_in  <= '1';
    wait for clock_period;
    in_port_tdata_in   <= x"0C0B0A090807";
    wait for clock_period;
    in_port_tdata_in   <= x"1211100F0E0D";
    wait for clock_period;
    in_port_tdata_in   <= x"181716151413";
    wait for clock_period;
    --
    -- TVALID=0, TREADY=1 at first byte
    in_port_tvalid_in  <= '0';
    wait for clock_period;
    wait for clock_period;
    in_port_tdata_in   <= x"060504030201";
    in_port_tvalid_in  <= '1';
    wait for clock_period;
    in_port_tdata_in   <= x"0C0B0A090807";
    wait for clock_period;
    in_port_tdata_in   <= x"1211100F0E0D";
    wait for clock_period;
    in_port_tdata_in   <= x"181716151413";
    wait for clock_period;
    --
    -- again TVALID=0, TREADY=1 but not at first byte
    in_port_tdata_in   <= x"060504030201";
    wait for clock_period;
    in_port_tdata_in   <= x"0C0B0A090807";
    wait for clock_period;
    in_port_tvalid_in  <= '0';
    wait for clock_period;
    wait for clock_period;
    in_port_tdata_in   <= x"1211100F0E0D";
    in_port_tvalid_in  <= '1';
    wait for clock_period;
    in_port_tdata_in   <= x"181716151413";
    wait for clock_period;
    --
    -- TVALID=0, TREADY=0 first byte; reassert TREADY first
    in_port_tdata_in   <= x"060504030201";
    in_port_tvalid_in  <= '0';
    out_port_tready_in <= '0';
    wait for clock_period;
    wait for clock_period;
    out_port_tready_in <= '1';
    wait for clock_period;
    wait for clock_period;
    in_port_tvalid_in  <= '1';
    wait for clock_period;
    in_port_tdata_in   <= x"0C0B0A090807";
    wait for clock_period;
    in_port_tdata_in   <= x"1211100F0E0D";
    wait for clock_period;
    in_port_tdata_in   <= x"181716151413";
    wait for clock_period;
    --
    -- TVALID=0, TREADY=0 first byte; reassert TVALID first
    in_port_tdata_in   <= x"060504030201";
    in_port_tvalid_in  <= '0';
    out_port_tready_in <= '0';
    wait for clock_period;
    wait for clock_period;
    in_port_tvalid_in  <= '1';
    wait for clock_period;
    wait for clock_period;
    out_port_tready_in <= '1';
    wait for clock_period;
    in_port_tdata_in   <= x"0C0B0A090807";
    wait for clock_period;
    in_port_tdata_in   <= x"1211100F0E0D";
    wait for clock_period;
    in_port_tdata_in   <= x"181716151413";
    wait for clock_period;
    --
    -- TVALID=0, TREADY=0 second byte (where output valid goes low); reassert TREADY first
    in_port_tdata_in   <= x"060504030201";
    wait for clock_period;
    in_port_tdata_in   <= x"0C0B0A090807";
    wait for clock_period;
    in_port_tdata_in   <= x"1211100F0E0D";
    in_port_tvalid_in  <= '0';
    out_port_tready_in <= '0';
    wait for clock_period;
    wait for clock_period;
    out_port_tready_in <= '1';
    wait for clock_period;
    wait for clock_period;
    in_port_tvalid_in  <= '1';
    wait for clock_period;
    in_port_tdata_in   <= x"181716151413";
    wait for clock_period;
    --
    -- TVALID=0, TREADY=0 second byte (where output valid goes low); reassert TVALID first
    in_port_tdata_in   <= x"060504030201";
    wait for clock_period;
    in_port_tdata_in   <= x"0C0B0A090807";
    wait for clock_period;
    in_port_tdata_in   <= x"1211100F0E0D";
    in_port_tvalid_in  <= '0';
    out_port_tready_in <= '0';
    wait for clock_period;
    wait for clock_period;
    in_port_tvalid_in  <= '1';
    wait for clock_period;
    wait for clock_period;
    out_port_tready_in <= '1';
    wait for clock_period;
    in_port_tdata_in   <= x"181716151413";
    wait for clock_period;
    --


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
