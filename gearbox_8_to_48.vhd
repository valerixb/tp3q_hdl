--
-- 8 to 48 gearbox
-- buffer fills from LSB up = LSB is the oldest
-- 
-- no TREADY management, as the PHY is continuously producing data: 
-- use a FIFO after this gearbox
--
-- latest rev oct 19 2023
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

entity gearbox_8_to_48 is
  PORT (
    clk       :  in std_logic;
    reset     :  in std_logic;
    in_valid  :  in std_logic;
    datain    :  in std_logic_vector(7 downto 0);
    is_comma  :  in std_logic;
    dataout   : out std_logic_vector(47 downto 0);
    out_valid : out std_logic
  );
end gearbox_8_to_48;

architecture Behavioral of gearbox_8_to_48 is

  -- State machine                                             
  type state is ( W1, W2, W3, W4, W5, W6);
  signal  sm_exec_state : state := W1;                                                   

  signal dataout_buf   : std_logic_vector(47 downto 0);
  signal out_valid_buf : std_logic;


begin

  -- buffer outputs
  dataout   <= dataout_buf;
  out_valid <= out_valid_buf;
  
    -- main machine
  state_machine: process (clk, reset)
    begin
      if(rising_edge(clk)) then
        if(reset='1') then
          dataout_buf   <= (others=>'0');
          out_valid_buf <= '0';
          sm_exec_state <= W1;

        elsif(is_comma='1') then
          -- reset gearbox counter when a comma character is detected
          dataout_buf   <= dataout_buf;
          out_valid_buf <= '0';
          sm_exec_state <= W1;
        
        elsif(in_valid='1') then
          case(sm_exec_state) is
          
            when W1 =>
              dataout_buf(  7 downto  0) <= datain;
              out_valid_buf <= '0';
              sm_exec_state <= W2;
              
            when W2 =>
              dataout_buf( 15 downto  8) <= datain;
              out_valid_buf <= '0';
              sm_exec_state <= W3;
              
            when W3 =>
              dataout_buf( 23 downto 16) <= datain;
              out_valid_buf <= '0';
              sm_exec_state <= W4;
              
            when W4 =>
              dataout_buf( 31 downto 24) <= datain;
              out_valid_buf <= '0';
              sm_exec_state <= W5;
              
            when W5 =>
              dataout_buf( 39 downto 32) <= datain;
              out_valid_buf <= '0';
              sm_exec_state <= W6;
              
            when W6 =>
              dataout_buf( 47 downto 40) <= datain;
              out_valid_buf <= '1';
              sm_exec_state <= W1;
              
            when others =>
              dataout_buf   <= dataout_buf;
              out_valid_buf <= '0';
              sm_exec_state <= W1;

          end case;
        else
          -- inut data NOT ready
          dataout_buf   <= dataout_buf;
          out_valid_buf <= '0';
          sm_exec_state <= sm_exec_state;
          
        end if;  -- if not reset
      end if;  -- if clk rising edge
    end process state_machine;



end Behavioral;
