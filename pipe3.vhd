----------------------------------------------------------------------------------
--  
-- 3-stage flip flop for clock domain crossing or external input 
-- 
-- latest rev: sept 30 2021
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pipe3 is
    Port ( clk : in STD_LOGIC;
           reset_n : in STD_LOGIC;
           i : in STD_LOGIC;
           o : out STD_LOGIC);
end pipe3;

architecture Behavioral of pipe3 is

    signal pipe : STD_LOGIC_VECTOR( 2 downto 0);
    attribute ASYNC_REG : string;
      attribute ASYNC_REG of pipe : signal is "TRUE";

begin

    main_process : process (clk, reset_n)
        begin
        if reset_n = '0' then
            pipe <= (others => '0');
            o    <= '0';
        elsif rising_edge(clk) then
            pipe <= pipe(1 downto 0) & i;
            o    <= pipe(2);
        end if;
    end process main_process;

end Behavioral;
