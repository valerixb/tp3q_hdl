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
-- latest rev oct 24 2023
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

entity gearbox_48_to_64 is
  generic(
    C_S_AXIS_TUSER_WIDTH  : integer	:= 16
    );
  port(
    clk                  : in std_logic;
    resetn               : in std_logic;
    --
    in_port_tready_out   : out std_logic;
    in_port_tdata_in     :  in std_logic_vector(47 downto 0);
    in_port_tvalid_in    :  in std_logic;
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
  type state is ( W1_R3, W2_Rnone, W3_R1, W4_R2);
  signal  sm_exec_state : state := W1_R3;                                                   

  signal circbuf       : std_logic_vector(191 downto 0);
  signal circbuf_valid : std_logic;
  signal dataout_buf   : std_logic_vector(63 downto 0);
  signal in_buf        : std_logic_vector(47 downto 0);
  signal in_valid_buf  : std_logic := '0';
  signal tvalid_buf    : std_logic := '0';
  signal tlast_buf     : std_logic := '0';
  --signal tready_buf    : std_logic := '1';
  signal tkeep_buf     : std_logic_vector(7 downto 0) := "11111111";
  signal tuser_buf     : std_logic_vector(C_S_AXIS_TUSER_WIDTH-1 downto 0) := (others=>'0');


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
          --tready_buf    <= out_port_tready_in;
        else
          in_buf        <= in_port_tdata_in;
          in_valid_buf  <= in_port_tvalid_in;
          --tready_buf    <= out_port_tready_in;
        end if;  -- if not reset
      end if;  -- if clk rising edge
    end process in_reg_slice;

  
  -- main machine
  state_machine: process (clk, resetn)
    begin
      if(rising_edge(clk)) then
        if(resetn='0') then
          circbuf       <= (others=>'0');
          circbuf_valid <= '0';
          dataout_buf   <= (others=>'0');
          --tready_buf    <= '1';
          tvalid_buf    <= '0';
          tlast_buf     <= '0';
          tuser_buf     <= (others=>'0');
          tkeep_buf     <= (others=>'1');
          sm_exec_state <= W1_R3;

        else
        if((out_port_tready_in='1') and (in_valid_buf='1')) then
            case(sm_exec_state) is

              when W1_R3 =>
                circbuf( 47 downto  0) <= in_buf;
                -- data in circular buffer is valid only after first write to W1 position
                circbuf_valid <= '1';
                if( circbuf_valid='1' ) then
                  dataout_buf <= circbuf( 191 downto 128);
                  tvalid_buf  <= '1';
                  -- generate a TLAST when circular buffer wraps
                  tlast_buf   <= '1';
                else
                  dataout_buf <= (others => '0');
                  tvalid_buf  <= '0';
                  tlast_buf   <= '0';
              end if;
                circbuf( 191 downto 128) <= (others => '0');
                --tready_buf    <= '1';
                tuser_buf     <= (others=>'0');
                tkeep_buf     <= (others=>'1');
                sm_exec_state <= W2_Rnone;

              when W2_Rnone =>
                circbuf(95 downto 48) <= in_buf;
                circbuf_valid <= circbuf_valid;
                dataout_buf <= dataout_buf;
                tvalid_buf  <= '0';
                --tready_buf    <= '1';
                tlast_buf     <= '0';
                tuser_buf     <= (others=>'0');
                tkeep_buf     <= (others=>'1');
                sm_exec_state <= W3_R1;

              when W3_R1 =>
                circbuf( 143 downto 96) <= in_buf;
                circbuf_valid <= circbuf_valid;
                if( circbuf_valid='1' ) then
                  dataout_buf <= circbuf(  63 downto   0);
                  tvalid_buf  <= '1';
                else
                  dataout_buf <= (others => '0');
                  tvalid_buf  <= '0';
                end if;
                circbuf(  63 downto   0) <= (others => '0');
                --tready_buf    <= '1';
                tlast_buf     <= '0';
                tuser_buf     <= (others=>'0');
                tkeep_buf     <= (others=>'1');
                sm_exec_state <= W4_R2;

              when W4_R2 =>
                circbuf( 191 downto 144) <= in_buf;
                circbuf_valid <= circbuf_valid;
                if( circbuf_valid='1' ) then
                  dataout_buf <= circbuf( 127 downto  64);
                  tvalid_buf  <= '1';
                else
                  dataout_buf <= (others => '0');
                  tvalid_buf  <= '0';
                end if;
                circbuf( 127 downto  64) <= (others => '0');
                --tready_buf    <= '1';
                tlast_buf     <= '0';
                tuser_buf     <= (others=>'0');
                tkeep_buf     <= (others=>'1');
                sm_exec_state <= W1_R3;

              when others =>
                circbuf       <= circbuf;
                circbuf_valid <= '0';
                dataout_buf   <= dataout_buf;
                --tready_buf    <= '1';
                tvalid_buf    <= '0';
                tlast_buf     <= '0';
                tuser_buf     <= (others=>'0');
                tkeep_buf     <= (others=>'1');
                sm_exec_state <= W1_R3;

            end case;
          else
            -- if input not valid or ouput not ready, just hold on
            circbuf       <= circbuf;
            circbuf_valid <= circbuf_valid;
            dataout_buf   <= dataout_buf;
            tvalid_buf    <= tvalid_buf and not out_port_tready_in;
            tlast_buf     <= tlast_buf;
            tuser_buf     <= tuser_buf;
            tkeep_buf     <= tkeep_buf;
            sm_exec_state <= sm_exec_state;            
          end if; -- if input valid & output ready
        end if;  -- if not reset
      end if;  -- if clk rising edge
    end process state_machine;



end Behavioral;
