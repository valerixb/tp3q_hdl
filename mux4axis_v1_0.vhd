--
-- AXI Stream 4 to 1 multiplexer
--
-- I made it just because the Xilinx AXIS Interconnect IP does not work
-- common clock and reset
--
-- latest rev apr 17 2024
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux4axis_v1_0 is
  generic(
    AXIS_TDATA_WIDTH    : integer := 64;
    AXIS_TDEST_WIDTH    : integer := 4;
    AXIS_TID_WIDTH      : integer := 4;
    AXIS_TUSER_WIDTH    : integer := 4
  );
  port(
    clk              :  in std_logic;
    resetn           :  in std_logic;
    --
    instream0_tready  : out std_logic;
    instream0_tlast   :  in std_logic;
    instream0_tvalid  :  in std_logic;
    instream0_tdata   :  in std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0);
    instream0_tstrb   :  in std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0);
    instream0_tdest   :  in std_logic_vector(AXIS_TDEST_WIDTH-1 downto 0);
    instream0_tid     :  in std_logic_vector(AXIS_TID_WIDTH-1 downto 0);
    instream0_tuser   :  in std_logic_vector(AXIS_TUSER_WIDTH-1 downto 0);
    --
    instream1_tready  : out std_logic;
    instream1_tlast   :  in std_logic;
    instream1_tvalid  :  in std_logic;
    instream1_tdata   :  in std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0);
    instream1_tstrb   :  in std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0);
    instream1_tdest   :  in std_logic_vector(AXIS_TDEST_WIDTH-1 downto 0);
    instream1_tid     :  in std_logic_vector(AXIS_TID_WIDTH-1 downto 0);
    instream1_tuser   :  in std_logic_vector(AXIS_TUSER_WIDTH-1 downto 0);
    --
    instream2_tready  : out std_logic;
    instream2_tlast   :  in std_logic;
    instream2_tvalid  :  in std_logic;
    instream2_tdata   :  in std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0);
    instream2_tstrb   :  in std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0);
    instream2_tdest   :  in std_logic_vector(AXIS_TDEST_WIDTH-1 downto 0);
    instream2_tid     :  in std_logic_vector(AXIS_TID_WIDTH-1 downto 0);
    instream2_tuser   :  in std_logic_vector(AXIS_TUSER_WIDTH-1 downto 0);
    --
    instream3_tready  : out std_logic;
    instream3_tlast   :  in std_logic;
    instream3_tvalid  :  in std_logic;
    instream3_tdata   :  in std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0);
    instream3_tstrb   :  in std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0);
    instream3_tdest   :  in std_logic_vector(AXIS_TDEST_WIDTH-1 downto 0);
    instream3_tid     :  in std_logic_vector(AXIS_TID_WIDTH-1 downto 0);
    instream3_tuser   :  in std_logic_vector(AXIS_TUSER_WIDTH-1 downto 0);
    --
    outstream_tready  :  in std_logic;
    outstream_tlast   : out std_logic;
    outstream_tvalid  : out std_logic;
    outstream_tdata   : out std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0);
    outstream_tstrb   : out std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0);
    outstream_tdest   : out std_logic_vector(AXIS_TDEST_WIDTH-1 downto 0);
    outstream_tid     : out std_logic_vector(AXIS_TID_WIDTH-1 downto 0);
    outstream_tuser   : out std_logic_vector(AXIS_TUSER_WIDTH-1 downto 0)
  );
end mux4axis_v1_0;

architecture arch_imp of mux4axis_v1_0 is

signal chan_sel       : integer range 0 to 3 := 0;
signal inprogress     : std_logic := '0';
signal outreg_tlast   : std_logic;
signal outreg_tvalid  : std_logic;
signal outreg_tdata   : std_logic_vector(AXIS_TDATA_WIDTH-1 downto 0);
signal outreg_tstrb   : std_logic_vector((AXIS_TDATA_WIDTH/8)-1 downto 0);
signal outreg_tdest   : std_logic_vector(AXIS_TDEST_WIDTH-1 downto 0);
signal outreg_tid     : std_logic_vector(AXIS_TID_WIDTH-1 downto 0);
signal outreg_tuser   : std_logic_vector(AXIS_TUSER_WIDTH-1 downto 0);
 
begin

outstream_tlast   <= outreg_tlast;
outstream_tvalid  <= outreg_tvalid;
outstream_tdata   <= outreg_tdata;
outstream_tstrb   <= outreg_tstrb;
outstream_tdest   <= outreg_tdest;
outstream_tid     <= outreg_tid;
outstream_tuser   <= outreg_tuser;

instream0_tready <= outstream_tready when chan_sel=0 else '0';
instream1_tready <= outstream_tready when chan_sel=1 else '0';
instream2_tready <= outstream_tready when chan_sel=2 else '0';
instream3_tready <= outstream_tready when chan_sel=3 else '0';


robin: process(clk, resetn)
  begin
    if(rising_edge(clk)) then
      if( resetn='0' ) then
        chan_sel <= 0;
        inprogress <= '0';
      else
        if( (chan_sel=0) and 
            ( 
              ( (inprogress='1') and (outreg_tlast='1') and (outreg_tvalid='1') and (outstream_tready='1') ) 
              or
              ( (inprogress='0') and (instream0_tvalid='0') )
            )
          ) then
          chan_sel <= 1;
          inprogress <= instream1_tvalid;
          
        elsif( (chan_sel=1) and 
            ( 
              ( (inprogress='1') and (outreg_tlast='1') and (outreg_tvalid='1') and (outstream_tready='1') ) 
              or
              ( (inprogress='0') and (instream1_tvalid='0') )
            )
          ) then
          chan_sel <= 2;
          inprogress <= instream2_tvalid;

        elsif( (chan_sel=2) and 
            ( 
              ( (inprogress='1') and (outreg_tlast='1') and (outreg_tvalid='1') and (outstream_tready='1') ) 
              or
              ( (inprogress='0') and (instream2_tvalid='0') )
            )
          ) then
          chan_sel <= 3;
          inprogress <= instream3_tvalid;

        elsif( (chan_sel=3) and 
            ( 
              ( (inprogress='1') and (outreg_tlast='1') and (outreg_tvalid='1') and (outstream_tready='1') ) 
              or
              ( (inprogress='0') and (instream3_tvalid='0') )
            )
          ) then
          chan_sel <= 0;
          inprogress <= instream0_tvalid;

        else
          chan_sel <= chan_sel;
          inprogress <= inprogress;
        end if;  -- round robin
      end if; -- if not reset
    end if; -- if clk edge
  end process robin;


switchboard: process(clk, resetn)
  begin
    if(rising_edge(clk)) then
      if( resetn='0' ) then
        outreg_tvalid <= '0';
      else
        if(outstream_tready='1') then
          case chan_sel is
            when 0 =>
              outreg_tlast  <= instream0_tlast;
              outreg_tvalid <= instream0_tvalid;
              outreg_tdata  <= instream0_tdata;
              outreg_tstrb  <= instream0_tstrb;
              outreg_tdest  <= instream0_tdest;
              outreg_tid    <= instream0_tid;
              outreg_tuser  <= instream0_tuser;
            when 1 =>
              outreg_tlast  <= instream1_tlast;
              outreg_tvalid <= instream1_tvalid;
              outreg_tdata  <= instream1_tdata;
              outreg_tstrb  <= instream1_tstrb;
              outreg_tdest  <= instream1_tdest;
              outreg_tid    <= instream1_tid;
              outreg_tuser  <= instream1_tuser;
            when 2 =>
              outreg_tlast  <= instream2_tlast;
              outreg_tvalid <= instream2_tvalid;
              outreg_tdata  <= instream2_tdata;
              outreg_tstrb  <= instream2_tstrb;
              outreg_tdest  <= instream2_tdest;
              outreg_tid    <= instream2_tid;
              outreg_tuser  <= instream2_tuser;
            when 3 =>
              outreg_tlast  <= instream3_tlast;
              outreg_tvalid <= instream3_tvalid;
              outreg_tdata  <= instream3_tdata;
              outreg_tstrb  <= instream3_tstrb;
              outreg_tdest  <= instream3_tdest;
              outreg_tid    <= instream3_tid;
              outreg_tuser  <= instream3_tuser;
            when others =>
              outreg_tlast  <= outreg_tlast;            
              outreg_tvalid <= '0';
              outreg_tdata  <= outreg_tdata;
              outreg_tstrb  <= outreg_tstrb;
              outreg_tdest  <= outreg_tdest;
              outreg_tid    <= outreg_tid;
              outreg_tuser  <= outreg_tuser;
          end case;
        else -- output not ready
          outreg_tlast  <= outreg_tlast;            
          outreg_tvalid <= outreg_tvalid;
          outreg_tdata  <= outreg_tdata;
          outreg_tstrb  <= outreg_tstrb;
          outreg_tdest  <= outreg_tdest;
          outreg_tid    <= outreg_tid;
          outreg_tuser  <= outreg_tuser;
        end if;  -- if output ready
      end if; -- if not reset
    end if; -- if clk edge
  end process switchboard;


end arch_imp;
