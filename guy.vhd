library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity guy is
    Port ( clk		: in std_logic;
           Reset	: in std_logic;
           makeIn	: in std_logic;
		   codeRdyIn: in std_logic;
           scanIn	: in std_logic_vector(7 downto 0);
           L		: out std_logic;
           R		: out std_logic);
		end guy;
		
architecture Behavioral of guy is

constant gravity : std_logic_vector(9 downto 0) := "0000000100";
--signal xPos, yPos : std_logic_vector(9 downto 0);

signal moveLeftReg, moveRightReg, rdyReg : std_logic;

begin

--	guySize <= "0000001000";
	
		
	updateRegs : process(reset, clk)
	begin
		if(reset = '1') then
			moveLeftReg <= '0';
			moveRightReg<= '0';
			rdyReg <= '0';
		elsif(falling_edge(clk)) then
			rdyReg <= codeRdyIn;
--			if((codeRdyIn = '1') and (rdyReg = '0')) then
				case scanIn is
					when x"1C" =>
						moveLeftReg <= makeIn;
					when x"23" =>
						moveRightReg<= makeIn;
					when others =>
						null;
				end case;
	--		end if;
		end if;
	end process;		
				
L <= moveLeftReg;
R <= moveRightReg;			
--guyXpos <= xPos;
--guyYpos <= yPos;		
	
end Behavioral;		
