--
-- AXI Stream monitor
--
-- I made it just because the Xilinx AXIS Broadcaster IP does not work
-- 
-- passthru axi stream + monitor port
-- note that no TREADY is present on monitor port to avoid slowing down
-- the main stream
--
-- common clock and reset
--
-- passthru stream is not registered, to avoid adding latency
-- monitor port is registered, to help timig closure
--
-- latest rev dec 13 2023
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axistream_monitor_v1_0 is
  generic(
    AXIS_TDATA_WIDTH    : integer := 48
  );
  port(
    clk              :  in std_logic;
    resetn           :  in std_logic;
    --
    instream_tready  : out std_logic;
    instream_tdata   :  in std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0);
    instream_tstrb   :  in std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0);
    instream_tlast   :  in std_logic;
    instream_tvalid  :  in std_logic;
    --
    outstream_tready  :  in std_logic;
    outstream_tdata   : out std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0);
    outstream_tstrb   : out std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0);
    outstream_tlast   : out std_logic;
    outstream_tvalid  : out std_logic;
    --
    monitor_tdata     : out std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0);
    monitor_tstrb     : out std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0);
    monitor_tlast     : out std_logic;
    monitor_tvalid    : out std_logic
    --
  );
end axistream_monitor_v1_0;

architecture arch_imp of axistream_monitor_v1_0 is

signal tdata_buf : std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0);
signal tstrb_buf : std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0);
signal tlast_buf, tvalid_buf : std_logic;

begin
  instream_tready  <= outstream_tready;
  outstream_tdata  <= instream_tdata;
  outstream_tstrb  <= instream_tstrb;
  outstream_tlast  <= instream_tlast;
  outstream_tvalid <= instream_tvalid;
  --
  monitor_tdata    <= tdata_buf;
  monitor_tstrb    <= tstrb_buf;
  monitor_tlast    <= tlast_buf;
  monitor_tvalid   <= tvalid_buf;
  
  monitor_reg: process(clk, resetn)
    begin
      if(rising_edge(clk)) then
        if( resetn='0' ) then
          tdata_buf  <= (others=>'0');
          tstrb_buf  <= (others=>'0');
          tlast_buf  <= '0';
          tvalid_buf <= '0';
        else
          tdata_buf  <= instream_tdata;
          tstrb_buf  <= instream_tstrb;
          tlast_buf  <= instream_tlast;
          tvalid_buf <= instream_tvalid and outstream_tready;
        end if; -- if not reset
      end if; -- if clk edge
    end process monitor_reg;
  
end arch_imp;
