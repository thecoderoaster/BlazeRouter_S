----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:49:39 06/04/2011 
-- Design Name: 
-- Module Name:    ControlUnit - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.router_library.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ControlUnit is
	generic(dp_size		: natural;
			  address_size : natural;
			  rte_size		: natural;
			  sch_size		: natural);
	port(
			clk				   : in 	std_logic;
			rst					: in 	std_logic;
			rte_data_in			: in 	std_logic_vector (rte_size-1 downto 0);
			rte_data_out		: out std_logic_vector (rte_size-1 downto 0);
			sch_data_in			: in 	std_logic_vector (sch_size-1 downto 0);
			sch_data_out		: out std_logic_vector (sch_size-1 downto 0);
			address				: out std_logic_vector (address_size-1 downto 0);
			rte_en				: out std_logic;
			sch_en 				: out std_logic;
			n_vc_deq 			: out std_logic;
			n_vc_rnaSelI 		: out std_logic_vector (1 downto 0);		 
			n_vc_rnaSelO 		: out std_logic_vector (1 downto 0);		
			n_vc_rnaSelS		: out	std_logic_vector (1 downto 0);		
			n_vc_strq 			: out std_logic;									
			n_vc_status 		: in 	std_logic_vector (1 downto 0);		
			e_vc_deq 			: out std_logic;									
			e_vc_rnaSelI 		: out std_logic_vector (1 downto 0);		
			e_vc_rnaSelO 		: out std_logic_vector (1 downto 0);		 
			e_vc_rnaSelS		: out	std_logic_vector (1 downto 0);
			e_vc_strq 			: out std_logic;
			e_vc_status 		: in 	std_logic_vector (1 downto 0);
			s_vc_deq 			: out std_logic;							
			s_vc_rnaSelI 		: out std_logic_vector (1 downto 0); 
			s_vc_rnaSelO 		: out std_logic_vector (1 downto 0); 
			s_vc_rnaSelS		: out	std_logic_vector (1 downto 0);
			s_vc_strq 			: out std_logic;							
			s_vc_status 		: in 	std_logic_vector (1 downto 0);
			w_vc_deq 			: out std_logic;
			w_vc_rnaSelI 		: out std_logic_vector (1 downto 0); 
			w_vc_rnaSelO 		: out std_logic_vector (1 downto 0); 
			w_vc_rnaSelS		: out	std_logic_vector (1 downto 0);
			w_vc_strq 			: out std_logic;
			w_vc_status 		: in 	std_logic_vector (1 downto 0);
			n_CTRflg				: out std_logic;
			n_DataFlg			: in 	std_logic;
			n_rnaData			: in 	std_logic_vector(dp_size-1 downto 0);
			e_CTRflg				: out std_logic;
			e_DataFlg			: in 	std_logic;
			e_rnaData			: in 	std_logic_vector(dp_size-1 downto 0);
			s_CTRflg				: out std_logic;
			s_DataFlg			: in 	std_logic;
			s_rnaData			: in 	std_logic_vector(dp_size-1 downto 0);
			w_CTRflg				: out std_logic;
			w_DataFlg			: in 	std_logic;
			w_rnaData			: in 	std_logic_vector(dp_size-1 downto 0);
			sw_nSel				: out std_logic_vector(2 downto 0);
			sw_eSel				: out std_logic_vector(2 downto 0);
			sw_sSel				: out std_logic_vector(2 downto 0);
			sw_wSel				: out std_logic_vector(2 downto 0);
			sw_ejectSel			: out std_logic_vector(2 downto 0);
			sw_rnaDtFl			: in 	std_logic;
			rna_dataPkt			: out std_logic_vector(dp_size-1 downto 0);
			injt_dataPkt		: in 	std_logic_vector (dp_size-1 downto 0)
		);
end ControlUnit;

architecture Behavioral of ControlUnit is
	type state_type is (start, north1, north2, north3, north4,
							  east1, east2, east3, east4,
							  south1, south2, south3, south4,
							  west1, west2, west3, west4,
							  injection1, injection2, injection3, injection4, injection5,
							  injection6, injection7,
							  departure1, departure2, departure3, departure4);   -- State FSM
	signal state, next_state : state_type;
	
	signal router_address 	: std_logic_vector(address_size-1 downto 0);
	
	--Departure Itinerary
	signal next_pkt_in_vcc					: std_logic_vector(2 downto 0);
	signal next_pkt_in_vcell				: std_logic_vector(1 downto 0);

begin
	
	--cpStateHandler_process: These processes below are responsible for assigning the next_state

	process
	begin
		wait until rising_edge(clk);
		if rst = '1' then
			state <= start;
		else
			state <= next_state;
		end if;
	end process;
	
	process(state)
		  
		--Memory Related Variables (Routing/Reservation/Scheduler)
		variable w_address 			: std_logic_vector(address_size-1 downto 0);
		variable r_address			: std_logic_vector(address_size-1 downto 0);
		variable reserved_cnt		: std_logic_vector(address_size-1 downto 0);
		variable table_full 			: std_logic;
	
		begin
			case state is
				when start =>
					--Reset state
					w_address := std_logic_vector(to_unsigned(0, w_address'length));
					r_address := std_logic_vector(to_unsigned(0, r_address'length));
					reserved_cnt := std_logic_vector(to_unsigned(0, reserved_cnt'length));
					table_full := '0';
					
					router_address <= std_logic_vector(to_unsigned(0, router_address'length));
					next_pkt_in_vcc <= std_logic_vector(to_unsigned(0, next_pkt_in_vcc'length));
					next_pkt_in_vcell <= std_logic_vector(to_unsigned(0, next_pkt_in_vcell'length));
			
					rte_en <= '0';
					sch_en <= '0';
					
					next_state <= north1;
	--*NORTH*--
				when north1 =>
					--Check flag
					if(n_DataFlg = '1') then
						next_state <= north2;
					else
						next_state <= east1;
					end if;
				when north2 =>
					if(table_full = '0') then
						next_state <= north3;
					else
						next_state <= east1;
					end if;
				when north3 =>	
					--Schedule the incoming data packet
					--Ack!
					n_CTRflg <= '1', '0' after 1 ns;
					--Write bits to sch_data_out
					sch_data_out <= "000" & n_rnaData(8 downto 2);
					
					--Control VCC
					n_vc_rnaSelI <= n_rnaData(7 downto 6);			--Value from DIR bits
					
					--Send to scheduled table
					address <= w_address;
					sch_en <= '1';
					next_state <= north4;
				when north4 =>
					w_address := w_address + 1;
					reserved_cnt := reserved_cnt + 1;
					
					--Check table space
					if(reserved_cnt <= "1110") then
						table_full := '0';
					else
						table_full := '1';
					end if;
					
					sch_en <= '0';
					next_state <= east1;
	--*EAST*--				
				when east1 =>
					--Check flag
					if(s_DataFlg = '1') then
						next_state <= east2;
					else
						next_state <= south1;
					end if;
				when east2 =>
					if(table_full = '0') then
						next_state <= east3;
					else
						next_state <= south1;
					end if;
				when east3 =>	
					--Schedule the incoming data packet
					--Ack!
					e_CTRflg <= '1', '0' after 1 ns;
					--Write bits to sch_data_out
					sch_data_out <= "001" & e_rnaData(8 downto 2);
					
					--Control VCC
					e_vc_rnaSelI <= e_rnaData(7 downto 6);			--Value from DIR bits
		
					--Send to scheduled table
					address <= w_address;
					sch_en <= '1';
					next_state <= east4;
				when east4 =>
					w_address := w_address + 1;
					reserved_cnt := reserved_cnt + 1;
					
					--Check table space
					if(reserved_cnt <= "1110") then
						table_full := '0';
					else
						table_full := '1';
					end if;
					
					sch_en <= '0';
					next_state <= south1;	
	--*SOUTH*--
				when south1 =>
					--Check flag
					if(s_DataFlg = '1') then
						next_state <= south2;
					else
						next_state <= west1;
					end if;
				when south2 =>
					if(table_full = '0') then
						next_state <= south3;
					else
						next_state <= west1;
					end if;
				when south3 =>	
					--Schedule the incoming data packet
					--Ack!
					s_CTRflg <= '1', '0' after 1 ns;
					--Write bits to sch_data_out
					sch_data_out <= "010" & s_rnaData(8 downto 2);
					
					--Control VCC
					s_vc_rnaSelI <= s_rnaData(7 downto 6);			--Value from DIR bits
					
					--Send to scheduled table
					address <= w_address;
					sch_en <= '1';
					next_state <= south4;
				when south4 =>
					w_address := w_address + 1;
					reserved_cnt := reserved_cnt + 1;
					
					--Check table space
					if(reserved_cnt <= "1110") then
						table_full := '0';
					else
						table_full := '1';
					end if;
					
					sch_en <= '0';
					next_state <= west1;	
	--*WEST*--
				when west1 =>
					--Check flag
					if(w_DataFlg = '1') then
						next_state <= west2;
					else
						next_state <= injection1;
					end if;
				when west2 =>
					if(table_full = '0') then
						next_state <= west3;
					else
						next_state <= injection1;
					end if;
				when west3 =>	
					--Schedule the incoming data packet
					--Ack!
					w_CTRflg <= '1', '0' after 1 ns;
					--Write bits to sch_data_out
					sch_data_out <= "011" & w_rnaData(8 downto 2);
					
					--Control VCC
					w_vc_rnaSelI <= w_rnaData(7 downto 6);			--Value from DIR bits
					
					--Send to scheduled table
					address <= w_address;
					sch_en <= '1';
					next_state <= west4;
				when west4 =>
					w_address := w_address + 1;
					reserved_cnt := reserved_cnt + 1;
					
					--Check table space
					if(reserved_cnt <= "1110") then
						table_full := '0';
					else
						table_full := '1';
					end if;
					
					sch_en <= '0';
					next_state <= injection1;
	--*INJECTION*--
				when injection1 =>
					--Check flag
					if(sw_rnaDtFl = '1') then
						next_state <= injection2;
					else
						next_state <= departure1;
					end if;
				when injection2 =>
					case injt_dataPkt(1 downto 0) is
						when "00" =>
							next_state <= injection3;	-- Condition: Normal Packet
						when "01" =>
							next_state <= injection4;	-- Condition: PE is re/assigning addresses
						when "10" =>
							next_state <= injection5;	-- Condition: PE is updating Routing Table
						when others =>
							next_state <= departure1;	-- Condition: Unknown, move to next state.
					end case;
				when injection3 =>
					if(table_full = '0') then
						next_state <= injection6;
					else
						next_state <= departure1;
					end if;
				when injection4 =>
					router_address <= injt_dataPkt(12 downto 9);
					next_state <= departure1;
				when injection5 =>
					address <= injt_dataPkt(12 downto 9);
					rte_data_out <= injt_dataPkt(15 downto 13);
					rte_en <= '1';
					next_state <= departure1;
				when injection6 =>	
					--Schedule the incoming data packet
					--Write bits to sch_data_out
					sch_data_out <= "111" & injt_dataPkt(8 downto 2);
					
					--Send to scheduled table
					address <= w_address;
					sch_en <= '1';
					next_state <= injection7;
				when injection7 =>
					w_address := w_address + 1;
					reserved_cnt := reserved_cnt + 1;
					
					--Check table space
					if(reserved_cnt <= "1110") then
						table_full := '0';
					else
						table_full := '1';
					end if;
					
					sch_en <= '0';
					next_state <= departure1;	
	--*DEPARTURE*--
				when departure1 =>
					if(r_address /= w_address) then
						next_state <= departure2;
					else
						next_state <= north1;
					end if;
				when departure2 =>
					--Grab the next item from the scheduled table
					address <= r_address;
					sch_en <= '0';
					next_state <= departure3;
				when departure3 =>
					next_pkt_in_vcc <= sch_data_in(9 downto 7);
					next_pkt_in_vcell <= sch_data_in(5 downto 4);
					
					--Grab Routing Information for switch
					address <= sch_data_in(3 downto 0);
					rte_en <= '0';
					next_state <= departure4;
				when departure4 =>
					--Use the routing table info saved in next_pkt_departing_from_gate to control VCC
					case next_pkt_in_vcc is
						when "000" =>
							n_vc_rnaSelO <= next_pkt_in_vcell;			-- "00" North FIFO 
							n_vc_deq <= '1', '0' after 1 ns;
							sw_nSel <= rte_data_in;									
						when "001" =>
							e_vc_rnaSelO <= next_pkt_in_vcell;			-- "01" East FIFO
							e_vc_deq <= '1', '0' after 1 ns;
							sw_eSel <= rte_data_in;
						when "010" =>
							s_vc_rnaSelO <= next_pkt_in_vcell;			-- "10" South FIFO
							s_vc_deq <= '1', '0' after 1 ns;
							sw_sSel <= rte_data_in;
						when "011" =>
							w_vc_rnaSelO <= next_pkt_in_vcell;			-- "11" West FIFO
							w_vc_deq <= '1', '0' after 1 ns;
							sw_wSel <= rte_data_in;
						when others =>											-- TO DO: Handle Ejection
							null;
					end case;
							
					
					--Check CTR going high to low
					--wait until falling_edge(n_CTRflg);
					
					--Update Space in Reservation Table now that packet has departed
					r_address := r_address + 1;
					reserved_cnt := reserved_cnt - 1;
					
					--Check table space
					if(reserved_cnt <= "1110") then
						table_full := '0';
					else
						table_full := '1';
					end if;
					
					next_state <= north1;
				when others =>
					null;
		end case;
	end process;
end Behavioral;

