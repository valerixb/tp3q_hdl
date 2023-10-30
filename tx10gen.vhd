--
-- 10-bit stream generator for HSSIO TX test interface
-- user can choose to transmit a packet or 
-- a pseudorandom bit sequence
--
-- latest rev oct 30 2023
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tx10gen is
  --generic (
  --);
  port (
    clk           :  in std_logic;
    reset         :  in std_logic;
    ready         :  in std_logic;
    prbs_pckt_sel :  in std_logic;
    error_inj     :  in std_logic_vector(9 downto 0);
    out10         : out std_logic_vector(9 downto 0)
  );
end tx10gen;

architecture implementation of tx10gen is
  
  constant NUMBER_OF_OUTPUT_WORDS : integer := 7;
  type pkt_arr is array (0 to NUMBER_OF_OUTPUT_WORDS-1) of 
    std_logic_vector(9 downto 0);
  
  signal rd_ptr      : natural := 0;
  signal out_buf     : std_logic_vector(9 downto 0) := (others=>'0');
-- RESET is synchronous: I don't need a synchronizer
--  signal reset_sync  : std_logic;
--  signal reset_pipe  : std_logic_vector(2 downto 0) := "000";
--  attribute ASYNC_REG : string;
--    attribute ASYNC_REG of reset_pipe : signal is "TRUE";
  signal int_prbs_res : std_logic;
  signal int_prbs_out : std_logic_vector(9 downto 0);
  
  -- test packet #1
  constant pkt_to_send : pkt_arr :=
    (
    "0011111010",  -- K28.5- comma character for alignment
    "0101100100",  -- 0x1A
    "1101001001",  -- 0x2B
    "0011101001",  -- 0x3C
    "1011000101",  -- 0x4D
    "0111100101",  -- 0x5E
    "1010001100"   -- 0x6F
    );

  -- component prbs_any from Xilinx XAPP884
  component PRBS_ANY
    generic 
       (      
       CHK_MODE    : boolean := false; 
       INV_PATTERN : boolean := false;
       POLY_LENGHT : natural range 2 to 63 := 7 ;
       POLY_TAP    : natural range 1 to 62 := 6 ;
       NBITS       : natural range 1 to 512 := 4
       );
    port
      (
      RST          : in  std_logic;
      CLK          : in  std_logic;
      DATA_IN      : in  std_logic_vector(NBITS - 1 downto 0); -- inject error/data to be checked
      EN           : in  std_logic;                            -- enable/pause pattern generation
      DATA_OUT     : out std_logic_vector(NBITS - 1 downto 0):= (others => '0')  -- generated prbs pattern/errors found
      );
  end component;



begin
    
  -- buffer output
  out10 <= out_buf;

  -- PRBS generator instance
  PRBS_gen : PRBS_ANY
  generic map
     (      
     CHK_MODE    => false, 
     INV_PATTERN => true,
     POLY_LENGHT =>  7,
     POLY_TAP    =>  6,
     NBITS       => 10
     )
  port map
    (
    RST          => int_prbs_res,
    CLK          => clk,
    DATA_IN      => error_inj,
    EN           => ready,
    DATA_OUT     => int_prbs_out
    );

--  -- synchronize ext async reset to local clk
--  sync_reset_process : process (clk, reset)
--    begin
--      if rising_edge(clk) then
--        reset_pipe <= reset_pipe(1 downto 0) & reset;
--        reset_sync <= reset_pipe(2);
--      end if;
--    end process sync_reset_process;
    
    -- keep sending packet forever 
--  main_machine: process(clk, reset_sync)                                                                        
  main_machine: process(clk, reset)                                                                        
    begin                                                                                       
      if(rising_edge(clk)) then
--        if(reset_sync = '1') then
        if(reset = '1') then
          rd_ptr  <= 0;
          int_prbs_res <= '1';
          out_buf <= (others=>'0');
          --out_buf <= pkt_to_send(0);
        else
          if( prbs_pckt_sel = '1' ) then
            -- output PRBS
            int_prbs_res <= '0';
            out_buf      <= int_prbs_out;
            -- PRBS enable is alrady connected to "ready"
          else
            int_prbs_res <= '1';  -- keep PRBS in reset
            -- output packet
            out_buf <= pkt_to_send(rd_ptr);
            if(ready = '1') then
              if( rd_ptr < (NUMBER_OF_OUTPUT_WORDS-1)) then
                rd_ptr <= rd_ptr+1;
              else
                rd_ptr <= 0;
              end if;
            else
              rd_ptr <= rd_ptr;
            end if;  -- if receiver ready
          end if;  -- select PRBS or packet output

        end if; -- if not reset
      end if; -- if clock edge
    end process main_machine;
    
end implementation;
  