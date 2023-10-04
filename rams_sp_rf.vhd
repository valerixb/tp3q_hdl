-- Single-Port Block RAM Read-First Mode
-- rams_sp_rf.vhd
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rams_sp_rf is
  generic(
  DATA_WIDTH    : integer	:= 64;
  ADDR_WIDTH    : integer   := 11;
  -- I put also actual length required for the buffer, as it may be less than 2**ADDR_WIDTH and I save some BRAM
  BUFFER_LENGTH : integer   := 1127
  );
 port(
  clk   : in  std_logic;
  we    : in  std_logic;
  ready :  in std_logic;
  en    : in  std_logic;
  addr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
  di    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
  do    : out std_logic_vector(DATA_WIDTH-1 downto 0)
 );
end rams_sp_rf;

architecture syn of rams_sp_rf is

  function min (a, b : integer) return integer is                  
      variable c : integer;
    begin
      if (a>b) then
        c := b;
      else
        c := a;
      end if;
      return(c);
    end;   
  
  type ram_type is array (min(BUFFER_LENGTH,2**ADDR_WIDTH)-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal RAM    : ram_type;
  signal outbuf : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  
begin
  do <= outbuf;
 
  process(clk)
  begin
    if clk'event and clk = '1' then
      if en = '1' then
        if we = '1' then
          RAM(to_integer(unsigned(addr))) <= di;
        end if;
        
        if( ready = '1' ) then
          outbuf <= RAM(to_integer(unsigned(addr)));
        else
          outbuf <= outbuf;
        end if;
      else
        outbuf <= (others => '0');
      end if;  -- if enabled
    end if;  -- if CLK edge
  end process;

end syn;
