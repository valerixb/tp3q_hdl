----------------------------------------------------------------------------------
-- testbench for stream generator v1.0
-- 
-- latest rev by valerix, jan 23 2023
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

entity streamgen_tb is
	generic (
		-- Parameters of Axi Master Bus Interface M00_AXIS
		C_M00_AXIS_TDATA_WIDTH	: integer	:= 64;
		C_M00_AXIS_TUSER_WIDTH  : integer	:= 16;
		C_M00_AXIS_TID_WIDTH    : integer	:= 8;
		C_M00_AXIS_TDEST_WIDTH  : integer	:= 4;

		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 6
	);
--  Port ( );
end streamgen_tb;

architecture Behavioral of streamgen_tb is

	component streamgen_v1_0_M00_AXIS is
		generic (
		C_M_AXIS_TDATA_WIDTH    : integer	:= 64;
		C_M_AXIS_TUSER_WIDTH    : integer	:= 16;
		C_M_AXIS_TID_WIDTH      : integer	:= 8;
		C_M_AXIS_TDEST_WIDTH    : integer	:= 4;
		C_S_AXIlite_DATA_WIDTH	: integer	:= 32
		);
		port (
        start_strobe                  : in std_logic;
        stop_strobe                   : in std_logic;
	    STREAM_generating             : out std_logic;
        STREAM_completed_repetitions  : out std_logic_vector(C_S_AXIlite_DATA_WIDTH-1 downto 0);
	    AXI_start_generation          : in  std_logic;
	    AXI_stop_generation           : in  std_logic;
	    AXI_ext_trig_enable           : in  std_logic;
	    AXI_generator_mode            : in  std_logic_vector(C_S_AXIlite_DATA_WIDTH-1 downto 0);
	    AXI_generator_seed            : in  std_logic_vector(C_S_AXIlite_DATA_WIDTH-1 downto 0);
	    AXI_stream_length             : in  std_logic_vector(C_S_AXIlite_DATA_WIDTH-1 downto 0);
	    AXI_tot_repetitions           : in  std_logic_vector(C_S_AXIlite_DATA_WIDTH-1 downto 0);
	    AXI_rest_ticks                : in  std_logic_vector(C_S_AXIlite_DATA_WIDTH-1 downto 0);
        --
		M_AXIS_ACLK	    : in std_logic;
		M_AXIS_ARESETN	: in std_logic;
		M_AXIS_TVALID	: out std_logic;
		M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		M_AXIS_TKEEP	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		M_AXIS_TUSER	: out std_logic_vector(C_M_AXIS_TUSER_WIDTH-1 downto 0);
		M_AXIS_TID   	: out std_logic_vector(C_M_AXIS_TID_WIDTH-1 downto 0);
		M_AXIS_TDEST   	: out std_logic_vector(C_M_AXIS_TDEST_WIDTH-1 downto 0);
		M_AXIS_TLAST	: out std_logic;
		M_AXIS_TREADY	: in std_logic
		);
	end component streamgen_v1_0_M00_AXIS;

  signal STREAM_generating             : std_logic;
  signal STREAM_completed_repetitions  : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal AXI_start_generation          : std_logic;
  signal AXI_stop_generation           : std_logic;
  signal AXI_ext_trig_enable           : std_logic;
  signal AXI_generator_mode            : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal AXI_generator_seed            : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal AXI_stream_length             : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal AXI_tot_repetitions           : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal AXI_rest_ticks                : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal m00_axis_tkeep	               : std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
  signal m00_axis_tuser	               : std_logic_vector(C_M00_AXIS_TUSER_WIDTH-1 downto 0);
  signal m00_axis_tid                  : std_logic_vector(C_M00_AXIS_TID_WIDTH-1 downto 0);
  signal m00_axis_tdest                : std_logic_vector(C_M00_AXIS_TDEST_WIDTH-1 downto 0);

  signal    start_strobe               : STD_LOGIC;
  signal    stop_strobe                : STD_LOGIC;
  signal    aclk                       : STD_LOGIC;
  signal    aresetn                    : STD_LOGIC;
  signal    m00_axis_tvalid            : STD_LOGIC;
  signal    m00_axis_tdata             : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal    m00_axis_tstrb             : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal    m00_axis_tlast             : STD_LOGIC;
  signal    m00_axis_tready            : STD_LOGIC;

  constant clock_period: time := 6 ns;
  signal stop_the_clock: boolean;
  
  constant STREAM_LEN  : integer := 38;
  constant REPETITIONS : integer := 5;
  constant REST        : integer := 10;

begin

streamgen_v1_0_M00_AXIS_inst : streamgen_v1_0_M00_AXIS
	generic map (
		C_M_AXIS_TDATA_WIDTH	=> C_M00_AXIS_TDATA_WIDTH,
		C_M_AXIS_TUSER_WIDTH  => C_M00_AXIS_TUSER_WIDTH,
		C_M_AXIS_TID_WIDTH    => C_M00_AXIS_TID_WIDTH,
		C_M_AXIS_TDEST_WIDTH  => C_M00_AXIS_TDEST_WIDTH,
		C_S_AXIlite_DATA_WIDTH => C_S00_AXI_DATA_WIDTH
	)
	port map (
        start_strobe    => start_strobe,
        stop_strobe     => stop_strobe,
	    STREAM_generating            => STREAM_generating,
        STREAM_completed_repetitions => STREAM_completed_repetitions,
	    AXI_start_generation         => AXI_start_generation,
	    AXI_stop_generation          => AXI_stop_generation,
	    AXI_ext_trig_enable          => AXI_ext_trig_enable,
	    AXI_generator_mode           => AXI_generator_mode,
	    AXI_generator_seed           => AXI_generator_seed,
	    AXI_stream_length            => AXI_stream_length,
	    AXI_tot_repetitions          => AXI_tot_repetitions,
	    AXI_rest_ticks               => AXI_rest_ticks,
	    --
		M_AXIS_ACLK	    => aclk,
		M_AXIS_ARESETN	=> aresetn,
		M_AXIS_TVALID	=> m00_axis_tvalid,
		M_AXIS_TDATA	=> m00_axis_tdata,
		M_AXIS_TSTRB	=> m00_axis_tstrb,
		M_AXIS_TKEEP	=> m00_axis_tkeep,
		M_AXIS_TUSER	=> m00_axis_tuser,
		M_AXIS_TID   	=> m00_axis_tid,
		M_AXIS_TDEST   	=> m00_axis_tdest,
		M_AXIS_TLAST	=> m00_axis_tlast,
		M_AXIS_TREADY	=> m00_axis_tready
	);




  stimulus: process
  begin

    aresetn <= '0';
    start_strobe <= '0';
    stop_strobe <= '0';
    m00_axis_tready <= '1';
    AXI_start_generation <= '0';
    AXI_stop_generation<= '0';
    AXI_ext_trig_enable <= '1';
    AXI_generator_mode  <= x"00000001";
    AXI_generator_seed  <= x"0000ABCD";
    AXI_stream_length   <= std_logic_vector(to_unsigned(STREAM_LEN,C_S00_AXI_DATA_WIDTH));
    AXI_tot_repetitions <= std_logic_vector(to_unsigned(REPETITIONS,C_S00_AXI_DATA_WIDTH));
    AXI_rest_ticks      <= std_logic_vector(to_unsigned(REST,C_S00_AXI_DATA_WIDTH));

    wait for clock_period*10;
    aresetn <= '1';
    wait for clock_period*10;

    -- change states on falling edge of clock, to be ready for next rising edge
    -- not necessary because I start the clock LOW
    --wait for clock_period/2;
    
    -- Put test bench stimuli here

    -- allow the state machine to give the initial delay
--    m00_axis_tready <= '0';
    wait for clock_period*10;
    -- trigger
    start_strobe <= '1';
    wait for clock_period*2;
    --wait for clock_period;
    --m00_axis_tready <= '0';
    wait for clock_period;
--    m00_axis_tready <= '1';
    wait for clock_period;
    start_strobe <= '0';


    -- wait a bit, then give a second trigger
    wait for clock_period*100;
    m00_axis_tready <= '0';
    wait for clock_period*2;
    -- trigger
    start_strobe <= '1';
    wait for clock_period*2;
    start_strobe <= '0';
    wait for clock_period;
    m00_axis_tready <= '1';
    wait for clock_period*4;
    m00_axis_tready <= '0';
    wait for clock_period*2;
    m00_axis_tready <= '1';

    -- user stop
    wait for clock_period*26;
    stop_strobe <= '1';
    wait for clock_period*2;
    stop_strobe <= '0';

    -- now wait for the SM to send out the packet
    wait for clock_period*40;
    
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
