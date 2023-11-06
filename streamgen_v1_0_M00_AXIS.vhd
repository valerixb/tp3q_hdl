library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity streamgen_v1_0_M00_AXIS is
	generic (
		C_M_AXIS_TDATA_WIDTH  : integer	:= 64;
		C_M_AXIS_TUSER_WIDTH  : integer	:= 1;
		C_M_AXIS_TID_WIDTH    : integer	:= 8;
		C_M_AXIS_TDEST_WIDTH  : integer	:= 4;
		-- width of command registers coming from control axi-lite interface
		C_S_AXIlite_DATA_WIDTH	  : integer	:= 32
	);
	port (
        start_strobe                  : in std_logic;
        stop_strobe                   : in std_logic;
	    STREAM_generating             : out std_logic;
        STREAM_completed_repetitions  : out std_logic_vector(C_S_AXIlite_DATA_WIDTH-1 downto 0);
	    AXI_start_generation          : in  std_logic;
	    AXI_stop_generation           : in  std_logic;
	    AXI_ext_trig_enable           : in  std_logic;
	    AXI_generator_mode            : in  std_logic_vector(C_S_AXIlite_DATA_WIDTH-1 downto 0);
	    AXI_generator_seed            : in  std_logic_vector(C_S_AXIlite_DATA_WIDTH-1 downto 0);
	    AXI_stream_length             : in  std_logic_vector(C_S_AXIlite_DATA_WIDTH-1 downto 0);
	    AXI_tot_repetitions           : in  std_logic_vector(C_S_AXIlite_DATA_WIDTH-1 downto 0);
	    AXI_rest_ticks                : in  std_logic_vector(C_S_AXIlite_DATA_WIDTH-1 downto 0);
		-- 
		M_AXIS_ACLK	                  : in std_logic;
		M_AXIS_ARESETN	              : in std_logic;
		M_AXIS_TVALID	              : out std_logic;
		M_AXIS_TDATA	              : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		M_AXIS_TSTRB	              : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		M_AXIS_TKEEP	              : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		M_AXIS_TUSER	              : out std_logic_vector(C_M_AXIS_TUSER_WIDTH-1 downto 0);
		M_AXIS_TID   	              : out std_logic_vector(C_M_AXIS_TID_WIDTH-1 downto 0);
		M_AXIS_TDEST   	              : out std_logic_vector(C_M_AXIS_TDEST_WIDTH-1 downto 0);
		M_AXIS_TLAST	              : out std_logic;
		M_AXIS_TREADY	              : in std_logic
	);
end streamgen_v1_0_M00_AXIS;

architecture implementation of streamgen_v1_0_M00_AXIS is

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

    -- decode number of final bytes for stream length not multiple of 8 bytes
	function tkeep_decode (len_remainder : std_logic_vector ) return std_logic_vector is                  
	 	variable d  : std_logic_vector(7 downto 0);                                       
	 begin           
	   case len_remainder is
	     when  "000" => d := "11111111";
	     when  "001" => d := "00000001";
	     when  "010" => d := "00000011";
	     when  "011" => d := "00000111";
	     when  "100" => d := "00001111";
	     when  "101" => d := "00011111";
	     when  "110" => d := "00111111";
	     when  "111" => d := "01111111";
	     when others => d := "11111111";
	   end case;    
	   return(d);        	                                              
	 end;                                                                    


	-- State machine                                             
	type state is ( WAIT_TRIGGER,
	                INIT_COUNTER,
	                SEND_STREAM,
	                INIT_REST,
	                DO_REST);                               
	signal  sm_exec_state : state;                                                   

    constant MAXCOUNT : integer := 65535;
	signal p0, p1, p2, p3 : integer range 0 to MAXCOUNT;
	
	signal axis_tvalid	                : std_logic;
	signal axis_tlast	                : std_logic;
	signal stream_data_out	            : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
	signal tx_done	                    : std_logic;
    signal start_strobe_dly             : std_logic;
    signal stop_strobe_dly              : std_logic;
    signal AXI_start_generation_dly     : std_logic;
    signal AXI_stop_generation_dly      : std_logic;
	signal internal_tkeep               : std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
	signal latched_AXI_stream_length    : unsigned(C_S_AXIlite_DATA_WIDTH-1 downto 0);
	signal stream_counter               : unsigned(C_S_AXIlite_DATA_WIDTH-1 downto 0);
	signal latched_tkeep                : std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
	signal generating                   : std_logic;
    signal completed_repetitions        : integer;
	signal latched_tot_rep              : integer;
	signal latched_rest_ticks           : integer;
	signal rest_counter                 : integer;
	signal terminate_generation         : std_logic;


begin

	M_AXIS_TVALID	<= axis_tvalid;
	M_AXIS_TDATA	<= stream_data_out;
	M_AXIS_TLAST	<= axis_tlast;
    M_AXIS_TUSER	<= (others => '0');
	M_AXIS_TID   	<= (others => '0');
	M_AXIS_TDEST   	<= (others => '0');
	M_AXIS_TSTRB	<= internal_tkeep;
	M_AXIS_TKEEP	<= internal_tkeep;
    STREAM_generating <= generating;
    STREAM_completed_repetitions <= std_logic_vector(to_unsigned(completed_repetitions,C_S_AXIlite_DATA_WIDTH));

    -- delayed copies for edge detection
	process(M_AXIS_ACLK)                                                                           
	begin                                                                                          
	  if (rising_edge (M_AXIS_ACLK)) then                                                          
	    if(M_AXIS_ARESETN = '0') then                                                              
	      start_strobe_dly          <= '0';
	      stop_strobe_dly           <= '0';
	      AXI_start_generation_dly  <= '0';
	      AXI_stop_generation_dly   <= '0';
	    else
	      start_strobe_dly         <= start_strobe;                                                                               
	      stop_strobe_dly          <= stop_strobe;
	      AXI_start_generation_dly <= AXI_start_generation;                                                                               
	      AXI_stop_generation_dly  <= AXI_stop_generation;
	    end if;
	  end if;
	end process;

    -- listen to stop command and latch it 
	process(M_AXIS_ACLK)                                                                           
	begin                                                                                          
	  if (rising_edge (M_AXIS_ACLK)) then                                                          
	    if(M_AXIS_ARESETN = '0') then                                                              
	      terminate_generation <= '0';
	    else
	      if (sm_exec_state = WAIT_TRIGGER) then
  	        -- reset when waiting for next trigger
	        terminate_generation <= '0';
	      else
	        if ( (stop_strobe_dly='0' and stop_strobe='1' and AXI_ext_trig_enable='1') or
	             (AXI_stop_generation_dly='0' and  AXI_stop_generation='1') ) then
	          terminate_generation <= '1';
	        else
	          terminate_generation <= terminate_generation;
	        end if;
	      end if;	    
	    end if;
	  end if;
    end process;
	                                                                                               
	-- Control state machine                                               
	process(M_AXIS_ACLK)                                                                        
	begin                                                                                       
	  if (rising_edge (M_AXIS_ACLK)) then                                                       
	    if(M_AXIS_ARESETN = '0') then                                                           
	      sm_exec_state      <= WAIT_TRIGGER;
	      latched_AXI_stream_length <= (others => '0');
	      latched_tkeep <= (others => '1');
          generating <= '0';
          completed_repetitions <= 0;
	    else                                                                                    
	      case (sm_exec_state) is                                                              
	        when WAIT_TRIGGER =>
	          if ( (start_strobe_dly='0' and start_strobe='1' and AXI_ext_trig_enable='1') or
	               (AXI_start_generation_dly='0' and  AXI_start_generation='1') ) then
	            sm_exec_state  <= INIT_COUNTER;
	          else
	            sm_exec_state  <= WAIT_TRIGGER;
	          end if;
	                                                                                               
	        when INIT_COUNTER  =>
              latched_tot_rep    <= to_integer(unsigned(AXI_tot_repetitions));
              latched_rest_ticks <= to_integer(unsigned(AXI_rest_ticks));
              completed_repetitions <= 0;
	          latched_AXI_stream_length <= unsigned(AXI_stream_length);
              latched_tkeep <= tkeep_decode(AXI_stream_length(2 downto 0));
              generating <= '1';
	          sm_exec_state  <= SEND_STREAM;

	        when SEND_STREAM  =>                                                                
	          if (tx_done = '1') then
	            sm_exec_state <= INIT_REST;                                                         
	          else                                                                              
	            sm_exec_state <= SEND_STREAM;                                                  
	          end if;                                                                           
	                                                                                            
	        when INIT_REST  =>                                                                
	          rest_counter <= 0;
	          sm_exec_state <= DO_REST;

	        when DO_REST  =>                                                                
	          if(rest_counter < latched_rest_ticks) then
	            -- keep resting
	            rest_counter <= rest_counter+1;
	            sm_exec_state <= DO_REST;
	          else
	            -- rest period expired
	            rest_counter <= 0;
                completed_repetitions <= completed_repetitions +1;

	            if ( ( (completed_repetitions < latched_tot_rep-1) or (latched_tot_rep=0) )
	                    and (terminate_generation='0') ) then
                  -- do another iteration
	              sm_exec_state <= SEND_STREAM;
	            else
	              -- I don't reset completed_repetitions until next trigger
	              generating <= '0';
	              sm_exec_state <= WAIT_TRIGGER;
	            end if;

	          end if;

	        when others    =>                                                                   
	          sm_exec_state <= WAIT_TRIGGER;                                                           
	                                                                                            
	      end case;                                                                             
	    end if;                                                                                 
	  end if;                                                                                   
	end process;                                                                                


    -- generate output pattern
    -- one case only is implemented, so I do not check AXI_generator_mode
    -- and I don't use AXI_generator_seed
	process(M_AXIS_ACLK)
	variable p0d, p1d, p2d, p3d : std_logic_vector(15 downto 0);
	variable islast : boolean;
	begin                                                                            
	  if (rising_edge (M_AXIS_ACLK)) then
	    if(M_AXIS_ARESETN = '0') then                                                
	      p0 <= 0;
	      p1 <= 1;
	      p2 <= 2;
	      p3 <= 3;
	      axis_tvalid <= '0';
	      axis_tlast  <= '0';
	      tx_done  <= '0';               
          -- stream_data_out <= std_logic_vector(to_unsigned(0,C_M_AXIS_TDATA_WIDTH));
          stream_data_out <= X"0300_0200_0100_0000";   -- prepare first word for next stream
          internal_tkeep <= (others => '1');
          stream_counter <= to_unsigned(8,C_S_AXIlite_DATA_WIDTH);
	    else
          -- last word in stream?
          --islast := ((p3+1)*2 >= latched_AXI_stream_length );
          islast := (stream_counter >= latched_AXI_stream_length );

	      if((sm_exec_state = SEND_STREAM) and (tx_done='0'))then
            axis_tvalid <= '1';
            tx_done  <= '0';
            -- if this is the last packet and TLAST was not sasserted, it means that it's the case of a stream 
            -- length of one word only: let's raise TLAST
            if( (islast=true) and (axis_tlast='0') ) then
	          axis_tlast <= '1';
	          internal_tkeep <= latched_tkeep;
	        end if;
            
            if (axis_tvalid='1' and M_AXIS_TREADY='1') then
              if( islast=true ) then
                tx_done  <= '1';
	            axis_tvalid <= '0';
	            axis_tlast  <= '0';
                p0 <= 0;
	            p1 <= 1;
	            p2 <= 2;
	            p3 <= 3;
   	            stream_data_out <= X"0300_0200_0100_0000";   -- prepare first word for next stream
                internal_tkeep <= (others => '1');
              else
                -- prepare next word
                stream_counter <= stream_counter+8;
	            p0 <= p0+4;
	            p1 <= p1+4;
	            p2 <= p2+4;
	            p3 <= p3+4;
	            p0d:= std_logic_vector(to_unsigned(p0+4,16));
	            p1d:= std_logic_vector(to_unsigned(p1+4,16));
                p2d:= std_logic_vector(to_unsigned(p2+4,16));
                p3d:= std_logic_vector(to_unsigned(p3+4,16));
                -- build up pattern: it's a 16-bit counter
	            -- remember we do a host2net on the output data
	            stream_data_out( 7 downto  0) <= p0d(15 downto 8);  
	            stream_data_out(15 downto  8) <= p0d( 7 downto 0);
                stream_data_out(23 downto 16) <= p1d(15 downto 8);
                stream_data_out(31 downto 24) <= p1d( 7 downto 0);
	            stream_data_out(39 downto 32) <= p2d(15 downto 8);
	            stream_data_out(47 downto 40) <= p2d( 7 downto 0);
	            stream_data_out(55 downto 48) <= p3d(15 downto 8);
	            stream_data_out(63 downto 56) <= p3d( 7 downto 0);
	            -- prepare TLAST for next word
                --if ( (p3+5)*2 >= latched_AXI_stream_length ) then
                if ( (stream_counter+8) >= latched_AXI_stream_length ) then
  	              axis_tlast <= '1';
  	              internal_tkeep <= latched_tkeep;
  	            else
  	              axis_tlast <= '0';
  	              internal_tkeep <= (others => '1');
  	            end if;
	          end if;
            end if;
            
	      else       -- if send stream
	        stream_data_out <= X"0300_0200_0100_0000";   -- prepare first word for next stream
            p0 <= 0;
	        p1 <= 1;
	        p2 <= 2;
	        p3 <= 3;
	        axis_tvalid <= '0';
	        axis_tlast  <= '0';
	        tx_done  <= '0';               
            internal_tkeep <= (others => '1');
            stream_counter <= to_unsigned(8,C_S_AXIlite_DATA_WIDTH);
	      end if;    -- if send stream
	                                                        
	    end  if;    -- if not reset
	  end  if;    -- if rising edge
	end process;                                                                     



end implementation;
