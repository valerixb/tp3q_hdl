----------------------------------------------------------------------------------
-- testbench for UDP packetizer v1.0
--
-- TREADY/TVALID management check 
--
-- latest rev by valerix, feb 20 2023
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

entity UDPpktzr_tb is
--  Generic ( );
--  Port ( );
end UDPpktzr_tb;

architecture Behavioral of UDPpktzr_tb is

	component UDPpacketizer_v1_0_AXIS is
		generic (
        MTU                     : integer	:= 9000;
		C_M_AXIS_TDATA_WIDTH    : integer	:= 64;
		C_M_AXIS_TUSER_WIDTH    : integer	:= 16;
		C_M_AXIS_TID_WIDTH      : integer	:= 8;
		C_M_AXIS_TDEST_WIDTH    : integer	:= 4;
--		C_S_AXIlite_DATA_WIDTH	: integer	:= 32;
--		C_M_START_COUNT	: integer	:= 32
		C_S_AXIS_TDATA_WIDTH	: integer	:= 64;
		C_S_AXIS_TUSER_WIDTH    : integer	:= 16;
		C_S_AXIS_TID_WIDTH      : integer	:= 8;
		C_S_AXIS_TDEST_WIDTH    : integer	:= 4;
		C_S_AXIlite_DATA_WIDTH	: integer	:= 32
		);
		port (
		-- config ports
		PKTZR_enable     : in std_logic;
		SRC_IP           : in std_logic_vector(31 downto 0);
		SRC_MAC          : in std_logic_vector(47 downto 0);
		SRC_PORT         : in std_logic_vector(15 downto 0);
		DEST_IP          : in std_logic_vector(31 downto 0);
		DEST_MAC         : in std_logic_vector(47 downto 0);
		DEST_PORT        : in std_logic_vector(15 downto 0);
		WATCHDOG_TIMEOUT : in std_logic_vector(C_S_AXIlite_DATA_WIDTH-1 downto 0);

        -- stream slave
        S_AXIS_ACLK	    : in std_logic;
		S_AXIS_ARESETN	: in std_logic;
		S_AXIS_TREADY	: out std_logic;
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		S_AXIS_TKEEP	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		S_AXIS_TUSER	: in std_logic_vector(C_S_AXIS_TUSER_WIDTH-1 downto 0);
		S_AXIS_TID   	: in std_logic_vector(C_S_AXIS_TID_WIDTH-1 downto 0);
		S_AXIS_TDEST   	: in std_logic_vector(C_S_AXIS_TDEST_WIDTH-1 downto 0);
		S_AXIS_TLAST	: in std_logic;
		S_AXIS_TVALID	: in std_logic;

        -- stream master
		M_AXIS_ACLK	: in std_logic;
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
	end component UDPpacketizer_v1_0_AXIS;

  constant clock_period: time := 6 ns;
  signal stop_the_clock: boolean;
  
  signal    aclk                       : STD_LOGIC;
  signal    aresetn                    : STD_LOGIC;
  --
  signal    m00_axis_tvalid            : STD_LOGIC;
  signal    m00_axis_tdata             : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal    m00_axis_tstrb             : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal    m00_axis_tkeep             : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal    m00_axis_tlast             : STD_LOGIC;
  signal    m00_axis_tready            : STD_LOGIC;
  signal    m00_axis_tuser             : STD_LOGIC_VECTOR(15 DOWNTO 0);
  signal    m00_axis_tid               : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal    m00_axis_tdest             : STD_LOGIC_VECTOR(3 DOWNTO 0);
  --
  signal    s00_axis_tvalid            : STD_LOGIC;
  signal    s00_axis_tdata             : STD_LOGIC_VECTOR(63 DOWNTO 0);
  signal    s00_axis_tstrb             : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal    s00_axis_tkeep             : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal    s00_axis_tlast             : STD_LOGIC;
  signal    s00_axis_tready            : STD_LOGIC;
  --
  signal    pktzr_enable               : STD_LOGIC;
  

begin

-- Instantiation of Axi Stream Bus Interface
UDPpacketizer_v1_0_AXIS_inst : UDPpacketizer_v1_0_AXIS
	generic map (
	    MTU                     => 9000,
	    --
		C_M_AXIS_TDATA_WIDTH	=> 64,
		C_M_AXIS_TUSER_WIDTH    => 16,
		C_M_AXIS_TID_WIDTH      => 8,
		C_M_AXIS_TDEST_WIDTH    => 4,
        --
		C_S_AXIS_TDATA_WIDTH	=> 64,
		C_S_AXIS_TUSER_WIDTH    => 16,
		C_S_AXIS_TID_WIDTH      => 8,
		C_S_AXIS_TDEST_WIDTH    => 4,
		--
		C_S_AXIlite_DATA_WIDTH  => 32
	)
	port map (
	    PKTZR_enable     => pktzr_enable,
		SRC_IP           => x"C0A8050A",  -- 192.168.5.10
		SRC_MAC          => x"00_0A_35_00_00_01",
		SRC_PORT         => x"13ED",  -- 5101
		DEST_IP          => x"C0A805FF",  -- broadcast: 192.168.5.255
		DEST_MAC         => x"FF_FF_FF_FF_FF_FF",  -- broadcast
		DEST_PORT        => x"13ED",  -- 5101
		WATCHDOG_TIMEOUT => x"0002625A", -- = 156250 decimal = 1 ms
        -- stream slave
		S_AXIS_ACLK	    => aclk,
		S_AXIS_ARESETN	=> aresetn,
		S_AXIS_TREADY	=> s00_axis_tready,
		S_AXIS_TDATA	=> s00_axis_tdata,
		S_AXIS_TSTRB	=> s00_axis_tstrb,
		S_AXIS_TKEEP	=> s00_axis_tkeep,
		S_AXIS_TUSER	=> (others => '0'),
		S_AXIS_TID   	=> (others => '0'),
		S_AXIS_TDEST   	=> (others => '0'),
		S_AXIS_TLAST	=> s00_axis_tlast,
		S_AXIS_TVALID	=> s00_axis_tvalid,
        -- stream master
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

    aresetn         <= '0';
    m00_axis_tready <= '1';
    s00_axis_tvalid <= '0';
    s00_axis_tlast  <= '0';
    s00_axis_tkeep  <= (others => '1');
    s00_axis_tstrb  <= (others => '1');
    s00_axis_tdata  <= (others => '0');
    pktzr_enable    <= '1';

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
    s00_axis_tdata  <= x"6f70706970206d75";
    s00_axis_tlast  <= '0';
    s00_axis_tvalid <= '1';
    wait for clock_period;
    s00_axis_tdata  <= x"65206f74756c7020"; 
    wait for clock_period;
    s00_axis_tdata  <= x"6e69726570617020"; 
    --m00_axis_tready <= '0';
    s00_axis_tvalid <= '0';
    wait for clock_period*2;
    s00_axis_tvalid <= '1';
    wait for clock_period;
    s00_axis_tdata  <= x"727562656863206f"; 
    wait for clock_period;
    s00_axis_tdata  <= x"206520616b687361"; 
    wait for clock_period;
    s00_axis_tdata  <= x"6c69646f6b6f726b"; 
    wait for clock_period;
    s00_axis_tdata  <= x"2e2e616e65684720";
    s00_axis_tlast  <= '1'; 
    wait for clock_period;
    s00_axis_tdata  <= x"0000000000000000";
    s00_axis_tlast  <= '0';
    s00_axis_tvalid <= '0';
    --
    wait for clock_period*3;
    m00_axis_tready <= '0';

    -- now wait for the SM to send out the packet
    wait for clock_period*6;
    m00_axis_tready <= '1';

    wait for clock_period*4;
    -- drop READY on the last
    m00_axis_tready <= '0';
    wait for clock_period*2;
    m00_axis_tready <= '1';    
    wait for clock_period*15;

    -- send packet
    -- 
    s00_axis_tdata  <= x"6f70706970206d75";
    s00_axis_tlast  <= '0';
    s00_axis_tvalid <= '1';
    wait for clock_period;
    s00_axis_tdata  <= x"65206f74756c7020"; 
    wait for clock_period;
    s00_axis_tdata  <= x"6e69726570617020"; 
    wait for clock_period;
    s00_axis_tdata  <= x"727562656863206f"; 
    wait for clock_period;
    s00_axis_tdata  <= x"206520616b687361"; 
    wait for clock_period;
    s00_axis_tdata  <= x"6c69646f6b6f726b"; 
    wait for clock_period;
    s00_axis_tdata  <= x"2e2e616e65684720";
    s00_axis_tlast  <= '1'; 
    wait for clock_period;
    s00_axis_tdata  <= x"0000000000000000";
    s00_axis_tlast  <= '0';
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
