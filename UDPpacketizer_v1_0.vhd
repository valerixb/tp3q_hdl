library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UDPpacketizer_v1_0 is
	generic (
	    -- ethernet maximum transmission unit, in bytes. 9000=jumbo frames=our default (default eth is 1500)
        MTU                     : integer	:= 9000;

		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 6;

		-- Parameters of Axi Slave Bus Interface S00_AXIS
		C_S00_AXIS_TDATA_WIDTH	: integer	:= 64;
		C_S00_AXIS_TUSER_WIDTH  : integer	:= 16;
		C_S00_AXIS_TID_WIDTH    : integer	:= 8;
		C_S00_AXIS_TDEST_WIDTH  : integer	:= 4;

		-- Parameters of Axi Master Bus Interface M00_AXIS
		C_M00_AXIS_TDATA_WIDTH	: integer	:= 64;
		C_M00_AXIS_TUSER_WIDTH  : integer	:= 16;
		C_M00_AXIS_TID_WIDTH    : integer	:= 8;
		C_M00_AXIS_TDEST_WIDTH  : integer	:= 4
--		C_M00_AXIS_START_COUNT	: integer	:= 32;
	);
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line

        -- common clock and reset of both AXI-lite and AXIStream interfaces        
		aclk	: in std_logic;
		aresetn	: in std_logic;

		-- Ports of Axi Slave Bus Interface S00_AXI
--		s00_axi_aclk	: in std_logic;
--		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S00_AXIS
--		s00_axis_aclk	: in std_logic;
--		s00_axis_aresetn	: in std_logic;
		s00_axis_tready	: out std_logic;
		s00_axis_tdata	: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
		s00_axis_tstrb	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		s00_axis_tkeep	: in std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		s00_axis_tuser	: in std_logic_vector(C_M00_AXIS_TUSER_WIDTH-1 downto 0);
		s00_axis_tid   	: in std_logic_vector(C_M00_AXIS_TID_WIDTH-1 downto 0);
		s00_axis_tdest 	: in std_logic_vector(C_M00_AXIS_TDEST_WIDTH-1 downto 0);
		s00_axis_tlast	: in std_logic;
		s00_axis_tvalid	: in std_logic;

		-- Ports of Axi Master Bus Interface M00_AXIS
--		m00_axis_aclk	: in std_logic;
--		m00_axis_aresetn	: in std_logic;
		m00_axis_tvalid	: out std_logic;
		m00_axis_tdata	: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
		m00_axis_tstrb	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m00_axis_tkeep	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m00_axis_tuser	: out std_logic_vector(C_M00_AXIS_TUSER_WIDTH-1 downto 0);
		m00_axis_tid   	: out std_logic_vector(C_M00_AXIS_TID_WIDTH-1 downto 0);
		m00_axis_tdest 	: out std_logic_vector(C_M00_AXIS_TDEST_WIDTH-1 downto 0);
		m00_axis_tlast	: out std_logic;
		m00_axis_tready	: in std_logic;
		busy            : out std_logic
		
	);
end UDPpacketizer_v1_0;

architecture arch_imp of UDPpacketizer_v1_0 is

	-- component declaration
	component UDPpacketizer_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 6
		);
		port (
		-- config ports
		PKTZR_enable     : out std_logic;
		SRC_IP           : out std_logic_vector(31 downto 0);
		SRC_MAC          : out std_logic_vector(47 downto 0);
		SRC_PORT         : out std_logic_vector(15 downto 0);
		DEST_IP          : out std_logic_vector(31 downto 0);
		DEST_MAC         : out std_logic_vector(47 downto 0);
		DEST_PORT        : out std_logic_vector(15 downto 0);
		WATCHDOG_TIMEOUT : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        --
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component UDPpacketizer_v1_0_S00_AXI;


	component UDPpacketizer_v1_0_AXIS is
		generic (
        MTU                     : integer	:= 9000;
		C_M_AXIS_TDATA_WIDTH    : integer	:= 64;
		C_M_AXIS_TUSER_WIDTH    : integer	:= 16;
		C_M_AXIS_TID_WIDTH      : integer	:= 8;
		C_M_AXIS_TDEST_WIDTH    : integer	:= 4;
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
		M_AXIS_TREADY	: in std_logic;
		busy            : out std_logic
		);
	end component UDPpacketizer_v1_0_AXIS;

 
  signal pktzr_enable     : std_logic;
  signal src_ip           : std_logic_vector(31 downto 0);
  signal src_mac          : std_logic_vector(47 downto 0);
  signal src_port         : std_logic_vector(15 downto 0);
  signal dest_ip          : std_logic_vector(31 downto 0);
  signal dest_mac         : std_logic_vector(47 downto 0);
  signal dest_port        : std_logic_vector(15 downto 0);
  signal watchdog_timeout : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);


begin

-- Instantiation of Axi Bus Interface S00_AXI
UDPpacketizer_v1_0_S00_AXI_inst : UDPpacketizer_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
	    PKTZR_enable     => pktzr_enable,
		SRC_IP           => src_ip,
		SRC_MAC          => src_mac,
		SRC_PORT         => src_port,
		DEST_IP          => dest_ip,
		DEST_MAC         => dest_mac,
		DEST_PORT        => dest_port,
		WATCHDOG_TIMEOUT => watchdog_timeout,
        --
		S_AXI_ACLK	    => aclk,
		S_AXI_ARESETN	=> aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);


-- Instantiation of Axi Stream Bus Interface
UDPpacketizer_v1_0_AXIS_inst : UDPpacketizer_v1_0_AXIS
	generic map (
	    MTU                     => MTU,
		C_M_AXIS_TDATA_WIDTH	=> C_M00_AXIS_TDATA_WIDTH,
		C_M_AXIS_TUSER_WIDTH    => C_M00_AXIS_TUSER_WIDTH,
		C_M_AXIS_TID_WIDTH      => C_M00_AXIS_TID_WIDTH,
		C_M_AXIS_TDEST_WIDTH    => C_M00_AXIS_TDEST_WIDTH,
        --
		C_S_AXIS_TDATA_WIDTH	=> C_S00_AXIS_TDATA_WIDTH,
		C_S_AXIS_TUSER_WIDTH    => C_S00_AXIS_TUSER_WIDTH,
		C_S_AXIS_TID_WIDTH      => C_S00_AXIS_TID_WIDTH,
		C_S_AXIS_TDEST_WIDTH    => C_S00_AXIS_TDEST_WIDTH,
		C_S_AXIlite_DATA_WIDTH  => C_S00_AXI_DATA_WIDTH
	)
	port map (
	    PKTZR_enable     => pktzr_enable,
		SRC_IP           => src_ip,
		SRC_MAC          => src_mac,
		SRC_PORT         => src_port,
		DEST_IP          => dest_ip,
		DEST_MAC         => dest_mac,
		DEST_PORT        => dest_port,
		WATCHDOG_TIMEOUT => watchdog_timeout,
        -- stream slave
		S_AXIS_ACLK	    => aclk,
		S_AXIS_ARESETN	=> aresetn,
		S_AXIS_TREADY	=> s00_axis_tready,
		S_AXIS_TDATA	=> s00_axis_tdata,
		S_AXIS_TSTRB	=> s00_axis_tstrb,
		S_AXIS_TKEEP	=> s00_axis_tkeep,
		S_AXIS_TUSER	=> s00_axis_tuser,
		S_AXIS_TID   	=> s00_axis_tid,
		S_AXIS_TDEST   	=> s00_axis_tdest,
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
		M_AXIS_TREADY	=> m00_axis_tready,
		busy            => busy
	);

	-- Add user logic here

	-- User logic ends

end arch_imp;
