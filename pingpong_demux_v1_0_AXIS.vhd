library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.math_real.all;

entity pingpong_demux_v1_0_AXIS is
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
end pingpong_demux_v1_0_AXIS;

architecture arch_imp of pingpong_demux_v1_0_AXIS is

signal chan : integer range 0 to 1 :=0;
signal int_valid0, int_valid1, in_ready, out_ready, int_tlast : std_logic;
signal int_data : std_logic_vector(C_AXIS_TDATA_WIDTH-1 downto 0);
signal int_tkeep : std_logic_vector((C_AXIS_TDATA_WIDTH/8)-1 downto 0);
signal int_tuser : std_logic_vector(C_AXIS_TUSER_WIDTH-1 downto 0);
signal int_tid   : std_logic_vector(C_AXIS_TID_WIDTH-1 downto 0);
signal int_tdest : std_logic_vector(C_AXIS_TDEST_WIDTH-1 downto 0);

begin

  in_ready <= M0_AXIS_TREADY when chan=0 else M1_AXIS_TREADY;
  S_AXIS_TREADY <= out_ready;
  -- stream master 0
  M0_AXIS_TVALID <= int_valid0;
  M0_AXIS_TDATA  <= int_data;
  M0_AXIS_TSTRB  <= int_tkeep;
  M0_AXIS_TKEEP  <= int_tkeep;
  M0_AXIS_TUSER  <= int_tuser;
  M0_AXIS_TID    <= int_tid;
  M0_AXIS_TDEST  <= int_tdest;
  M0_AXIS_TLAST  <= int_tlast;
  -- stream master 1
  M1_AXIS_TVALID <= int_valid1;
  M1_AXIS_TDATA  <= int_data;
  M1_AXIS_TSTRB  <= int_tkeep;
  M1_AXIS_TKEEP  <= int_tkeep;
  M1_AXIS_TUSER  <= int_tuser;
  M1_AXIS_TID    <= int_tid;
  M1_AXIS_TDEST  <= int_tdest;
  M1_AXIS_TLAST  <= int_tlast;


  data_register: process( aclk )
  begin
    if( rising_edge(aclk) ) then
      if( aresetn='0' ) then
        int_data  <= (others => '0');
        int_valid0 <= '0';
        int_valid1 <= '0';
        int_tlast <= '0';
        int_tkeep <= (others => '1');
        int_tuser <= (others => '0');
        int_tid   <= (others => '0');
        int_tdest <= (others => '0');
      else
        out_ready <= in_ready;
        if( in_ready='1' ) then
          int_data  <= S_AXIS_TDATA;
          if( chan=0 ) then
            int_valid0 <= S_AXIS_TVALID;
            int_valid1 <= '0'; 
          else
            int_valid0 <= '0';
            int_valid1 <= S_AXIS_TVALID; 
          end if;
          int_tlast <= S_AXIS_TLAST;
          int_tkeep <= S_AXIS_TKEEP;
          int_tuser <= S_AXIS_TUSER;
          int_tid   <= S_AXIS_TID;
          int_tdest <= S_AXIS_TDEST;
        else
        -- output not ready: latch current values
          int_data  <= int_data;
          int_valid0 <= int_valid0;
          int_valid1 <= int_valid1;
          int_tlast <= int_tlast;
          int_tkeep <= int_tkeep;
          int_tuser <= int_tuser;
          int_tid   <= int_tid;
          int_tdest <= int_tdest;
        end if;
        
      end if;
    end if;
  end process data_register;

  select_chan: process( aclk )
  begin
    if( rising_edge(aclk) ) then
      if( aresetn='0' ) then
        chan<=0;
      else
        if( chan=0 ) then
          if( busy0='0' ) then
            chan<=0;
          else
            chan<=1;
          end if;
        else
          if( busy1='0' ) then
            chan<=1;
          else
            chan<=0;
          end if;
        end if;
      end if;
    end if;
  end process select_chan;
  
end arch_imp;
