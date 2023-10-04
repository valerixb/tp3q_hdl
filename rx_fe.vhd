--
-- receiver frontend for HSSIO async RX
--
-- deinterleaver, data recovery (oversampling phase picker),
-- 4 to 10 gearbox, comma aligner
--
-- latest rev jun 13 2023
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

entity rx_fe is
  Port( 
    clk            :  in std_logic;
    reset          :  in std_logic;
    RIU_configured :  in std_logic;
    fifo_valid     :  in std_logic;
    in_P           :  in std_logic_vector(7 downto 0);
    in_N           :  in std_logic_vector(7 downto 0);
    comma_align_en :  in std_logic;
    out10          : out std_logic_vector(9 downto 0);
    out10_valid    : out std_logic;
    aligned        : out std_logic;
    --- debug
    debug_deinterleaved      : out std_logic_vector(15 downto 0);
    debug_sample_vector      : out std_logic_vector(16 downto 0);
    debug_sample_vector_len  : out std_logic_vector(4 downto 0);
    debug_old_2words         : out std_logic_vector(19 downto 0);
    debug_comma_ptr          : out std_logic_vector(3 downto 0)
  );
end rx_fe;

architecture Behavioral of rx_fe is

-- 8b10b comma characters for alignment
constant K28_5N : std_logic_vector(9 downto 0) := "0011111010";
constant K28_5P : std_logic_vector(9 downto 0) := "1100000101";
-- constant K28_5N : std_logic_vector(9 downto 0) := "0101111100";
-- constant K28_5P : std_logic_vector(9 downto 0) := "1010000011";

--constant K28_1N : std_logic_vector(9 downto 0) := "0011111001";
--constant K28_1P : std_logic_vector(9 downto 0) := "1100000110";
--constant K28_7N : std_logic_vector(9 downto 0) := "0011111000";
--constant K28_7P : std_logic_vector(9 downto 0) := "1100000111";

constant SAMP_FIFO_LEN : natural := 17;
type VEC4_ARR is array(0 to 3) of std_logic_vector(3 downto 0);
subtype SAMP_FIFO_VECTOR is std_logic_vector(SAMP_FIFO_LEN-1 downto 0);
type SAMPL_PH_TYPE is (PH0, PH1A, PH1B, PH2);
type SAMPL_PH_VEC_TYPE is array(0 to 4) of SAMPL_PH_TYPE;

signal rx_vec, rx_vec_dly : std_logic_vector(16 downto 0);  -- 17 bit to remember also last bit of previous nibble
signal sample_vec_in      : std_logic_vector(3 downto 0);
-- signal "sample_ph_vec" is 5 bits instead of 4: bit 0 refers to last bit of previously received nibble
signal sample_ph_vec      : SAMPL_PH_VEC_TYPE;
signal sample_vector      : SAMP_FIFO_VECTOR;
-- max length of sample vector to comma aligner is"SAMP_FIFO_LEN" 
-- and not "SAMP_FIFO_LEN-1", because it's the length, not the index
signal sample_vector_len  : natural range 0 to SAMP_FIFO_LEN;
signal sampler_word_out   : std_logic_vector(9 downto 0);
signal sampler_word_valid, sampler_word_valid_dly : std_logic;
signal old_2words         : std_logic_vector(19 downto 0);
signal comma_ptr          : natural range 0 to 9;
signal out10_int          : std_logic_vector(9 downto 0);
signal out10_valid_int    : std_logic;
signal aligned_int, aligned_int_dly : std_logic;


begin

  out10 <= out10_int;
  out10_valid <= out10_valid_int;
  aligned <= aligned_int_dly;

  debug_deinterleaved <= rx_vec(16 downto 1);
  debug_sample_vector <= sample_vector;
  debug_sample_vector_len <= std_logic_vector(to_unsigned(sample_vector_len,5));
  debug_comma_ptr <= std_logic_vector(to_unsigned(comma_ptr,4));
  debug_old_2words <= old_2words;

  main_machine: process(clk, reset, RIU_configured)
    
    variable edge_vec         : VEC4_ARR;
    variable next_vector      : SAMP_FIFO_VECTOR;
    variable next_len         : natural range 0 to SAMP_FIFO_LEN;
    variable comma_search_buf : std_logic_vector(19 downto 0);
    variable sample_phase     : SAMPL_PH_TYPE;
  
  
    begin

      if(rising_edge(clk)) then
        if(reset='1' or RIU_configured='0') then
          rx_vec                 <= (others=>'0');
          rx_vec_dly             <= (others=>'0');
          sample_ph_vec          <= (others=>PH2);
          sampler_word_out       <= (others=>'0');
          old_2words             <= (others=>'0');
          sampler_word_valid     <= '0';
          sampler_word_valid_dly <= '0';
          comma_ptr              <= 0;
          out10_int              <= (others=>'0');
          out10_valid_int        <= '0';
          aligned_int            <= '0';
          sample_vector          <= (others=>'0');
          sample_vector_len      <= 0;
        else
          -- note: if not FIFO_valid, the pipe just stops, waiting for more data
          if( fifo_valid = '1' ) then

            sampler_word_valid_dly <= sampler_word_valid;
            aligned_int_dly        <= aligned_int;
            rx_vec_dly             <= rx_vec;

            ---------------------------------
            -- de-interleave input streams --
            ---------------------------------
            -- LSB is oldest; N side is delayed (and negated)
            rx_vec <= in_P(7) & not in_N(7) &
                      in_P(6) & not in_N(6) & 
                      in_P(5) & not in_N(5) & 
                      in_P(4) & not in_N(4) & 
                      in_P(3) & not in_N(3) & 
                      in_P(2) & not in_N(2) & 
                      in_P(1) & not in_N(1) & 
                      in_P(0) & not in_N(0) &
                      rx_vec(16);              -- remember last bit of previous nibble

           
            ---------------------------------
            --           sampler           --
            ---------------------------------
            -- pick the right phase
            -- input from deinterleaver is 4 bit at 4x oversampling
          
            next_vector := sample_vector;      -- initialize vector out of the sampler...
            next_len    := sample_vector_len;  -- ...and its length
            sample_phase := sample_ph_vec(4);
            sample_ph_vec(0) <= sample_phase;   -- record sampling point of last bit of previous nibble
            
            -- generate loop on each bit 
            for i in 0 to 3 loop
              -- look for edges
              --edge_vec(i) := rx_vec(i*4+3 downto i*4+1) xor rx_vec(i*4+2 downto i*4);
              edge_vec(i) := rx_vec(i*4+4 downto i*4+1) xor rx_vec(i*4+3 downto i*4);
            
              -- sample at the right phase (see notes for documentation)
              -- I use a variable to use latest value in case there are no transitions
              case(edge_vec(i)) is
                when "0010" => 
                  sample_vec_in(i)   <= rx_vec(i*4+1+2);
                  sample_phase       := PH2;
                when "0100"  =>
                  sample_vec_in(i)   <= rx_vec(i*4+1);
                  sample_phase       := PH0;
                when "1000" =>
                  sample_vec_in(i)   <= rx_vec(i*4+1+1);
                  sample_phase       := PH1A;
                when "0001" =>
                  sample_vec_in(i)   <= rx_vec(i*4+1+1);
                  sample_phase       := PH1B;
                when others =>
                  -- no transition or multiple transitions: use latest value
                  --sample_vec_in(i) <= rx_vec(i*4+1+sample_phase);
                  case(sample_phase) is
                    when PH0 =>
                      sample_vec_in(i) <= rx_vec(i*4+1);
                    when PH1A | PH1B =>
                      sample_vec_in(i) <= rx_vec(i*4+1+1);
                    when PH2 =>
                      sample_vec_in(i) <= rx_vec(i*4+1+2);
                  end case;
                  
              end case;
              
              -- record sampling phase for successive ADD/DROP check
              sample_ph_vec(i+1) <= sample_phase;
            
              ---------------------------------
              --         ADD / DROP          --
              ---------------------------------
              -- push 0, 1 or 2 bits into the fifo, accounting for ADD/DROP cases (see notes for documentation)
              -- do a ADD/DROP only when sampling phase jumps by more than 1 position, 
              -- otherwise it's not needed
              if( sample_ph_vec(i+1)=PH0 and sample_ph_vec(i)=PH2 ) then
                -- DROP case: don't add any bit
                next_vector := next_vector;
                next_len := next_len;
              elsif( sample_ph_vec(i+1)=PH2 and sample_ph_vec(i)=PH0 ) then
                -- ADD case: add 2 bits
                next_vector := sample_vec_in(i) & rx_vec_dly(i*4+1) & next_vector(SAMP_FIFO_VECTOR'LENGTH-1 downto 2);
                next_len := next_len+2;
              elsif( sample_ph_vec(i+1)=PH1B and sample_ph_vec(i)=PH0 ) then
                -- ADD case: add 2 bits
                next_vector := sample_vec_in(i) & not rx_vec_dly(i*4+1-1) & next_vector(SAMP_FIFO_VECTOR'LENGTH-1 downto 2);
                next_len := next_len+2;
              else
                -- regular case: add one bit only
                next_vector := sample_vec_in(i) & next_vector(SAMP_FIFO_VECTOR'LENGTH-1 downto 1);
                next_len := next_len+1;
              end if;
            
            end loop;  -- on 4 input bits

            -- update sampler FIFO
            sample_vector     <= next_vector;
            -- now update sampler FIFO length in case 10 bits at least are available
            -- as an output to next stage 
            if( next_len >= 10 ) then
              sample_vector_len <= next_len-10;
              sampler_word_valid <= '1';
              -- can't use index in VHDL :-(
              case(next_len) is
                when 10 => sampler_word_out <= next_vector(SAMP_FIFO_VECTOR'LENGTH-1 downto SAMP_FIFO_VECTOR'LENGTH-10);
                when 11 => sampler_word_out <= next_vector(SAMP_FIFO_VECTOR'LENGTH-2 downto SAMP_FIFO_VECTOR'LENGTH-11);
                when 12 => sampler_word_out <= next_vector(SAMP_FIFO_VECTOR'LENGTH-3 downto SAMP_FIFO_VECTOR'LENGTH-12);
                when 13 => sampler_word_out <= next_vector(SAMP_FIFO_VECTOR'LENGTH-4 downto SAMP_FIFO_VECTOR'LENGTH-13);
                when 14 => sampler_word_out <= next_vector(SAMP_FIFO_VECTOR'LENGTH-5 downto SAMP_FIFO_VECTOR'LENGTH-14);
                when 15 => sampler_word_out <= next_vector(SAMP_FIFO_VECTOR'LENGTH-6 downto SAMP_FIFO_VECTOR'LENGTH-15);
                when 16 => sampler_word_out <= next_vector(SAMP_FIFO_VECTOR'LENGTH-7 downto SAMP_FIFO_VECTOR'LENGTH-16);
                when 17 => sampler_word_out <= next_vector(SAMP_FIFO_VECTOR'LENGTH-8 downto SAMP_FIFO_VECTOR'LENGTH-17);
                when others => sampler_word_out <= sampler_word_out;
              end case;

--              -- check all cases without explicitly assuming that SAMP_FIFO_VECTOR'LENGTH is 17
--              -- PROBABLY NOT GOOD because there are no "ELSE", so it's priority encoded, which I think is way
--              -- heavier for time closure
--              for i in 10 to SAMP_FIFO_VECTOR'LENGTH loop
--                if( next_len = i ) then 
--                  sampler_word_out <= next_vector(SAMP_FIFO_VECTOR'LENGTH-i+9 downto SAMP_FIFO_VECTOR'LENGTH-i);
--                end if;
--              end loop;

            else
              sample_vector_len <= next_len;
              sampler_word_valid <= '0';
              sampler_word_out <= sampler_word_out;
            end if;

          end if;  -- if FIFO_valid
          
          ---------------------------------
          --         comma align         --
          ---------------------------------
          if( sampler_word_valid = '1' ) then
            comma_search_buf := sampler_word_out & old_2words(19 downto 10);
            old_2words <= comma_search_buf;
            if( comma_align_en = '1' ) then
              if   ( (comma_search_buf( 9 downto 0) = K28_5N) or (comma_search_buf( 9 downto 0) = K28_5P) ) then  comma_ptr <=0; aligned_int<='1';
              elsif( (comma_search_buf(10 downto 1) = K28_5N) or (comma_search_buf(10 downto 1) = K28_5P) ) then  comma_ptr <=1; aligned_int<='1';
              elsif( (comma_search_buf(11 downto 2) = K28_5N) or (comma_search_buf(11 downto 2) = K28_5P) ) then  comma_ptr <=2; aligned_int<='1';
              elsif( (comma_search_buf(12 downto 3) = K28_5N) or (comma_search_buf(12 downto 3) = K28_5P) ) then  comma_ptr <=3; aligned_int<='1';
              elsif( (comma_search_buf(13 downto 4) = K28_5N) or (comma_search_buf(13 downto 4) = K28_5P) ) then  comma_ptr <=4; aligned_int<='1';
              elsif( (comma_search_buf(14 downto 5) = K28_5N) or (comma_search_buf(14 downto 5) = K28_5P) ) then  comma_ptr <=5; aligned_int<='1';
              elsif( (comma_search_buf(15 downto 6) = K28_5N) or (comma_search_buf(15 downto 6) = K28_5P) ) then  comma_ptr <=6; aligned_int<='1';
              elsif( (comma_search_buf(16 downto 7) = K28_5N) or (comma_search_buf(16 downto 7) = K28_5P) ) then  comma_ptr <=7; aligned_int<='1';
              elsif( (comma_search_buf(17 downto 8) = K28_5N) or (comma_search_buf(17 downto 8) = K28_5P) ) then  comma_ptr <=8; aligned_int<='1';
              elsif( (comma_search_buf(18 downto 9) = K28_5N) or (comma_search_buf(18 downto 9) = K28_5P) ) then  comma_ptr <=9; aligned_int<='1';
              else comma_ptr <= comma_ptr; aligned_int <= aligned_int;
              end if;
            else
              comma_ptr <= comma_ptr; aligned_int <= aligned_int;
            end if;
          end if;
          
          if( sampler_word_valid_dly = '1') then
            out10_valid_int <= '1';
            case(comma_ptr) is
              when 0 => out10_int <= old_2words( 9 downto 0);
              when 1 => out10_int <= old_2words(10 downto 1);
              when 2 => out10_int <= old_2words(11 downto 2);
              when 3 => out10_int <= old_2words(12 downto 3);
              when 4 => out10_int <= old_2words(13 downto 4);
              when 5 => out10_int <= old_2words(14 downto 5);
              when 6 => out10_int <= old_2words(15 downto 6);
              when 7 => out10_int <= old_2words(16 downto 7);
              when 8 => out10_int <= old_2words(17 downto 8);
              when 9 => out10_int <= old_2words(18 downto 9);
            end case;
          else
            out10_valid_int <= '0';
          end if;

        end if; -- if not reset
      end if; -- if clock edge
    end process main_machine;

end Behavioral;
