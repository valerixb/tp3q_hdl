--
-- a wrapper for the 8b10b decoder by Ken Boyette / OpenCores.org
-- It adds input/output registers and TVALID
-- note that TREADY is not needed because we cannot put backpressure
-- onto the HSSIO RX, which continuously samples the lines, no matter what
--
-- latest rev oct 4 2023
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

entity decoder_10b8b is
  Port(
    clk            :  in std_logic;
    reset          :  in std_logic;
    in10           :  in std_logic_vector(9 downto 0);
    in10_valid     :  in std_logic;
    out8_valid     : out std_logic;
    out8           : out std_logic_vector(7 downto 0);
    is_comma       : out std_logic
    );
end decoder_10b8b;

architecture Behavioral of decoder_10b8b is

  component dec_8b10b
    port(
      AI, BI, CI, DI, EI, II : in std_logic ;
      FI, GI, HI, JI : in std_logic ; -- Encoded input (LS..MS)		
      KO : out std_logic ;	-- Control (K) character indicator (AH)
      HO, GO, FO, EO, DO, CO, BO, AO : out std_logic; 	-- Decoded out (MS..LS)
      is_comma : out std_logic
      );
  end component;

  signal in10reg : std_logic_vector(9 downto 0);
  signal out8i, out8reg : std_logic_vector(7 downto 0);
  signal inpvalid_dly, outvalid, ko, is_comma_int : std_logic;

begin
  out8       <= out8reg;
  out8_valid <= outvalid;
  
  decoder_inst: dec_8b10b
    port map(
      AI => in10reg(9),
      BI => in10reg(8),
      CI => in10reg(7),
      DI => in10reg(6),
      EI => in10reg(5),
      II => in10reg(4),
      FI => in10reg(3),
      GI => in10reg(2),
      HI => in10reg(1),
      JI => in10reg(0),
      KO => ko,
      HO => out8i(7),
      GO => out8i(6),
      FO => out8i(5),
      EO => out8i(4),
      DO => out8i(3),
      CO => out8i(2),
      BO => out8i(1),
      AO => out8i(0),
      is_comma => is_comma_int
      );

latch_in: process(clk, reset)
  begin
    if(rising_edge(clk)) then
      if(reset='1') then
        in10reg <= (others=>'0');
      else
        inpvalid_dly<=in10_valid;
        if(in10_valid='1') then
          in10reg<=in10;
        end if;
      end if;
    end if;
  end process latch_in;

latch_out: process(clk, reset)
  begin
    if(rising_edge(clk)) then
      if(reset='1') then
        out8reg  <= (others=>'0');
        is_comma <= '0';
        outvalid <= '0';
      else
        if((inpvalid_dly='1')) then
          if(ko='0') then
            -- it's a regular character, Dxx.x
            out8reg  <= out8i;
            outvalid <= '1';
            is_comma <= '0';
          else
            -- it's a control character, Kxx.x
            out8reg  <= out8i; -- don't care
            outvalid <= '0';
            is_comma <= is_comma_int;            
          end if;
        else
          out8reg  <= out8i; -- don't care
          outvalid <= '0';
          is_comma <= '0';
        end if; -- if input was valid
      end if;  -- if not reset
    end if;  -- if clock edge
  end process latch_out;



end Behavioral;
