--
-- 10 to 8 gearbox
-- common clock
-- 40 bit circular buffer
-- state machine operating on 5-state cycle
-- buffer written in 4 cycles + 1 idle (READY deassert)
-- buffer read in 5 cycles
-- remember to write before you read! (duh)
-- after reading, set bits to zero; this takes care of
-- potentially incomplete packets
-- No VALID handshake, as the PHY has none
-- READY handshake towards the traffic generator
--
-- latest rev may 22 2023
--


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity gearbox_10_to_8 is
  PORT (
    clk      : in std_logic;
    reset    : in std_logic;
    ready    : out std_logic;
    datain   : in std_logic_vector(9 downto 0);
    dataout  : out std_logic_vector(7 downto 0)
  );
end gearbox_10_to_8;

architecture Behavioral of gearbox_10_to_8 is

  -- State machine                                             
  type state is ( W1_R5, W2_R1, W3_R2, W4_R3, WNONE_R4);
  signal  sm_exec_state : state := W1_R5;                                                   

  signal circbuf       : std_logic_vector(39 downto 0);
  signal circbuf_valid : std_logic;
  signal dataout_buf   : std_logic_vector(7 downto 0);
  signal ready_buf     : std_logic := '1';
-- RESET is synchronous: I don't need a synchronizer
--  signal reset_sync    : std_logic;
--  signal reset_pipe    : std_logic_vector(2 downto 0) := "000";
--  attribute ASYNC_REG : string;
--    attribute ASYNC_REG of reset_pipe : signal is "TRUE";


begin

  -- buffer outputs
  dataout <= dataout_buf;
  ready   <= ready_buf;
  
--  -- synchronize ext async reset to local clk
--  sync_reset_process : process (clk, reset)
--    begin
--      if rising_edge(clk) then
--        reset_pipe <= reset_pipe(1 downto 0) & reset;
--        reset_sync <= reset_pipe(2);
--      end if;
--    end process sync_reset_process;

  -- main machine
--  state_machine: process (clk, reset_sync)
  state_machine: process (clk, reset)
    begin
      if(rising_edge(clk)) then
--        if(reset_sync='1') then
        if(reset='1') then
          circbuf       <= (others=>'0');
          dataout_buf   <= (others=>'0');
          ready_buf     <= '0';
          circbuf_valid <= '0';
          --sm_exec_state <= W1_R5;
          -- because ready = 0 during reset, like in state W3_R2, 
          -- so we resume from the next sate in the machine cycle
          -- (not very important, just for sake of order)
          sm_exec_state <= W4_R3;

        else
          case(sm_exec_state) is
          
            when W1_R5 =>
              circbuf( 9 downto  0) <= datain;
              -- data in circular buffer is valid only after first write to W1 position
              circbuf_valid <= '1';
              if( circbuf_valid='1' ) then
                dataout_buf <= circbuf(39 downto 32);
              else
                dataout_buf <= (others => '0');
              end if;
              circbuf(39 downto 32) <= (others => '0');
              ready_buf             <= '1';
              sm_exec_state         <= W2_R1;
              
            when W2_R1 =>
              circbuf(19 downto 10) <= datain;
              circbuf_valid <= circbuf_valid;
              if( circbuf_valid='1' ) then
                dataout_buf <= circbuf( 7 downto  0);
              else
                dataout_buf <= (others => '0');
              end if;
              circbuf( 7 downto  0) <= (others => '0');
              ready_buf             <= '1';
              sm_exec_state         <= W3_R2;
              
            when W3_R2 =>
              circbuf(29 downto 20) <= datain;
              circbuf_valid <= circbuf_valid;
              if( circbuf_valid='1' ) then
                dataout_buf <= circbuf(15 downto  8);
              else
                dataout_buf <= (others => '0');
              end if;
              circbuf(15 downto  8) <= (others => '0');
              ready_buf             <= '0';  -- next state+2 is a input wait state
              sm_exec_state         <= W4_R3;
              
            when W4_R3 =>
              circbuf(39 downto 30) <= datain;
              circbuf_valid <= circbuf_valid;
              if( circbuf_valid='1' ) then
                dataout_buf <= circbuf(23 downto 16);
              else
                dataout_buf <= (others => '0');
              end if;
              circbuf(23 downto 16) <= (others => '0');
              ready_buf             <= '1';
              sm_exec_state         <= WNONE_R4;
              
            when WNONE_R4 =>
              --circbuf(39 downto 30) <= datain;
              circbuf_valid <= circbuf_valid;
              if( circbuf_valid='1' ) then
                dataout_buf <= circbuf(31 downto 24);
              else
                dataout_buf <= (others => '0');
              end if;
              circbuf(31 downto 24) <= (others => '0');
              ready_buf             <= '1';
              sm_exec_state         <= W1_R5;
              
            when others =>
              --circbuf       <= (others=>'0');
              --dataout_buf   <= (others=>'0');
              ready_buf     <= '1';
              circbuf_valid <= '0';
              sm_exec_state <= W1_R5;

          end case;
        end if;  -- if not reset
      end if;  -- if clk rising edge
    end process state_machine;


end Behavioral;
