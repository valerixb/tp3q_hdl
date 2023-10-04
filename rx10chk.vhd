--
-- 10-bit PRBS checker 
--
-- latest rev jun 9 2023
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity rx10chk is
  --generic (
  --);
  port (
    clk            :  in std_logic;
    reset          :  in std_logic;
    valid          :  in std_logic;
    in10           :  in std_logic_vector(9 downto 0);
    bit_cnt_noerr  : out std_logic_vector(63 downto 0);
    bit_err_sticky : out std_logic;
    bit_err        : out std_logic;
    bit_err_reset  :  in std_logic
  );
end rx10chk;

architecture Behavioral of rx10chk is

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

  signal int_bit_err_vec    : std_logic_vector(9 downto 0);
  signal int_bit_err        : std_logic;
  signal int_bit_cnt_noerr  : unsigned(63 downto 0);
  signal int_bit_err_sticky : std_logic;
  signal valid_dly          : std_logic;


begin

  -- PRBS checker instance
  PRBS_gen : PRBS_ANY
  generic map
     (      
     CHK_MODE    => true, 
     INV_PATTERN => true,
     POLY_LENGHT =>  7,
     POLY_TAP    =>  6,
     NBITS       => 10
     )
  port map
    (
    RST          => reset,
    CLK          => clk,
    DATA_IN      => in10,
    EN           => valid,
    DATA_OUT     => int_bit_err_vec
    );

  int_bit_err    <= or_reduce(int_bit_err_vec);
  bit_cnt_noerr  <= std_logic_vector(int_bit_cnt_noerr);
  bit_err_sticky <= int_bit_err_sticky;
  
  delay_pipes: process(clk, reset)
    begin
      if(rising_edge(clk)) then
        if(reset = '1') then
          valid_dly <= '0';
        else
          valid_dly <= valid;
        end if;
      end if;
    end process delay_pipes;
  
  main_machine: process(clk, reset, bit_err_reset)
    begin
      if(rising_edge(clk)) then
        if(reset = '1' or bit_err_reset='1') then
          int_bit_cnt_noerr  <= (others=>'0');
          int_bit_err_sticky <= '0';
          bit_err <= '0';
        else
          if(int_bit_err='1' and valid_dly='1') then
            -- there was a bit error
            int_bit_err_sticky <= '1';
            bit_err <= '1';
            int_bit_cnt_noerr  <= int_bit_cnt_noerr;
          elsif(int_bit_err_sticky='0') then
            -- no bit error: increment counter of error-free words
            int_bit_err_sticky <= int_bit_err_sticky;
            bit_err <= '0';
            int_bit_cnt_noerr  <= int_bit_cnt_noerr+1;
          else
            -- there was an error before (error_sticky is 1)
            bit_err <= '0';            
            int_bit_err_sticky <= int_bit_err_sticky;
            int_bit_cnt_noerr  <= int_bit_cnt_noerr;
          end if;
        end if; -- if not reset
      end if; -- if clock edge
    end process main_machine;


end Behavioral;
