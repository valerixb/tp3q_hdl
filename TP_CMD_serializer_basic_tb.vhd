----------------------------------------------------------------------------------
-- testbench for Timepix Command Serializer
-- 
-- basic transaction check 
--
-- latest rev by valerix, jul 28 2023
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

entity TP_CMD_serializer_basic_tb is
--  Generic ( );
--  Port ( );
end TP_CMD_serializer_basic_tb;

architecture Behavioral of TP_CMD_serializer_basic_tb is

  component TP_CMD_serializer_v1_0 is
    generic (
      C_S_AXIS_TDATA_WIDTH	: integer	:= 8
    );
    port (
      reset_TPEnable    :  in std_logic;
      TPEnable          : out std_logic;
      TPData            : out std_logic;
      tx_bytes_dbg_cntr : out std_logic_vector(15 downto 0);
      -- input 8-bit AXI Stream
      S_AXIS_ACLK       :  in std_logic;
      S_AXIS_ARESETN    :  in std_logic;
      S_AXIS_TREADY     : out std_logic;
      S_AXIS_TDATA      :  in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
      S_AXIS_TSTRB      :  in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
      S_AXIS_TLAST      :  in std_logic;
      S_AXIS_TVALID     :  in std_logic
    );
  end component TP_CMD_serializer_v1_0;

  constant clock_period: time := 25 ns;
  signal stop_the_clock: boolean;
  
  signal    aclk                       : STD_LOGIC;
  signal    aresetn                    : STD_LOGIC;
  --
  signal    s00_axis_tvalid            : STD_LOGIC;
  signal    s00_axis_tdata             : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal    s00_axis_tstrb             : STD_LOGIC_VECTOR(0 DOWNTO 0);
  signal    s00_axis_tlast             : STD_LOGIC;
  signal    s00_axis_tready            : STD_LOGIC;
  --
  signal    reset_TPEnable             : std_logic;
  signal    TPEnable                   : std_logic;
  signal    TPData                     : std_logic;
  signal    tx_bytes_dbg_cntr          : std_logic_vector(15 downto 0);


begin

-- Instantiation of Axi Stream Bus Interface
TP_CMD_serializer_v1_0_inst : TP_CMD_serializer_v1_0
	generic map (
		C_S_AXIS_TDATA_WIDTH	=> 8
	)
	port map (
        reset_TPEnable    => reset_TPEnable,
        TPEnable          => TPEnable,
        TPData            => TPData,
        tx_bytes_dbg_cntr => tx_bytes_dbg_cntr,
        --
		S_AXIS_ACLK	      => aclk,
		S_AXIS_ARESETN	  => aresetn,
		S_AXIS_TREADY	  => s00_axis_tready,
		S_AXIS_TDATA	  => s00_axis_tdata,
		S_AXIS_TSTRB	  => s00_axis_tstrb,
		S_AXIS_TLAST	  => s00_axis_tlast,
		S_AXIS_TVALID	  => s00_axis_tvalid
	);


  stimulus: process
  begin

    aresetn         <= '0';
    s00_axis_tvalid <= '0';
    s00_axis_tlast  <= '0';
    s00_axis_tstrb  <= (others => '1');
    s00_axis_tdata  <= (others => '0');
    reset_TPEnable  <= '0';

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

    -- send packet
    -- 
    s00_axis_tdata  <= x"AA";
    s00_axis_tvalid <= '1';
    wait for clock_period;
    s00_axis_tdata  <= x"55";
    wait for clock_period*8;
    s00_axis_tdata  <= x"C3";
    wait for clock_period*8;
    s00_axis_tvalid <= '0';
    wait for clock_period*20;
    s00_axis_tdata  <= x"AB";
    s00_axis_tvalid <= '1';
    wait for clock_period;
    s00_axis_tvalid <= '0';
    --

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
