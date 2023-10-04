--
-- RIU controller for HSSIO RX
--
-- It reads the calibrated delay value and loads it into N channel
-- for 4x oversampling scheme made by two 2x oversampling in quadrature
-- 
-- mostly taken from Xilinx xapp1330 source ClkRst_Lib/RIU_StateMach.vhd
--
-- latest rev sept 20 2023
--


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RIU_ctrlr is
  Port( 
    clk                     :  in std_logic;
    reset                   :  in std_logic;
    dly_rdy                 :  in std_logic;
    rst_seq_done            :  in std_logic;
    pll0_locked             :  in std_logic;
    RIU_configured          : out std_logic;
    ------------
    N_delay_value           : out std_logic_vector(8 downto 0);
    delay_load              : out std_logic;
    vtc_enable              : out std_logic;
    riu_rd_data             :  in std_logic_vector(15 downto 0);
    riu_valid               :  in std_logic;
    riu_nibble_sel          : out std_logic_vector(1 downto 0);
    riu_addr                : out std_logic_vector(5 downto 0);
    riu_wr_data             : out std_logic_vector(15 downto 0); 
    riu_wr_en               : out std_logic
  );
end RIU_ctrlr;

architecture Behavioral of RIU_ctrlr is

--constant RIU_NIBBLE : std_logic_vector(1 downto 0) := "10";
constant RIU_NIBBLE : std_logic_vector(1 downto 0) := "01";
signal IntCtrl_State      : integer range 0 to 511 := 0;
signal int_RIU_configured : std_logic;

begin

  RIU_configured <= int_RIU_configured;
  
  -- the state machine has a "others" default case that increments the
  -- state variable, thus allowing for easy sequencing and wait states 
  
  ctrl_machine: process(clk, reset)
    begin

      if(rising_edge(clk)) then
        if(reset='1') then
          IntCtrl_State  <= 0;
          N_delay_value  <= (others=>'0');
          delay_load     <= '0';
          vtc_enable     <= '1';
          riu_nibble_sel <= "00";
          riu_addr       <= (others=>'0');
          riu_wr_data    <= (others=>'0'); 
          riu_wr_en      <= '0';
          int_RIU_configured <= '0';
        else
          case(IntCtrl_State) is
          
            when  0 =>
              int_RIU_configured <= '0';
              if( (rst_seq_done='1') and (dly_rdy='1') and (pll0_locked='1') ) then
                vtc_enable     <= '0';
                IntCtrl_State  <= IntCtrl_State + 1;
              end if;
            
            -- read calibrated delay
            -- mostly undocumented access to internal Xilinx debug data;
            -- just do like this and you'll get what you want
            when  1 =>
              riu_nibble_sel <= RIU_NIBBLE;             -- select upper nibble
              riu_addr       <= "111000";         -- RIU ADDR 0x38
              riu_wr_data    <= X"000C";          -- select debug value of calibrated delay
              riu_wr_en      <= '1';
              IntCtrl_State  <= IntCtrl_State + 1;
            
            -- wait 4 cycles before reading the value
              
            when  5 =>
              riu_nibble_sel <= RIU_NIBBLE;             -- select upper nibble
              riu_addr       <= "111001";         -- RIU ADDR 0x39
              riu_wr_data    <= X"0000";          -- 
              riu_wr_en      <= '0';
              IntCtrl_State  <= IntCtrl_State + 1;

            when  6 =>
              riu_nibble_sel <= RIU_NIBBLE;             -- select upper nibble
              riu_addr       <= "111001";         -- RIU ADDR 0x39
              riu_wr_data    <= X"0000";          -- 
              riu_wr_en      <= '0';
              -- wait until we get a non-zero value (it should be ready by now)
              if( riu_rd_data /= X"0000" ) then
                -- must divide by 4 to get quadrature delay
                N_delay_value <= '0' & riu_rd_data(9 downto 2);
                IntCtrl_State  <= IntCtrl_State + 1;
              end if;

            -- wait 2 cycles then reset all bitslices (for some reason)
            when  8 =>
              riu_nibble_sel <= RIU_NIBBLE;             -- select upper nibble
              riu_addr       <= "000101";         -- RIU ADDR 0x05
              riu_wr_data    <= X"007F";          -- reset bitslices
              riu_wr_en      <= '1';              -- it is deasserted nex cycle by "others" case
              IntCtrl_State  <= IntCtrl_State + 1;
              
            -- wait 3 cycles then release reset
            when 11 =>
              riu_nibble_sel <= RIU_NIBBLE;             -- select upper nibble
              riu_addr       <= "000101";         -- RIU ADDR 0x05
              riu_wr_data    <= X"0000";          -- deassert reset
              riu_wr_en      <= '1';              -- it is deasserted nex cycle by "others" case
              IntCtrl_State  <= IntCtrl_State + 1;

            -- wait 7 cycles then write delay value into N channel
            when 18 =>
              riu_nibble_sel <= RIU_NIBBLE;             -- select upper nibble
              riu_addr       <= "000000";         -- 
              riu_wr_data    <= X"0000";          -- 
              riu_wr_en      <= '0';
              delay_load     <= '1';
              IntCtrl_State  <= IntCtrl_State + 1;

            -- deassert "delay_load" after 1 clock cycle
            when 19 =>
              riu_nibble_sel <= RIU_NIBBLE;             -- select upper nibble
              riu_addr       <= "000000";         -- 
              riu_wr_data    <= X"0000";          -- 
              riu_wr_en      <= '0';
              delay_load     <= '0';
              IntCtrl_State  <= IntCtrl_State + 1;

            -- wait 131 cycles (for some reason),
            -- then deassert fabric receiver reset 
            when 150 =>
              int_RIU_configured <= '1';
              IntCtrl_State  <= IntCtrl_State + 1;
            
            -- now STOP the machine
            when 151 =>
              riu_nibble_sel <= "00";
              riu_addr       <= (others=>'0');
              riu_wr_data    <= (others=>'0'); 
              riu_wr_en      <= '0';
              IntCtrl_State  <= 151;
              
            
            -- default: keep incrementing state variable
                        
            when others =>
              riu_nibble_sel <= "00";
              riu_addr       <= (others=>'0');
              riu_wr_data    <= (others=>'0'); 
              riu_wr_en      <= '0';
              IntCtrl_State  <= IntCtrl_State + 1;
              
          end case;
        end if; -- if not reset
      end if; -- if clock edge
    end process ctrl_machine;

end Behavioral;
