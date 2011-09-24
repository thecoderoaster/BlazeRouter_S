----------------------------------------------------------------------------------
-- Company:			 University of Nevada, Las Vegas 
-- Engineer: 		 Krikor Hovasapian (ECE Graduate Student)
-- 					 Kareem Matariyeh (ECE Graduate Student)
-- Create Date:    18:47:06 03/15/2011 
-- Design Name: 	 BlazeRouter
-- Module Name:    flow_control - fc_4 
-- Project Name: 	 BlazeRouter_s
-- Description: 	 individual flow control for one direction in
--
-- Dependencies: 
--						 None
-- Revision: 
-- 					 Revision 0.01 - File Created
--						 Revision 0.02 - Created entity outline (KM)
--                 Revision 0.03 - Created implmentation code (KM)
--						 Revision 0.04	- Changed implmentation (KM)
--						 Revision 0.05 - Changed statments to line up with blazerouter_s
--											  requirements (KM)
-- Additional Comments: 
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.router_library.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity flow_control is
	Port (  fc_CTRflg			: in		STD_LOGIC;									-- Clear To Recieve flag (from RNA)
			  fc_dataIn 		: in  	STD_LOGIC_VECTOR (WIDTH downto 0); 	-- Input data port (from neighbor)
           fc_dStrb 			: in  	STD_LOGIC;									-- Data strobe (from neighbor)
           fc_vcFull 		: in  	STD_LOGIC;									-- Full status flag (from VC)
			  fc_vcData 		: out  	STD_LOGIC_VECTOR (WIDTH downto 0);	-- Data port (to VC)
           fc_rnaCtrl	 	: out  	STD_LOGIC_VECTOR (WIDTH downto 0);	-- Data port (to RNA)
           fc_pktStrb	 	: out  	STD_LOGIC;									-- Packet strobe (to RNA)
			  fc_CTR				: out		STD_LOGIC;									-- Clear to Recieve (to neighbor)
           fc_vcEnq 			: out  	STD_LOGIC);									-- enqueue command from RNA (to VC)
end flow_control;

architecture fc_4 of flow_control is

	signal dStrbInd	: STD_LOGIC;
	signal CTRInd	: STD_LOGIC;

	-- Control packet sense (for now it is assumed if LSB is high in a packet then it is of the control variety)
	-- Its assumed that the control packet will get consumed and a new one will be created
	-- Not required in s version of blazerouter
	-- alias  senseOp 	:STD_LOGIC is fc_dataIn(0);
	
begin

-- This is setup is pretty much a large forwarder with dmux for control packet forwarding to RNA.	

-- Data Bus
fc_vcData <= fc_dataIn;
fc_rnaCtrl <= fc_dataIn;

-- packet sense
fc_pktStrb <= fc_dStrb;
dStrbInd <= fc_dStrb;

-- Clear to recieve handler
CTRInd <= (not fc_vcFull) and fc_CTRflg;
fc_CTR <= CTRInd;

-- VC Data strobe handler
fc_vcEnq <= CTRInd and dStrbInd;

end fc_4;

