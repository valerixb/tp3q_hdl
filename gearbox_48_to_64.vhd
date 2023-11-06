--
-- 48 to 64 gearbox
-- common clock
-- 192 bit circular buffer
-- state machine operating on 4-state cycle
-- buffer written in 4 cycles
-- buffer read in 3 cycles + 1 idle (VALID deassert)
-- remember to write before you read! (duh)
-- after reading, set bits to zero; this takes care of
-- potentially incomplete packets
-- READY handshake on both sides
--
-- latest rev nov 6 2023
--


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
---use ieee.math_real.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity gearbox_48_to_64 is
  generic(
    C_S_AXIS_TUSER_WIDTH  : integer	:= 1
    );
  port(
    clk                  : in std_logic;
    resetn               : in std_logic;
    --watchdog_timeout     : in std_logic_vector(31 downto 0);
    --
    in_port_tready_out   : out std_logic;
    in_port_tvalid_in    :  in std_logic;
    in_port_tdata_in     :  in std_logic_vector(47 downto 0);
    --
    out_port_tready_in   :  in std_logic;
    out_port_tdata_out   : out std_logic_vector(63 downto 0);
    out_port_tvalid_out  : out std_logic;
    out_port_tlast_out   : out std_logic;
    out_port_tuser_out   : out std_logic_vector(C_S_AXIS_TUSER_WIDTH-1 downto 0);
    out_port_tkeep_out   : out std_logic_vector(7 downto 0);
    out_port_tstrb_out   : out std_logic_vector(7 downto 0)
    );
end gearbox_48_to_64;


architecture Behavioral of gearbox_48_to_64 is

  -- State machine                                             
  type state is ( W1_R3, W2_R1, W3_R2, W4_Rnone);
  
  -- half a millisecond timeout at 160 MHz is 80'000 cycles
  constant watchdog_timeout     : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(80000,32));
  
  signal  sm_exec_state : state := W1_R3;                                                   

  signal carry_buf      : std_logic_vector(63 downto 0);
  signal carrybuf_valid : std_logic;
  signal carrybuf_keep  : std_logic_vector(7 downto 0) := "11111111";
  signal dataout_buf    : std_logic_vector(63 downto 0);
  signal in_buf         : std_logic_vector(47 downto 0);
  signal in_valid_buf   : std_logic := '0';
  signal tvalid_buf     : std_logic := '0';
  signal tlast_buf      : std_logic := '0';
  signal tkeep_buf      : std_logic_vector(7 downto 0) := "11111111";
  signal tuser_buf      : std_logic_vector(C_S_AXIS_TUSER_WIDTH-1 downto 0) := (others=>'0');
  signal watchdog_timer : unsigned(31 downto 0);
  signal watchdog_reset : std_logic;



begin

  -- buffer outputs
  in_port_tready_out  <= out_port_tready_in;
  --
  out_port_tdata_out  <= dataout_buf;
  out_port_tvalid_out <= tvalid_buf;
  out_port_tlast_out  <= tlast_buf;
  out_port_tuser_out  <= tuser_buf;
  out_port_tkeep_out  <= tkeep_buf;
  out_port_tstrb_out  <= tkeep_buf;

  -- input register slice to help timing closure
  in_reg_slice: process (clk, resetn)
    begin
      if(rising_edge(clk)) then
        if(resetn='0') then
          in_buf        <= (others=>'0');
          in_valid_buf  <= '0';
        else
          if( out_port_tready_in='1') then
            in_buf        <= in_port_tdata_in;
            in_valid_buf  <= in_port_tvalid_in;
          else
            in_buf        <= in_buf;
            in_valid_buf  <= in_valid_buf;
          end if;
        end if;  -- if not reset
      end if;  -- if clk rising edge
    end process in_reg_slice;

  
  -- main machine
  state_machine: process (clk, resetn)
    begin
      if(rising_edge(clk)) then
        if(resetn='0') then
          carry_buf      <= (others=>'0');
          carrybuf_valid <= '0';
          carrybuf_keep  <= (others=>'1');
          dataout_buf    <= (others=>'0');
          tvalid_buf     <= '0';
          tlast_buf      <= '0';
          tuser_buf      <= (others=>'0');
          tkeep_buf      <= (others=>'1');
          watchdog_reset <= '1';
          sm_exec_state  <= W1_R3;

        else
          if((out_port_tready_in='1') and (in_valid_buf='1')) then
            watchdog_reset <= '1';
            case(sm_exec_state) is

              when W1_R3 =>
                carry_buf( 47 downto  0) <= in_buf;
                carry_buf( 63 downto 48) <= (others=>'0');
                carrybuf_keep  <= "00111111";
                -- data in carry buffer is valid only after first write to W1 position
                carrybuf_valid <= '1';
                if( carrybuf_valid='1' ) then
                  dataout_buf <= carry_buf;
                  tvalid_buf  <= '1';
                  -- generate a TLAST when an integer number of 48-bit words has been transmitted
                  tlast_buf   <= '1';
                else
                  dataout_buf <= (others => '0');
                  tvalid_buf  <= '0';
                  tlast_buf   <= '0';
                end if;
                tuser_buf     <= (others=>'0');
                tkeep_buf     <= (others=>'1');
                sm_exec_state <= W2_R1;

              when W2_R1 =>
                carry_buf( 31 downto  0) <= in_buf( 47 downto 16);
                carry_buf( 63 downto 32) <= (others=>'0');
                carrybuf_keep  <= "00001111";
                carrybuf_valid <= carrybuf_valid;
                if( carrybuf_valid='1' ) then
                  dataout_buf( 47 downto   0) <= carry_buf( 47 downto   0);
                  dataout_buf( 63 downto  48) <= in_buf( 15 downto   0);
                  tvalid_buf  <= '1';
                else
                  dataout_buf <= (others => '0');
                  tvalid_buf  <= '0';
                end if;
                tlast_buf     <= '0';
                tuser_buf     <= (others=>'0');
                tkeep_buf     <= (others=>'1');
                sm_exec_state <= W3_R2;

              when W3_R2 =>
                carry_buf( 15 downto  0) <= in_buf( 47 downto 32);
                carry_buf( 63 downto 16) <= (others=>'0');
                carrybuf_keep  <= "00000011";
                carrybuf_valid <= carrybuf_valid;
                if( carrybuf_valid='1' ) then
                  dataout_buf( 31 downto   0) <= carry_buf( 31 downto  0);
                  dataout_buf( 63 downto  32) <=  in_buf( 31 downto   0);
                  tvalid_buf  <= '1';
                else
                  dataout_buf <= (others => '0');
                  tvalid_buf  <= '0';
                end if;
                tlast_buf     <= '0';
                tuser_buf     <= (others=>'0');
                tkeep_buf     <= (others=>'1');
                sm_exec_state <= W4_Rnone;

              when W4_Rnone =>
                carry_buf( 63 downto 16) <= in_buf;
                carrybuf_valid <= carrybuf_valid;
                carrybuf_keep  <= "11111111";
                dataout_buf <= dataout_buf;
                tvalid_buf  <= '0';                
                tlast_buf     <= '0';
                tuser_buf     <= (others=>'0');
                tkeep_buf     <= (others=>'1');
                sm_exec_state <= W1_R3;

              when others =>
                carry_buf      <= carry_buf;
                carrybuf_valid <= '0';
                dataout_buf    <= dataout_buf;
                tvalid_buf     <= '0';
                tlast_buf      <= '0';
                tuser_buf      <= (others=>'0');
                tkeep_buf      <= (others=>'1');
                sm_exec_state  <= W1_R3;

            end case;
          else
            -- if input not valid or ouput not ready, just hold on
            -- 
            -- let the watchdog timer run only if we are waiting for data from Timepix;
            -- if we are kept in hold by the packetizer, wait forever (it has its own timeout)
            
            if( watchdog_timer = x"00000000") then
              watchdog_reset <= '1';
              carry_buf      <= (others=>'0');
              carrybuf_valid <= '0';
              if( carrybuf_valid = '1' ) then
                dataout_buf    <= carry_buf;
                tvalid_buf     <= '1';
                tlast_buf      <= '1';
                tuser_buf      <= std_logic_vector(to_unsigned(1, C_S_AXIS_TUSER_WIDTH));
                tkeep_buf      <= carrybuf_keep;
              else
                dataout_buf    <= dataout_buf;
                tvalid_buf     <= tvalid_buf and not out_port_tready_in;
                tlast_buf      <= tlast_buf;
                tuser_buf      <= tuser_buf;
                tkeep_buf      <= tkeep_buf;
              end if;
              sm_exec_state  <= W1_R3;
            else
              watchdog_reset <= in_valid_buf;
              carry_buf      <= carry_buf;
              carrybuf_valid <= carrybuf_valid;
              dataout_buf    <= dataout_buf;
              tvalid_buf     <= tvalid_buf and not out_port_tready_in;
              tlast_buf      <= tlast_buf;
              tuser_buf      <= tuser_buf;
              tkeep_buf      <= tkeep_buf;
              sm_exec_state  <= sm_exec_state;
            end if;  -- if watchdog timeout            
          end if; -- if input valid & output ready
        end if;  -- if not reset
      end if;  -- if clk rising edge
    end process state_machine;


	watchdog: process(clk)
	begin
	  if (rising_edge (clk)) then
	    if(watchdog_reset = '1') then                                                           
	      watchdog_timer <= unsigned(watchdog_timeout);
	    else
	      if(watchdog_timer /= x"00000000") then
	        watchdog_timer <= watchdog_timer -1;
	      else
	        watchdog_timer <= x"00000000";
	      end if;  -- if expired
	    end if;  -- if not reset
      end if; -- if clock edge
	end process watchdog;


end Behavioral;
