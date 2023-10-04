library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pingpong_demux_v1_0 is
	generic (
		C_AXIS_TDATA_WIDTH	: integer	:= 64;
		C_AXIS_TUSER_WIDTH  : integer	:= 16;
		C_AXIS_TID_WIDTH    : integer	:= 8;
		C_AXIS_TDEST_WIDTH  : integer	:= 4
	);
	port (
        -- common clock and reset
		aclk	: in std_logic;
		aresetn	: in std_logic;

		-- Ports of Axi Slave Bus Interface S00_AXIS
		s00_axis_tready	: out std_logic;
		s00_axis_tdata	: in std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
		s00_axis_tstrb	: in std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0);
		s00_axis_tkeep	: in std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0);
		s00_axis_tuser	: in std_logic_vector(C_AXIS_TUSER_WIDTH-1 downto 0);
		s00_axis_tid   	: in std_logic_vector(C_AXIS_TID_WIDTH-1 downto 0);
		s00_axis_tdest 	: in std_logic_vector(C_AXIS_TDEST_WIDTH-1 downto 0);
		s00_axis_tlast	: in std_logic;
		s00_axis_tvalid	: in std_logic;

		-- Ports of Axi Master Bus Interface M00_AXIS
		m00_axis_tvalid	: out std_logic;
		m00_axis_tdata	: out std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
		m00_axis_tstrb	: out std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m00_axis_tkeep	: out std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m00_axis_tuser	: out std_logic_vector(C_AXIS_TUSER_WIDTH-1 downto 0);
		m00_axis_tid   	: out std_logic_vector(C_AXIS_TID_WIDTH-1 downto 0);
		m00_axis_tdest 	: out std_logic_vector(C_AXIS_TDEST_WIDTH-1 downto 0);
		m00_axis_tlast	: out std_logic;
		m00_axis_tready	: in std_logic;
        busy0           : in std_logic;

		-- Ports of Axi Master Bus Interface M01_AXIS
		m01_axis_tvalid	: out std_logic;
		m01_axis_tdata	: out std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
		m01_axis_tstrb	: out std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m01_axis_tkeep	: out std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m01_axis_tuser	: out std_logic_vector(C_AXIS_TUSER_WIDTH-1 downto 0);
		m01_axis_tid   	: out std_logic_vector(C_AXIS_TID_WIDTH-1 downto 0);
		m01_axis_tdest 	: out std_logic_vector(C_AXIS_TDEST_WIDTH-1 downto 0);
		m01_axis_tlast	: out std_logic;
		m01_axis_tready	: in std_logic;
        busy1           : in std_logic		
	);
end pingpong_demux_v1_0;

architecture arch_imp of pingpong_demux_v1_0 is



component pingpong_demux_v1_0_AXIS is
  generic (
    C_AXIS_TDATA_WIDTH    : integer	:= 64;
    C_AXIS_TUSER_WIDTH    : integer	:= 16;
    C_AXIS_TID_WIDTH      : integer	:= 8;
    C_AXIS_TDEST_WIDTH    : integer	:= 4
  );
  port (
    -- common clock and reset
    aclk	: in std_logic;
	aresetn	: in std_logic;

    -- stream slave
    S_AXIS_TREADY    : out std_logic;
    S_AXIS_TDATA     : in std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
    S_AXIS_TSTRB     : in std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0);
    S_AXIS_TKEEP     : in std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0);
    S_AXIS_TUSER     : in std_logic_vector(C_AXIS_TUSER_WIDTH-1 downto 0);
    S_AXIS_TID       : in std_logic_vector(C_AXIS_TID_WIDTH-1 downto 0);
    S_AXIS_TDEST     : in std_logic_vector(C_AXIS_TDEST_WIDTH-1 downto 0);
    S_AXIS_TLAST     : in std_logic;
    S_AXIS_TVALID    : in std_logic;
    
    -- stream master 0
    M0_AXIS_TVALID   : out std_logic;
    M0_AXIS_TDATA    : out std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
    M0_AXIS_TSTRB    : out std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0);
    M0_AXIS_TKEEP    : out std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0);
    M0_AXIS_TUSER    : out std_logic_vector(C_AXIS_TUSER_WIDTH-1 downto 0);
    M0_AXIS_TID      : out std_logic_vector(C_AXIS_TID_WIDTH-1 downto 0);
    M0_AXIS_TDEST    : out std_logic_vector(C_AXIS_TDEST_WIDTH-1 downto 0);
    M0_AXIS_TLAST    : out std_logic;
    M0_AXIS_TREADY   : in std_logic;		
    busy0            : in std_logic;

    -- stream master 1
    M1_AXIS_TVALID   : out std_logic;
    M1_AXIS_TDATA    : out std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
    M1_AXIS_TSTRB    : out std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0);
    M1_AXIS_TKEEP    : out std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0);
    M1_AXIS_TUSER    : out std_logic_vector(C_AXIS_TUSER_WIDTH-1 downto 0);
    M1_AXIS_TID      : out std_logic_vector(C_AXIS_TID_WIDTH-1 downto 0);
    M1_AXIS_TDEST    : out std_logic_vector(C_AXIS_TDEST_WIDTH-1 downto 0);
    M1_AXIS_TLAST    : out std_logic;
    M1_AXIS_TREADY   : in std_logic;
    busy1            : in std_logic    		
  );
end component pingpong_demux_v1_0_AXIS;


begin

-- Instantiation
pingpong_demux_v1_0_AXIS_inst : pingpong_demux_v1_0_AXIS
  generic map (
    C_AXIS_TDATA_WIDTH    => C_AXIS_TDATA_WIDTH,
    C_AXIS_TUSER_WIDTH    => C_AXIS_TUSER_WIDTH,
    C_AXIS_TID_WIDTH      => C_AXIS_TID_WIDTH,
    C_AXIS_TDEST_WIDTH    => C_AXIS_TDEST_WIDTH
  )
  port map (
    aclk            => aclk,
    aresetn         => aresetn,
    -- stream slave
	S_AXIS_TREADY	=> s00_axis_tready,
	S_AXIS_TDATA	=> s00_axis_tdata,
	S_AXIS_TSTRB	=> s00_axis_tstrb,
	S_AXIS_TLAST	=> s00_axis_tlast,
	S_AXIS_TVALID	=> s00_axis_tvalid,
    S_AXIS_TKEEP    => s00_axis_tkeep,
    S_AXIS_TUSER    => s00_axis_tuser,
    S_AXIS_TID      => s00_axis_tid,
    S_AXIS_TDEST    => s00_axis_tdest,
    -- stream master 0
	M0_AXIS_TREADY	=> m00_axis_tready,
	M0_AXIS_TDATA	=> m00_axis_tdata,
	M0_AXIS_TSTRB	=> m00_axis_tstrb,
	M0_AXIS_TLAST	=> m00_axis_tlast,
	M0_AXIS_TVALID	=> m00_axis_tvalid,
    M0_AXIS_TKEEP   => m00_axis_tkeep,
    M0_AXIS_TUSER   => m00_axis_tuser,
    M0_AXIS_TID     => m00_axis_tid,
    M0_AXIS_TDEST   => m00_axis_tdest,
    busy0           => busy0,
    -- stream master 1
	M1_AXIS_TREADY	=> m01_axis_tready,
	M1_AXIS_TDATA	=> m01_axis_tdata,
	M1_AXIS_TSTRB	=> m01_axis_tstrb,
	M1_AXIS_TLAST	=> m01_axis_tlast,
	M1_AXIS_TVALID	=> m01_axis_tvalid,
    M1_AXIS_TKEEP   => m01_axis_tkeep,
    M1_AXIS_TUSER   => m01_axis_tuser,
    M1_AXIS_TID     => m01_axis_tid,
    M1_AXIS_TDEST   => m01_axis_tdest,
    busy1           => busy1
  );

end arch_imp;
