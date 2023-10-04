library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity streamgen_v1_0 is
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
	port (
        start_strobe : in std_logic;
        stop_strobe  : in std_logic;

        -- common clock and reset of both AXI-lite and AXIStream interfaces        
		aclk	: in std_logic;
		aresetn	: in std_logic;

		-- Ports of Axi Master Bus Interface M00_AXIS
		m00_axis_tvalid	: out std_logic;
		m00_axis_tdata	: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
		m00_axis_tstrb	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m00_axis_tkeep	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m00_axis_tuser	: out std_logic_vector(C_M00_AXIS_TUSER_WIDTH-1 downto 0);
		m00_axis_tid   	: out std_logic_vector(C_M00_AXIS_TID_WIDTH-1 downto 0);
		m00_axis_tdest 	: out std_logic_vector(C_M00_AXIS_TDEST_WIDTH-1 downto 0);
		m00_axis_tlast	: out std_logic;
		m00_axis_tready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S00_AXI
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
		s00_axi_rready	: in std_logic
	);
end streamgen_v1_0;

architecture arch_imp of streamgen_v1_0 is

	-- component declaration
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

	component streamgen_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 6
		);
		port (
	    STREAM_generating             : in  std_logic;
        STREAM_completed_repetitions  : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    AXI_start_generation          : out std_logic;
	    AXI_stop_generation           : out std_logic;
	    AXI_ext_trig_enable           : out std_logic;
	    AXI_generator_mode            : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    AXI_generator_seed            : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    AXI_stream_length             : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    AXI_tot_repetitions           : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    AXI_rest_ticks                : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
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
	end component streamgen_v1_0_S00_AXI;


	signal STREAM_generating             :  std_logic;
    signal STREAM_completed_repetitions  : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
	signal AXI_start_generation          : std_logic;
	signal AXI_stop_generation           : std_logic;
	signal AXI_ext_trig_enable           : std_logic;
	signal AXI_generator_mode            : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
	signal AXI_generator_seed            : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
	signal AXI_stream_length             : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
	signal AXI_tot_repetitions           : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
	signal AXI_rest_ticks                : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);


begin

-- Instantiation of Axi Bus Interface M00_AXIS
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

-- Instantiation of Axi Bus Interface S00_AXI
streamgen_v1_0_S00_AXI_inst : streamgen_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
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

	-- Add user logic here

	-- User logic ends

end arch_imp;
