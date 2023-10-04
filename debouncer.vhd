----------------------------------------------------------------------------------
-- 
-- button debouncer
-- 
-- latest rev by valerix, jan 11 2023
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

entity debouncer is
    Generic (
            DEBOUNCE_CYCLES : integer := 16e6
            );
    Port ( clk     : in STD_LOGIC;
           reset_n : in STD_LOGIC;
           i       : in STD_LOGIC;
           o       : out STD_LOGIC;
           o_n     : out STD_LOGIC);
end debouncer;

architecture Behavioral of debouncer is

    signal o_debounced   : std_logic;
    signal debounce_cntr : integer := 0;

begin

    main_process : process (clk, reset_n)
        begin
        if reset_n = '0' then
            o_debounced   <= '0';
            debounce_cntr <= 0;
        elsif rising_edge(clk) then
            if( debounce_cntr /= 0 ) then
                debounce_cntr <= debounce_cntr -1;
                o_debounced <= o_debounced;
            elsif(i /= o_debounced) then
                debounce_cntr <= DEBOUNCE_CYCLES;
                o_debounced <= i;
            end if;
        end if;
    end process main_process;

    o <= o_debounced;
    o_n <= not o_debounced;
    
end Behavioral;
