----------------------------------------------------------------------------------
-- testbench for Timepix RX channel 
-- 8b10b decoder + 8 to 48 gearbox
-- 
-- latest rev by valerix, oct 19 2023
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
-- library UNISIM;
-- use UNISIM.VComponents.all;

entity tb_8b10bdec48 is
--  Port ( );
end tb_8b10bdec48;

architecture Behavioral of tb_8b10bdec48 is
  
  component decoder_10b8b
    Port(
      clk            :  in std_logic;
      reset          :  in std_logic;
      in10           :  in std_logic_vector(9 downto 0);
      in10_valid     :  in std_logic;
      in10_aligned   :  in std_logic;
      out8_valid     : out std_logic;
      out8           : out std_logic_vector(7 downto 0);
      is_comma       : out std_logic
      );
  end component;

  component gearbox_8_to_48
    Port(
      clk       :  in std_logic;
      reset     :  in std_logic;
      in_valid  :  in std_logic;
      datain    :  in std_logic_vector(7 downto 0);
      is_comma  :  in std_logic;
      dataout   : out std_logic_vector(47 downto 0);
      out_valid : out std_logic
      );
  end component;
    

  constant clock_period: time := 6 ns;
  signal stop_the_clock: boolean;

  signal aclk     : std_logic;
  signal areset   : std_logic;
  --
  signal word10     : std_logic_vector(9 downto 0);
  signal valid10    : std_logic;
  signal word8      : std_logic_vector(7 downto 0);
  signal valid8     : std_logic;
  signal word48     : std_logic_vector(47 downto 0);
  signal valid48    : std_logic;
  signal is_comma_i : std_logic;
  signal aligned    : std_logic;

begin

  decoder_inst: component decoder_10b8b
  port map
    (
    clk          => aclk,
    reset        => areset,
    in10         => word10,
    in10_valid   => valid10,
    in10_aligned => aligned,
    out8_valid   => valid8,
    out8         => word8,
    is_comma     => is_comma_i
    );

  gear_8_48: component gearbox_8_to_48
  port map
    (
    clk       => aclk,
    reset     => areset,
    in_valid  => valid8,
    datain    => word8,
    is_comma  => is_comma_i,
    dataout   => word48,
    out_valid => valid48
    );


  stimulus: process
  begin

    areset         <= '1';
    valid10        <= '0';
    aligned        <= '0';

    wait for clock_period*10;
    areset <= '0';
    wait for clock_period*10;

    -- change states on falling edge of clock, to be ready for next rising edge
    -- not necessary because I start the clock LOW
    --wait for clock_period/2;
    
    -- Put test bench stimuli here
    valid10 <= '1';
    word10 <= "1010101010";
    wait for clock_period;
    word10 <= "1100110011";
    wait for clock_period;
    word10 <= "1111001101";
    wait for clock_period;
    aligned <= '1';

    word10 <= "1011000101"; -- - 0x4D -
    wait for clock_period;
    word10 <= "0111100101"; -- - 0x5E +
    wait for clock_period;
    word10 <= "1010001100"; -- + 0x6F -
    wait for clock_period;
    word10 <= "0101101011"; -- - 0x1A +
    wait for clock_period;
    word10 <= "1101001001"; -- + 0x2B +
    wait for clock_period;
    word10 <= "0011101001"; -- + 0x3C +
    wait for clock_period;
    word10 <= "1011000101"; -- + 0x4D +
    wait for clock_period;
    word10 <= "1000010101"; -- + 0x5E -
    wait for clock_period;
    word10 <= "0101110011"; -- - 0x6F +
    wait for clock_period;
    word10 <= "0101100100"; -- + 0x1A -
    wait for clock_period;
    word10 <= "1101001001"; -- - 0x2B -
    wait for clock_period;
    word10 <= "0011101001"; -- - 0x3C -
    wait for clock_period;
    word10 <= "1011000101"; -- - 0x4D -
    wait for clock_period;
    word10 <= "0111100101"; -- - 0x5E +
    wait for clock_period;
    word10 <= "1010001100"; -- + 0x6F -
    wait for clock_period;
    word10 <= "0011111010"; -- - K28.5+
    wait for clock_period;
    word10 <= "0101100100"; -- + 0x1A -
    wait for clock_period;
    word10 <= "1101001001"; -- - 0x2B -
    wait for clock_period;
    word10 <= "0011101001"; -- - 0x3C -
    wait for clock_period;
    word10 <= "1011000101"; -- - 0x4D -
    wait for clock_period;
    word10 <= "0111100101"; -- - 0x5E +
    wait for clock_period;
    word10 <= "1010001100"; -- + 0x6F -
    wait for clock_period;
    word10 <= "0101101011"; -- - 0x1A +
    wait for clock_period;
    word10 <= "1101001001"; -- + 0x2B +
    wait for clock_period;
    word10 <= "0011101001"; -- + 0x3C +
    wait for clock_period;
    word10 <= "1011000101"; -- + 0x4D +
    wait for clock_period;
    word10 <= "1000010101"; -- + 0x5E -
    wait for clock_period;
    word10 <= "0101110011"; -- - 0x6F +
    wait for clock_period;
    word10 <= "0101100100"; -- + 0x1A -
    wait for clock_period;
    word10 <= "1101001001"; -- - 0x2B -
    wait for clock_period;
    word10 <= "0011101001"; -- - 0x3C -
    wait for clock_period;
    word10 <= "1011000101"; -- - 0x4D -
    wait for clock_period;
    word10 <= "0111100101"; -- - 0x5E +
    wait for clock_period;
    word10 <= "1010001100"; -- + 0x6F -
    wait for clock_period;
    word10 <= "0011111010"; -- - K28.5+
    wait for clock_period;
    word10 <= "1100000101"; -- + K28.5-
    wait for clock_period;
    word10 <= "0011111010"; -- - K28.5+
    wait for clock_period;
    word10 <= "1100000101"; -- + K28.5-
    wait for clock_period;
    word10 <= "0011111010"; -- - K28.5+
    wait for clock_period;
    word10 <= "0101100100"; -- + 0x1A -
    wait for clock_period;
    word10 <= "1101001001"; -- - 0x2B -
    wait for clock_period;
    word10 <= "0011101001"; -- - 0x3C -
    wait for clock_period;
    word10 <= "1011000101"; -- - 0x4D -
    wait for clock_period;
    word10 <= "0111100101"; -- - 0x5E +
    wait for clock_period;
    word10 <= "1010001100"; -- + 0x6F -
    wait for clock_period;
    word10 <= "0101101011"; -- - 0x1A +
    wait for clock_period;
    word10 <= "1101001001"; -- + 0x2B +
    wait for clock_period;
    word10 <= "0011101001"; -- + 0x3C +
    wait for clock_period;
    word10 <= "1011000101"; -- + 0x4D +
    wait for clock_period;
    word10 <= "1000010101"; -- + 0x5E -
    wait for clock_period;
    word10 <= "0101110011"; -- - 0x6F +
    wait for clock_period;
    word10 <= "0101100100"; -- + 0x1A -
    wait for clock_period;
    word10 <= "1101001001"; -- - 0x2B -
    wait for clock_period;
    word10 <= "0011101001"; -- - 0x3C -
    wait for clock_period;
    word10 <= "1011000101"; -- - 0x4D -
    wait for clock_period;
    word10 <= "0111100101"; -- - 0x5E +
    wait for clock_period;
    word10 <= "1010001100"; -- + 0x6F -
    wait for clock_period;
    word10 <= "0101101011"; -- - 0x1A +
    wait for clock_period;
    word10 <= "1101001001"; -- + 0x2B +
    wait for clock_period;
    word10 <= "0011101001"; -- + 0x3C +
    wait for clock_period;
    word10 <= "1011000101"; -- + 0x4D +
    wait for clock_period;
    word10 <= "1000010101"; -- + 0x5E -
    wait for clock_period;
    word10 <= "0101110011"; -- - 0x6F +
    wait for clock_period;
    word10 <= "0101100100"; -- + 0x1A -
    wait for clock_period;
    word10 <= "1101001001"; -- - 0x2B -
    wait for clock_period;
    word10 <= "0011101001"; -- - 0x3C -
    wait for clock_period;
    word10 <= "1011000101"; -- - 0x4D -
    wait for clock_period;
    word10 <= "0111100101"; -- - 0x5E +
    wait for clock_period;
    word10 <= "1010001100"; -- + 0x6F -
    wait for clock_period;
    word10 <= "0101101011"; -- - 0x1A +
    wait for clock_period;
    word10 <= "1101001001"; -- + 0x2B +
    wait for clock_period;
    word10 <= "0011101001"; -- + 0x3C +
    wait for clock_period;
    word10 <= "1011000101"; -- + 0x4D +
    wait for clock_period;
    word10 <= "1000010101"; -- + 0x5E -
    wait for clock_period;
    word10 <= "0101110011"; -- - 0x6F +
    wait for clock_period;
    word10 <= "0101100100"; -- + 0x1A -
    wait for clock_period;
    word10 <= "1101001001"; -- - 0x2B -
    wait for clock_period;
    word10 <= "0011101001"; -- - 0x3C -
    wait for clock_period;
    word10 <= "1011000101"; -- - 0x4D -
    wait for clock_period;
    word10 <= "0111100101"; -- - 0x5E +
    wait for clock_period;
    word10 <= "1010001100"; -- + 0x6F -
    wait for clock_period;
    word10 <= "0101101011"; -- - 0x1A +
    wait for clock_period;
    word10 <= "1101001001"; -- + 0x2B +
    wait for clock_period;
    word10 <= "0011101001"; -- + 0x3C +
    wait for clock_period;
    word10 <= "1011000101"; -- + 0x4D +
    wait for clock_period;
    word10 <= "1000010101"; -- + 0x5E -
    wait for clock_period;
    word10 <= "0101110011"; -- - 0x6F +
    wait for clock_period;
    word10 <= "1100000101"; -- + K28.5-
    wait for clock_period;
    word10 <= "0101101011"; -- - 0x1A +
    wait for clock_period;
    word10 <= "1101001001"; -- + 0x2B +
    wait for clock_period;
    word10 <= "0011101001"; -- + 0x3C +
    wait for clock_period;
    word10 <= "1011000101"; -- + 0x4D +
    wait for clock_period;
    word10 <= "1000010101"; -- + 0x5E -
    wait for clock_period;
    word10 <= "0101110011"; -- - 0x6F +
    wait for clock_period;

    valid10        <= '0';

    -- now wait for the SM to send out the packet
    wait for clock_period*25;

    
    stop_the_clock <= true;
    wait;
  end process;


  clocking: process
  begin
    while not stop_the_clock loop
      aclk <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;

end Behavioral;
