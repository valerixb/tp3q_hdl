library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TP_CMD_serializer_v1_0 is
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
end TP_CMD_serializer_v1_0;

architecture arch_imp of TP_CMD_serializer_v1_0 is

  -- State machine
  type state is ( IDLE,
	              SHIFTING);
  signal sm_exec_state, old_state : state;

  signal rx_ready        : std_logic;
  signal TPEnable_int    : std_logic;
  signal bytebuf         : std_logic_vector(7 downto 0);
  signal shift_cnt       : integer range 0 to 7;
  signal debug_byte_cntr : integer range 0 to 65535;

begin
  S_AXIS_TREADY      <= rx_ready;
  TPEnable           <= TPEnable_int;
  -- transmit data MSB first
  TPData             <= bytebuf(7);
  tx_bytes_dbg_cntr  <= std_logic_vector( TO_UNSIGNED(debug_byte_cntr,16) );
  
  main_loop: process(S_AXIS_ACLK, S_AXIS_ARESETN)
  begin
    if (rising_edge (S_AXIS_ACLK)) then
      if(S_AXIS_ARESETN = '0') then
        rx_ready        <= '0';
        TPEnable_int    <= '1';
        bytebuf         <= (others => '0');
        shift_cnt       <= 0;
        debug_byte_cntr <= 0;
        sm_exec_state   <= IDLE;
        old_state       <= IDLE;
      else
        old_state <= sm_exec_state;
        
        case (sm_exec_state) is
          when IDLE =>
            if( S_AXIS_TVALID = '1') then
              rx_ready      <= '0';
              TPEnable_int  <= '0';
              bytebuf       <= S_AXIS_TDATA;
              shift_cnt     <= 0;
              if( old_state = IDLE ) then
                -- if we start shifting again after an interruption, 
                -- reset total number of transmitted bytes
                -- an interruption is found by two consecutive IDLE states,
                -- due to VALID being deasserted
                debug_byte_cntr <= 0;
              else
                debug_byte_cntr <= debug_byte_cntr;
              end if;
              sm_exec_state <= SHIFTING;
            else
              rx_ready      <= '1';
              if( reset_TPEnable = '1' ) then
                TPEnable_int  <= '1';
              else
                TPEnable_int  <= TPEnable_int;
              end if;
              bytebuf       <= (others => '0');
              shift_cnt     <= 0;
              debug_byte_cntr <= debug_byte_cntr;
              sm_exec_state <= IDLE;
            end if;
          when SHIFTING =>
            TPEnable_int  <= '0';
            -- transmit data MSB first
            bytebuf <= bytebuf( 6 downto 0 ) & '0';
            shift_cnt <= shift_cnt +1;
            if( shift_cnt = 6 ) then
              rx_ready <= '1';
              debug_byte_cntr <= debug_byte_cntr +1;
              sm_exec_state <= IDLE;
            else
              rx_ready <= '0';
              debug_byte_cntr <= debug_byte_cntr;
              sm_exec_state <= SHIFTING;
            end if;
            
          when others =>
            rx_ready        <= '0';
            TPEnable_int    <= TPEnable_int;
            bytebuf         <= bytebuf;
            shift_cnt       <= shift_cnt;
            debug_byte_cntr <= debug_byte_cntr;
            sm_exec_state   <= IDLE;

        end case;
      end if;  -- if not reset
    end if;  -- if clock edge
  end process main_loop;
  
  
end arch_imp;















--library ieee;
--use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;

--entity TP_CMD_serializer_v1_0 is
--  generic (
--    C_S00_AXIS_TDATA_WIDTH	: integer	:= 8
--  );
--  port (
--    reset_TPEnable      :  in std_logic;
--    TPEnable            : out std_logic;
--    TPData              : out std_logic;
--    tx_bytes_dbg_cntr   : out std_logic_vector(15 downto 0);
--    -- input 8-bit AXI Stream
--    s00_axis_aclk       :  in std_logic;
--    s00_axis_aresetn    :  in std_logic;
--    s00_axis_tready     : out std_logic;
--    s00_axis_tdata      :  in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
--    s00_axis_tstrb      :  in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
--    s00_axis_tlast      :  in std_logic;
--    s00_axis_tvalid     :  in std_logic
--  );
--end TP_CMD_serializer_v1_0;

--architecture arch_imp of TP_CMD_serializer_v1_0 is

--	-- component declaration
--	component TP_CMD_serializer_v1_0_S00_AXIS is
--      generic (
--        C_S_AXIS_TDATA_WIDTH	: integer	:= 8
--      );
--      port (
--        reset_TPEnable    :  in std_logic;
--        TPEnable          : out std_logic;
--        TPData            : out std_logic;
--        tx_bytes_dbg_cntr : out std_logic_vector(15 downto 0);
--        -- input 8-bit AXI Stream
--        S_AXIS_ACLK       :  in std_logic;
--        S_AXIS_ARESETN    :  in std_logic;
--        S_AXIS_TREADY     : out std_logic;
--        S_AXIS_TDATA      :  in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
--        S_AXIS_TSTRB      :  in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
--        S_AXIS_TLAST      :  in std_logic;
--        S_AXIS_TVALID     :  in std_logic
--      );
--	end component TP_CMD_serializer_v1_0_S00_AXIS;

--begin

---- Instantiation of Axi Bus Interface S00_AXIS
--TP_CMD_serializer_v1_0_S00_AXIS_inst : TP_CMD_serializer_v1_0_S00_AXIS
--	generic map (
--		C_S_AXIS_TDATA_WIDTH	=> C_S00_AXIS_TDATA_WIDTH
--	)
--	port map (
--        reset_TPEnable    => reset_TPEnable,
--        TPEnable          => TPEnable,
--        TPData            => TPData,
--        tx_bytes_dbg_cntr => tx_bytes_dbg_cntr,
--        --
--		S_AXIS_ACLK	      => s00_axis_aclk,
--		S_AXIS_ARESETN	  => s00_axis_aresetn,
--		S_AXIS_TREADY	  => s00_axis_tready,
--		S_AXIS_TDATA	  => s00_axis_tdata,
--		S_AXIS_TSTRB	  => s00_axis_tstrb,
--		S_AXIS_TLAST	  => s00_axis_tlast,
--		S_AXIS_TVALID	  => s00_axis_tvalid
--	);

--	-- Add user logic here

--	-- User logic ends

--end arch_imp;
