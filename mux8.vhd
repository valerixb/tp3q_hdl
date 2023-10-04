--
-- 8-bit wide multiplexer
--
-- latest rev may 25 2023
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

entity mux8 is
  Port(
    clk  : IN std_logic;
    rst  : IN std_logic;
    in0  : IN std_logic_vector(7 downto 0);
    in1  : IN std_logic_vector(7 downto 0);
    outb : OUT std_logic_vector(7 downto 0);
    sel  : IN std_logic
  );
end mux8;

architecture Behavioral of mux8 is

begin

main_process: process(clk, rst)
  begin
    if(rising_edge(clk)) then
      if(rst='1') then
        outb <= (others => '0');
      else
        if(sel = '0') then
          outb <= in0;
        else
          outb <= in1;
        end if;
      end if;
    end if;
  end process main_process;

end Behavioral;
