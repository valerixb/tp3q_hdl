library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity UDPpacketizer_v1_0_AXIS is
	generic (
	    -- ethernet maximum transmission unit, in bytes. 9000=jumbo frames=our default (default eth is 1500)
        MTU                     : integer	:= 9000;
	    -- stream master intf
		C_M_AXIS_TDATA_WIDTH    : integer	:= 64;
		C_M_AXIS_TUSER_WIDTH    : integer	:= 1;
		C_M_AXIS_TID_WIDTH      : integer	:= 8;
		C_M_AXIS_TDEST_WIDTH    : integer	:= 4;
        -- stream slave intf
		C_S_AXIS_TDATA_WIDTH	: integer	:= 64;
		C_S_AXIS_TUSER_WIDTH    : integer	:= 1;
		C_S_AXIS_TID_WIDTH      : integer	:= 8;
		C_S_AXIS_TDEST_WIDTH    : integer	:= 4;
		-- width of command registers coming from control axi-lite interface
		C_S_AXIlite_DATA_WIDTH	  : integer	:= 32
	);
	port (
		-- config ports
		PKTZR_enable     : in std_logic;
		SRC_IP           : in std_logic_vector(31 downto 0);
		SRC_MAC          : in std_logic_vector(47 downto 0);
		SRC_PORT         : in std_logic_vector(15 downto 0);
		DEST_IP          : in std_logic_vector(31 downto 0);
		DEST_MAC         : in std_logic_vector(47 downto 0);
		DEST_PORT        : in std_logic_vector(15 downto 0);
		WATCHDOG_TIMEOUT : in std_logic_vector(C_S_AXIlite_DATA_WIDTH-1 downto 0);

        -- stream slave
        S_AXIS_ACLK	     : in std_logic;
		S_AXIS_ARESETN	 : in std_logic;
		S_AXIS_TREADY	 : out std_logic;
		S_AXIS_TDATA	 : in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		S_AXIS_TSTRB	 : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		S_AXIS_TKEEP	 : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		S_AXIS_TUSER	 : in std_logic_vector(C_S_AXIS_TUSER_WIDTH-1 downto 0);
		S_AXIS_TID   	 : in std_logic_vector(C_S_AXIS_TID_WIDTH-1 downto 0);
		S_AXIS_TDEST   	 : in std_logic_vector(C_S_AXIS_TDEST_WIDTH-1 downto 0);
		S_AXIS_TLAST	 : in std_logic;
		S_AXIS_TVALID	 : in std_logic;

        -- stream master
		M_AXIS_ACLK	     : in std_logic;
		M_AXIS_ARESETN	 : in std_logic;
		M_AXIS_TVALID	 : out std_logic;
		M_AXIS_TDATA	 : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		M_AXIS_TSTRB	 : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		M_AXIS_TKEEP	 : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		M_AXIS_TUSER	 : out std_logic_vector(C_M_AXIS_TUSER_WIDTH-1 downto 0);
		M_AXIS_TID   	 : out std_logic_vector(C_M_AXIS_TID_WIDTH-1 downto 0);
		M_AXIS_TDEST   	 : out std_logic_vector(C_M_AXIS_TDEST_WIDTH-1 downto 0);
		M_AXIS_TLAST 	 : out std_logic;
		M_AXIS_TREADY	 : in std_logic;
		busy             : out std_logic				
	);
end UDPpacketizer_v1_0_AXIS;

architecture implementation of UDPpacketizer_v1_0_AXIS is

  -- function called clogb2 that returns an integer which has the   
  -- value of the ceiling of the log base 2.                              
  function clogb2 (bit_depth : integer) return integer is                  
    variable depth  : integer := bit_depth;                               
    variable count  : integer := 1;                                       
  begin                                                                   
    for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
      if (bit_depth <= 2) then                                           
        count := 1;                                                      
      else                                                               
        if(depth <= 1) then                                              
     	  count := count;                                                
     	else                                                             
     	  depth := depth / 2;                                            
          count := count + 1;                                            
     	end if;                                                          
      end if;                                                            
    end loop;                                                             
    return(count);        	                                              
  end;                                                                    

	-- State machine                                             
	type state is ( IDLE,
	                PREPARE_PADDING,
	                WAIT_ENABLE,
	                FILLING_PKT,
	                CALC_CRC,
	                INIT_TXBUF,
	                TRANSMITTING_PKT);                               
	signal  sm_exec_state : state;                                                   

    -- frame header+footer is not counted in MTU; take IP header out
    -- to work out the maximum size, but include UDP header
    constant MAX_PKT_DATA : integer := MTU-20;
    -- I am sensitive to incoming TLAST only when input buffer is almost full,
    -- to avoid sanding too many small packets. 
    -- Threshold must be < (BUFLEN - max_incoming_burst)
    -- for timepix we have a max of 8 packets of 48 bits (= 6 bytes) 
    -- before a K28.5 is transmitted on the line; 
    -- 6 x 8 = 48 bytes max incoming burst; I use a margin of 64 for good measure
    constant BUF_FULL_THR : integer := MAX_PKT_DATA - 64;
    -- minimum ethernet frame is 64 bytes; 4 bytes will be added by MAC as FCS
    --constant MIN_PKT_DATA : integer := 64-18-20-8;
    constant MIN_PKT_DATA : integer := 64-4;
    -- corresponding packet index (min number of 64-bit words in payload)
    constant MIN_PKT_INDEX: integer := integer(ceil(real(MIN_PKT_DATA)/real(8))) -1;
    -- I add 0-padding to have a 64-bit aligned payload; therefore, the first index is 6
    CONSTANT FIRST_PAYLOAD_INDEX : INTEGER := 6;
    -- packet is stored in an array of 64-bit words 
    constant PACKET_ALLOC : integer := integer(ceil(real(MTU+14)/real(8)));
	
	signal tx_valid	                : std_logic;
	signal tx_ready                 : std_logic;
	signal tx_last	                : std_logic;
	signal rx_ready                 : std_logic;
	signal rx_valid	                : std_logic;
	signal rx_last	                : std_logic;
	signal stream_data_in 	        : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
	signal internal_tkeep           : std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
	signal saved_tkeep              : std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
	signal saved_tuser              : std_logic_vector(C_M_AXIS_TUSER_WIDTH-1 downto 0);
	signal rx_tuser                 : std_logic_vector(C_M_AXIS_TUSER_WIDTH-1 downto 0);
	signal saved_tid                : std_logic_vector(C_M_AXIS_TID_WIDTH-1 downto 0);
	signal saved_tdest              : std_logic_vector(C_M_AXIS_TDEST_WIDTH-1 downto 0);
	
    signal saved_src_ip             : std_logic_vector(31 downto 0);
    signal saved_src_mac            : std_logic_vector(47 downto 0);
    signal saved_src_port           : std_logic_vector(15 downto 0);
    signal saved_dest_ip            : std_logic_vector(31 downto 0);
    signal saved_dest_mac           : std_logic_vector(47 downto 0);
    signal saved_dest_port          : std_logic_vector(15 downto 0);

    signal pkt_index, last_pkt_index, substep  : integer;
    -- CRC is done on 16 bit word; we use a 32 bit accum to have space for max packet + some slack
    -- IP length is just UDP_length + 20 (bytes)
    signal UDP_length     : integer;
    signal UDP_CRC, partial1, partial2 : unsigned(31 downto 0);
    signal IP_CRC         : unsigned(31 downto 0);
    signal watchdog_timer : unsigned(31 downto 0);
    signal watchdog_reset : std_logic;
    signal pkt_counter    : unsigned(39 downto 0);
    
    
    -- decode number of final bytes for stream length not multiple of 8 bytes
	function tkeep_decode (tkeep : std_logic_vector ) return integer is                  
	 	variable cnt  : integer;                                       
	 begin
	   cnt := 0;
	   for i0 in 0 to (tkeep'length -1) loop
	     cnt := cnt + to_integer(unsigned(tkeep(i0 downto i0)));
	   end loop;
	   return(cnt);
	 end;                                                                    

    -- BRAM for packet buffer
    component rams_sp_rf is
      generic(
        DATA_WIDTH    : integer	:= 64;
        ADDR_WIDTH    : integer   := 11;
        -- I put also actual length required for the buffer, as it may be less than 2**ADDR_WIDTH and I save some BRAM
        BUFFER_LENGTH : integer   := 1127
      );
      port(
        clk   : in  std_logic;
        we    : in  std_logic;
        ready : in std_logic;
        en    : in  std_logic;
        addr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        di    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        do    : out std_logic_vector(DATA_WIDTH-1 downto 0)
      );
    end component rams_sp_rf;

    signal buf_we, buf_en      : std_logic;
    signal buf_addr            : std_logic_vector( clogb2(PACKET_ALLOC)-1 downto 0);
    signal buf_di, buf_do      : std_logic_vector( C_S_AXIS_TDATA_WIDTH-1 downto 0);
    signal buf_init, buf_ready : std_logic;


begin

	M_AXIS_TVALID	<= tx_valid;
	M_AXIS_TDATA	<= buf_do;
	M_AXIS_TLAST	<= tx_last;
    M_AXIS_TUSER	<= saved_tuser;
	M_AXIS_TID   	<= saved_tid;
	M_AXIS_TDEST   	<= saved_tdest;
	M_AXIS_TSTRB	<= internal_tkeep;
	M_AXIS_TKEEP	<= internal_tkeep;
    rx_valid        <= S_AXIS_TVALID;
    rx_last         <= S_AXIS_TLAST;
    rx_tuser        <= S_AXIS_TUSER;
    stream_data_in  <= S_AXIS_TDATA;
    S_AXIS_TREADY   <= rx_ready;
    tx_ready        <= M_AXIS_TREADY;
    buf_addr        <= std_logic_vector(to_unsigned(pkt_index,clogb2(PACKET_ALLOC)));
    buf_ready       <= M_AXIS_TREADY or buf_init;
    

    -- buffer BRAM instance
    packet_buffer : rams_sp_rf
      generic map (
        DATA_WIDTH	   => C_S_AXIS_TDATA_WIDTH,
        ADDR_WIDTH     => clogb2(PACKET_ALLOC),
        BUFFER_LENGTH  => PACKET_ALLOC
      )
      port map (
        clk     => S_AXIS_ACLK,
        we      => buf_we,
        ready   => buf_ready,
        en      => buf_en,
        addr    => buf_addr,
        di      => buf_di,
        do      => buf_do
      );

	                                                                                               
	-- Control state machine
	state_machine: process(M_AXIS_ACLK)
	
	  variable pkt_word       : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
	  variable aux_datain     : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
	  variable CRC_aux        : unsigned(31 downto 0);
	  variable len_aux        : unsigned(15 downto 0);
	  variable add_length     : integer;

	begin
	  if (rising_edge (M_AXIS_ACLK)) then
	    if(M_AXIS_ARESETN = '0') then                                                           
	      sm_exec_state <= IDLE;
	      rx_ready <= '0';
	      tx_valid <= '0';
	      --stream_data_out <= (others => '0');
	      saved_tkeep <= (others => '1');
	      internal_tkeep <= (others => '1');
          saved_tuser <= (others => '0');
          saved_tid <= (others => '0');
          saved_tdest <= (others => '0');
          saved_src_ip     <= (others => '0');
          saved_src_mac    <= (others => '0');
          saved_src_port   <= (others => '0');
          saved_dest_ip    <= (others => '0');
          saved_dest_mac   <= (others => '0');
          saved_dest_port  <= (others => '0');
	      tx_last <= '0';
	      watchdog_reset <= '1';
	      buf_we <= '0';
	      buf_en <= '0';
	      --buf_addr <= (others => '0');
	      buf_init <= '0';
	      pkt_index <=0;
	      last_pkt_index <=0;
	      busy <= '0';
	      pkt_counter <= (others => '0');
	    else                                                                                    
          buf_en <= '1';
	      case (sm_exec_state) is                   
	                                                 
	        when IDLE =>
	          
	          -- prepare storage of payload data
	          -- headers will be written at the end, after calculation
	          -- of CRC and actual length
	          
	          -- data will start from index 6
              --pkt_index <= 6-1;
              pkt_index <= FIRST_PAYLOAD_INDEX-1;
              substep <= 0;
              buf_we <= '0';
              buf_init <= '0';
	          busy <= '0';
                  
              -- initialize length
              -- IP length will be = UDP_length + 20
	          --UDP_length <= 8;
	          UDP_length <= 14;  -- includes the 6 bytes of 64-bit alignment

              -- initialize IP CRC
	          -- IP CRC is for the header only; it will need the total length, though
	          -- IP_CRC is initialized in PREPARE_PADDING state
	          --IP_CRC <= (others => '0');

              -- UDP CRC id optional, but we calculate it; it is done on all UDP data (header + payload) + IP pseudoheader
              -- UDP_CRC is initialized in PREPARE_PADDING state
              --UDP_CRC <= (others => '0');

              -- we need to wait for external enable before asserting rx_ready 
              rx_ready <= '0';
              tx_valid <= '0';
              tx_last <= '0';
              saved_tkeep <= (others => '1');
              internal_tkeep <= (others => '1');
              saved_tuser <= (others => '0');
              saved_tid <= (others => '0');
              saved_tdest <= (others => '0');
              saved_src_ip     <= SRC_IP;
              saved_src_mac    <= SRC_MAC;
              saved_src_port   <= SRC_PORT;
              saved_dest_ip    <= DEST_IP;
              saved_dest_mac   <= DEST_MAC;
              saved_dest_port  <= DEST_PORT;

              watchdog_reset <= '1';
              sm_exec_state <= PREPARE_PADDING;

            --*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

	        when PREPARE_PADDING =>
	          busy <= '0';
	          -- set to 0 the minimum ethernet packet, in case we have to add padding
	          pkt_index<= pkt_index+1;
              substep <= 0;
	          rx_ready <= '0';

              -- initialize IP CRC with known data
              IP_CRC <= x"00004500"+ x"00004000"+ x"00008011"+ 
	                    unsigned( saved_src_ip(31 downto 16)) + unsigned( saved_src_ip(15 downto  0))+
	                    unsigned(saved_dest_ip(31 downto 16)) + unsigned(saved_dest_ip(15 downto  0))
                        + 20;

              -- initialize UDP CRC with known data
              UDP_CRC <= unsigned( saved_src_ip(31 downto 16)) + unsigned( saved_src_ip(15 downto  0))+ 
                         unsigned(saved_dest_ip(31 downto 16)) + unsigned(saved_dest_ip(15 downto  0))+ 
                         x"00000011" + unsigned(saved_src_port) + unsigned(saved_dest_port);
              
	          case( pkt_index+1 ) is

	            -- when 6 | 7 =>
	            when 6 to 7 =>
                  -- put to zero the minimum packet (60 bytes = 8 words)
                  -- they will be overwritten by actual data
	              buf_di <= x"0000000000000000";
	              buf_we <= '1';
	              sm_exec_state <= PREPARE_PADDING;

	            when 8 =>
	              -- data will start from index 6
                  --pkt_index <= 6-1;
                  pkt_index <= FIRST_PAYLOAD_INDEX-1;
                  buf_we <= '0';
                  sm_exec_state <= WAIT_ENABLE;

	            when others    =>
	              sm_exec_state <= IDLE;
	                                                                                            
	          end case;
	        

            --*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

	        when WAIT_ENABLE =>
              substep <= 0;
              buf_we <= '0';
              rx_ready <= '0';
	          busy <= '0';
	          if(PKTZR_enable = '1') then
                sm_exec_state <= FILLING_PKT;
              else
                sm_exec_state <= WAIT_ENABLE;
              end if;
            
            --*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

	        when FILLING_PKT =>
	          busy <= '0';
	          rx_ready <= '1';
              substep <= 0;
	          
	          if((rx_valid='1') and (rx_ready='1')) then
	            watchdog_reset <= '1';
	            buf_we <= '1';
	            
                -- stop conditions                
	            -- TLAST is acknowledged only if input buffer is full enough
	            -- or TUSER is et to 0000_0001, signaling a forced end-of-packet request
                --
	            -- if we have a TLAST asserted, we must check TKEEP to count the valid bytes only,
	            -- even if we store the whole 64-bit word
	            -- if the TLAST is going to be ignored because input buffer is not full enough,
	            -- then all bytes are stored irrespective of TKEEP, 
	            -- meaning that we support unaligned transfer only if it's the last
	            -- putting TUSER to 0000_0001 while asserting TLAST forces an end-of-packet
	            if( ((rx_last='1') and ((UDP_length + add_length +8) > BUF_FULL_THR)) or
	                ((rx_last='1') and (rx_tuser="00000001")) or  
	                ((UDP_length + add_length +8) > MAX_PKT_DATA) 
	              ) then
	              add_length:=tkeep_decode( S_AXIS_TKEEP );
	              -- put to 0 data bytes not enabled in tkeep
	              for i0 in 7 downto 0 loop
	                if(S_AXIS_TKEEP(i0)='1') then
	                  aux_datain(i0*8+7 downto i0*8) := stream_data_in(i0*8+7 downto i0*8);
	                else
	                  aux_datain(i0*8+7 downto i0*8) := x"00";
	                end if;
	              end loop;
	              -- store tkeep value to be used for packet retransmission
	              saved_tkeep <= S_AXIS_TKEEP;
	              --
	              --saved_tuser <= S_AXIS_TUSER;
				  -- put output TUSER to 0, otherwise xxv IP thinks it's an error code
				  saved_tuser <= (others => '0');
                  saved_tid   <= S_AXIS_TID;
                  saved_tdest <= S_AXIS_TDEST;

	              sm_exec_state <= CALC_CRC;
	              rx_ready <= '0';
	            else
	              add_length:=8;
	              saved_tkeep <= saved_tkeep;    -- or also (others => '1')
	              aux_datain := stream_data_in;

	              sm_exec_state <= FILLING_PKT;
	              rx_ready <= '1';
	            end if;
	            
	            UDP_length <= UDP_length + add_length;
	            -- must do a net2host to calculate the CRC
	            UDP_CRC <= UDP_CRC 
	                       + (unsigned(aux_datain(55 downto 48)) & unsigned(aux_datain(63 downto 56)))
	                       + (unsigned(aux_datain(39 downto 32)) & unsigned(aux_datain(47 downto 40))) 
	                       + (unsigned(aux_datain(23 downto 16)) & unsigned(aux_datain(31 downto 24))) 
	                       + (unsigned(aux_datain( 7 downto  0)) & unsigned(aux_datain(15 downto  8))); 
	            pkt_index <= pkt_index +1;

                -- update buffer
	            --the_packet(pkt_index) <= aux_datain;
	            buf_di <= aux_datain;

              else     -- no valid input data available: keep waiting
                buf_we <= '0';
                -- if we are still waiting for the first data, we don't fire up the watchdog: 
                -- we just keep waiting
                if( pkt_index = (FIRST_PAYLOAD_INDEX-1) ) then
	              saved_tkeep <= saved_tkeep;
	              watchdog_reset <= '1';
	              sm_exec_state <= FILLING_PKT;
	              rx_ready <= '1';
                else 
                  -- stop conditions                
                  if( watchdog_timer = x"00000000") then
	                sm_exec_state <= CALC_CRC;
	                rx_ready <= '0';
	              else
                    sm_exec_state <= FILLING_PKT;
	                rx_ready <= '1';
	              end if;
	              saved_tkeep <= saved_tkeep;
	              -- keep the watchdog alive
	              watchdog_reset <= '0';
                end if;
	          end if;
	          
	          tx_valid <= '0';

            --*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

	        when CALC_CRC =>
	          busy <= '1';
	          buf_we <= '1';
	          rx_ready <= '0';
	          watchdog_reset <= '1';
	          
	          -- now fill headers, calculating actual lengths and CRC
	          -- already do host2net
	          -- fill one word per clock cycle [EDIT] no more: to close the timing, we use multiple
	          -- clock ticks to fill some words
	          -- note that we prepare the data for NEXT word in buffer
	          -- so word#0 is calculated in case "others", which is when the packet index
	          -- is pointing into the payload and not into the headers, that corresponds
	          -- to its value when we first enter present state "CALC_CRC" of the state machine

	          --pkt_index<= pkt_index+1;
	          case( pkt_index+1 ) is
	            
	            when 1 =>
	              pkt_word( 7 downto  0) :=  saved_src_mac(31 downto 24);
	              pkt_word(15 downto  8) :=  saved_src_mac(23 downto 16);
	              pkt_word(23 downto 16) :=  saved_src_mac(15 downto  8);
	              pkt_word(31 downto 24) :=  saved_src_mac( 7 downto  0);
	              -- ether type = 0x0800 = IPv4 datagram
	              pkt_word(39 downto 32) := x"08";
	              pkt_word(47 downto 40) := x"00";
	              --                                                    *** IP header ***
	              -- version=4;
	              -- internet header length=5 (*4=20 bytes=no options)
	              pkt_word(55 downto 48) :=  x"45";
	              -- DSCP=0; ECN=0
	              pkt_word(63 downto 56) :=  x"00";
	              --the_packet(1) <= pkt_word;
	              buf_di <= pkt_word;
	              ----------------------------------------------------
	              sm_exec_state <= CALC_CRC;
	              pkt_index<= pkt_index+1;
	              substep <= 0;

  	            when 2 =>
                  -- IP length
                  len_aux := to_unsigned(UDP_length,16) + 20;
                  pkt_word( 7 downto  0) := std_logic_vector(len_aux(15 downto  8));
                  pkt_word(15 downto  8) := std_logic_vector(len_aux( 7 downto  0));
  	              -- identification = 0 (no fragmentation)
  	              pkt_word( 31 downto 16) := x"0000";
  	              -- flags=2, fragment offset=0
  	              pkt_word(47 downto 32) := x"0040";
  	              -- time to live=128
  	              pkt_word(55 downto 48) :=  x"80";
  	              -- protocol = 0x11 = UDP
  	              pkt_word(63 downto 56) :=  x"11";
  	              --the_packet(2) <= pkt_word;
  	              buf_di <= pkt_word;
  	              ----------------------------------------------------
  	              sm_exec_state <= CALC_CRC;
  	              pkt_index<= pkt_index+1;
  	              substep <= 0;

	            when 3 =>
	              -- IP CRC
                  -- IP CRC was initialized in the PREPARE_PADDING state: now add length only
                  CRC_aux := IP_CRC + to_unsigned(UDP_length,16);
                  CRC_aux := resize( CRC_aux(31 downto 16) + CRC_aux(15 downto 0) ,32);
                  CRC_aux := not CRC_aux;	          
                  pkt_word( 7 downto  0) := std_logic_vector(CRC_aux(15 downto  8));
                  pkt_word(15 downto  8) := std_logic_vector(CRC_aux( 7 downto  0));
	              -- SRC IP
	              pkt_word(23 downto 16) := saved_src_ip(31 downto 24);
	              pkt_word(31 downto 24) := saved_src_ip(23 downto 16);
	              pkt_word(39 downto 32) := saved_src_ip(15 downto  8);
	              pkt_word(47 downto 40) := saved_src_ip( 7 downto  0);
	              -- DEST IP
	              pkt_word(55 downto 48) := saved_dest_ip(31 downto 24);
	              pkt_word(63 downto 56) := saved_dest_ip(23 downto 16);
	              --the_packet(3) <= pkt_word;
	              buf_di <= pkt_word;
	              ----------------------------------------------------
	              sm_exec_state <= CALC_CRC;
	              pkt_index<= pkt_index+1;
	              substep <= 0;
	            
	            when 4 =>
	              pkt_word( 7 downto  0) := saved_dest_ip(15 downto  8);
	              pkt_word(15 downto  8) := saved_dest_ip( 7 downto  0);
	              --                                                    *** UDP HEADER ***
	              -- SRC Port
	              pkt_word(23 downto 16) :=  saved_src_port(15 downto  8);
	              pkt_word(31 downto 24) :=  saved_src_port( 7 downto  0);
	              -- DEST Port
	              pkt_word(39 downto 32) := saved_dest_port(15 downto  8);
	              pkt_word(47 downto 40) := saved_dest_port( 7 downto  0);
	              -- UDP length
                  len_aux := to_unsigned(UDP_length,16);
                  pkt_word(55 downto 48) := std_logic_vector(len_aux(15 downto  8));
                  pkt_word(63 downto 56) := std_logic_vector(len_aux( 7 downto  0));
	              --the_packet(4) <= pkt_word;
	              buf_di <= pkt_word;
	              ----------------------------------------------------
	              sm_exec_state <= CALC_CRC;
	              pkt_index<= pkt_index+1;
	              substep <= 0;
	            
	            when 5 =>
	              -- UDP CRC
                  -- UDP CRC was initialized in the PREPARE_PADDING state: now add length and pkt_counter
                  -- note that, for CRC calculation, pkt counter must not get a host2net
                  -- split CRC calculation into 2 steps to close timing
                  if(substep=0) then
                    substep <= 1;
                    pkt_index<= pkt_index;  -- do not increment packet index during substeps
                    len_aux := to_unsigned(UDP_length,16);
					-- split CRC sum into partial sums fr timing closure
                    -- UDP length will be added twice for IP pseudo header
                    partial1 <= UDP_CRC + 2*len_aux + pkt_counter(39 downto 24);
					partial2 <= (x"0000" & pkt_counter(23 downto  8)) + (x"0000" & pkt_counter( 7 downto  0) & unsigned(saved_tid));
                  else
                    substep <= 0;  -- reset substep counter
                    pkt_index<= pkt_index+1;
					CRC_aux := partial1 + partial2;
	                CRC_aux := resize( UDP_CRC(31 downto 16) + UDP_CRC(15 downto 0) ,32);
	                CRC_aux := not CRC_aux;
                    pkt_word( 7 downto  0) := std_logic_vector(CRC_aux(15 downto  8));
                    pkt_word(15 downto  8) := std_logic_vector(CRC_aux( 7 downto  0));
  	                -- pad with 5 bytes (0x00) + 1 byte of ID, so we are 64-bit aligned
	                --pkt_word(55 downto 16) := x"0000000000";
	                -- replace with a 5-byte counter + 1 byte of ID, so we are 64-bit aligned
	                -- and the packet counter helps detecting lost packets on the receiving side
	                -- remember to make a host2net of the counter for transmission
                    pkt_word(23 downto 16) := std_logic_vector(pkt_counter(39 downto 32));
                    pkt_word(31 downto 24) := std_logic_vector(pkt_counter(31 downto 24));
                    pkt_word(39 downto 32) := std_logic_vector(pkt_counter(23 downto 16));
                    pkt_word(47 downto 40) := std_logic_vector(pkt_counter(15 downto  8));
	                pkt_word(55 downto 48) := std_logic_vector(pkt_counter( 7 downto  0));
	                pkt_word(63 downto 56) := saved_tid;
	                --the_packet(5) <= pkt_word;
	                buf_di <= pkt_word;
	                ----------------------------------------------------
	              end if;
	              sm_exec_state <= CALC_CRC;
	              
                when 6 =>
	              pkt_index <= 0;
	              substep <= 0;
	              buf_we <= '0';
	              buf_init <= '1';
                  -- BRAM out has 1 clock cycle of latency
                  tx_valid <= '0';
                  tx_last <= '0';
                  -- output stream data bus is already connected to BRAM out
                  sm_exec_state <= INIT_TXBUF;

	            when others    =>
                  -- NOTE!!! THIS IS THE FIRST ITERATION EXECUTED IN STATE "CALC_CRC"
                  -- save index of last packet word
                  -- there is a minimum ethernet frame; we already prepared a zero padding in the packet when
                  -- filling the headers in IDLE state; now we just need to check the length
                  if( pkt_index < MIN_PKT_INDEX ) then
                    last_pkt_index <= MIN_PKT_INDEX;
                    saved_tkeep <= (others => '1');
                  else
                    last_pkt_index <= pkt_index;
                    saved_tkeep <= saved_tkeep;
                  end if;
                  
	              --                                                    *** ethernet frame header ***
                  -- dest MAC
                  pkt_word( 7 downto  0) := saved_dest_mac(47 downto 40);
                  pkt_word(15 downto  8) := saved_dest_mac(39 downto 32);
                  pkt_word(23 downto 16) := saved_dest_mac(31 downto 24);
                  pkt_word(31 downto 24) := saved_dest_mac(23 downto 16);
                  pkt_word(39 downto 32) := saved_dest_mac(15 downto  8);
                  pkt_word(47 downto 40) := saved_dest_mac( 7 downto  0);
                  -- src MAC
                  pkt_word(55 downto 48) :=  saved_src_mac(47 downto 40);
                  pkt_word(63 downto 56) :=  saved_src_mac(39 downto 32);
                  --the_packet(0) <= pkt_word;
                  buf_di <= pkt_word;
                  pkt_index<= 0;
                  substep <= 0;
                  ----------------------------------------------------
                  sm_exec_state <= CALC_CRC;
	                                                                                            
	          end case;

            --*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

	        when INIT_TXBUF =>
	          busy <= '1';
	          buf_init <= '0';
              tx_valid <= '1';
	          pkt_index <= 1;
	          pkt_counter <= pkt_counter+1;
              sm_exec_state <= TRANSMITTING_PKT;

            --*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

	        when TRANSMITTING_PKT =>
	          -- remember that BRAM buffer adds a latency of 1 clk cycle
              -- output stream data bus is already connected to BRAM out
              -- and BRAM module samples TREADY of the output stream, 
              -- to promptly react in case of its deassertion
              -- when we first enter this state, BRAM is already outputting word #0
              -- and pkt_index is already pointing to word #1
	          busy <= '1';
	          buf_init <= '0';
	          buf_we <= '0';
	          rx_ready <= '0';
              tx_valid <= '1';
	          watchdog_reset <= '1';

	          if( tx_ready='1' ) then
  	            if( pkt_index = last_pkt_index ) then
  	              pkt_index <= 0;
  	              tx_last <= '1';
  	              internal_tkeep <= saved_tkeep;
	              sm_exec_state <= IDLE;
                else
                  pkt_index <= pkt_index +1;
  	              tx_last <= '0';
  	              internal_tkeep <= (others => '1');
	              sm_exec_state <= TRANSMITTING_PKT;
                end if;
	          else
	            -- stream receiver not ready
	            pkt_index <= pkt_index;
	            sm_exec_state <= TRANSMITTING_PKT;
	          end if;
	          

            --*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

	        when others    =>
	          sm_exec_state <= IDLE;                                                           
	                                                                                            
	      end case;
	    end if;
	  end if;
	end process state_machine;


	watchdog: process(M_AXIS_ACLK)
	begin
	  if (rising_edge (M_AXIS_ACLK)) then
	    if(watchdog_reset = '1') then                                                           
	      watchdog_timer <= unsigned(WATCHDOG_TIMEOUT);
	    else
	      if(watchdog_timer /= x"00000000") then
	        watchdog_timer <= watchdog_timer -1;
	      else
	        watchdog_timer <= x"00000000";
	      end if;  -- if expired
	    end if;  -- if not reset
      end if; -- if clock edge
	end process watchdog;




end implementation;
