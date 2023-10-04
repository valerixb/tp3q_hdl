--
-- clock prescaler
--
-- latest rev sept 4 2023
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

entity clkscaler is
  Generic(
    SCALING_FACTOR : natural := 156250000
    );
  Port(
    clk         :  in std_logic;
    res_n       :  in std_logic;
    pulse_out   : out std_logic
    );
end clkscaler;

architecture Behavioral of clkscaler is

    constant SC_FACT_DIV2 : natural := SCALING_FACTOR/2;
    signal intcount : unsigned(31 downto 0);
    signal int_pout : std_logic;

begin

  main_proc: process(clk, res_n)
    begin
      if rising_edge(clk) then
        if(res_n='0') then
          intcount <= to_unsigned(1,32);
          int_pout <= '0';
        else
          if(intcount=(to_unsigned(SCALING_FACTOR,32))) then
            intcount <= to_unsigned(1,32);
            int_pout <= '1';
          elsif(intcount=(to_unsigned(SC_FACT_DIV2,32))) then
            intcount <= intcount+1;
            int_pout <= '0';
          else
            intcount <= intcount+1;
            int_pout <= int_pout;
          end if;
        end if;  -- if not reset
      end if;  -- if rising edge
    end process main_proc;
  
  -- in case scaling factor = 1, just send thru the incoming clock
  pulse_out <= clk when (SCALING_FACTOR=1) else int_pout; 
    
end Behavioral;
