library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;
library work;
use work.array_platPos.all;

----------------
-- The platform generator is in charge of updating the platform position every frame clock
--
-- The screen is split up into 8 columns, and there are two possible platforms for each column
-- Every frame clock the y position of columns 0 through 7 is updated based on the platform speed,
-- which is an input from the physics engine.
--
-- The generator is in charge of outputting the 8 x positions, and 16 y positions of the platforms to the phyiscs engine
----------------
entity platform_gen is
    Port ( frameClk	: in std_logic;
           Reset	: in std_logic;
           platS: in std_logic_vector(9 downto 0);
           platXpos : out platArray;
           platYpos1 : out platArray;
           platYpos2 : out platArray);
		end platform_gen;
		


architecture Behavioral of platform_gen is

type platArray is array (0 to 7) of std_logic_vector(9 downto 0);
signal xPlatPos, yPlatPos1, yPlatPos2 : platArray; 
signal yPlatPos1Upper, yPlatPos2Upper : platArray;
signal randomYpos : platArray;
constant col0_center : std_logic_vector(9 downto 0) := "0000101000"; --40
constant col1_center : std_logic_vector(9 downto 0) := "0001111000"; --120
constant col2_center : std_logic_vector(9 downto 0) := "0011001000"; --200
constant col3_center : std_logic_vector(9 downto 0) := "0100011000"; --280
constant col4_center : std_logic_vector(9 downto 0) := "0101101000"; --360
constant col5_center : std_logic_vector(9 downto 0) := "0110111000"; --440
constant col6_center : std_logic_vector(9 downto 0) := "1000001000"; --520
constant col7_center : std_logic_vector(9 downto 0) := "1001011000"; --600

signal randomCounter : integer; -- :=240;
signal randomPick : integer;
signal randomVec : std_logic_vector(9 downto 0);

begin

xPlatPos(0) <= col0_center;
xPlatPos(1) <= col1_center;
xPlatPos(2) <= col2_center;
xPlatPos(3) <= col3_center;
xPlatPos(4) <= col4_center;
xPlatPos(5) <= col5_center;
xPlatPos(6) <= col6_center;
xPlatPos(7) <= col7_center;

	----------------------
	-- The platforms are stored as if there are two screens stacked on top of each other
	-- When a platform reaches the bottom of the bottom screen a platform is randomly generated somewhere at the top of the top screen in the correct column
	-- Both screens platforms move at the same rate
	-- When a platform reaches the bottom of the top screen it appears at the top of the bottom screen and everything continues as normal
	---------------------
	generate_platforms: process(Reset, frameClk, platS)
	begin
		if(reset = '1') then
			yPlatPos1(0) <= "0000111000";
			yPlatPos1(1) <= "0001111100";
			yPlatPos1(2) <= "0000100001";
			yPlatPos1(3) <= "0010101100";
			yPlatPos1(4) <= "0001001101";
			yPlatPos1(5) <= "0011011110";
			yPlatPos1(6) <= "0010010100";
			yPlatPos1(7) <= "0000100101";
			
			yPlatPos2(0) <= "0110111110";
			yPlatPos2(1) <= "0101010100";
			yPlatPos2(2) <= "0100001000";
			yPlatPos2(3) <= "0110010111";
			yPlatPos2(4) <= "0100111000";
			yPlatPos2(5) <= "0111000011";
			yPlatPos2(6) <= "0101101000";
			yPlatPos2(7) <= "0110101001";		
			
		elsif(rising_edge(frameClk)) then
			randomCounter <= randomCounter +1;
			randomPick <= randomCounter mod 250;
			randomPick <= randomPick + 200;
			randomVec <= std_logic_vector(to_unsigned(randomPick, 10));
		 
			for i in 0 to 7 loop -- move platforms down
				randomCounter <= randomCounter +20;
				
			
				if(yPlatPos1(i) >= "0000000000") then
					yPlatPos1(i) <= yPlatPos1(i) + platS;
				end if;				
				if(yPlatPos1Upper(i) > "0000000000") then
					yPlatPos1Upper(i) <= yPlatPos1Upper(i) + platS;
				end if;
				
				if(yPlatPos2(i) >= "0000000000") then
					yPlatPos2(i) <= yPlatPos2(i) + platS;
				end if;
				if(yPlatPos2Upper(i) > "0000000000") then
					yPlatPos2Upper(i) <= yPlatPos2Upper(i) + platS;
				end if;
				
				if( yPlatPos1(i) > "0111100000") then
					yPlatPos1Upper(i) <= randomVec;
				end if;
				if( yPlatPos1Upper(i) > "0111100000") then
					yPlatPos1(i) <= "0000000000";
					yPlatPos1Upper(i) <= "0000000000";
				end if;	
				
				if( yPlatPos2(i) > "0111100000") then
					yPlatPos2Upper(i) <= randomVec;
				end if;
				if( yPlatPos2Upper(i) > "0111100000") then
					yPlatPos2(i) <= "0000000000";
					yPlatPos2Upper(i) <= "0000000000";
				end if;				
				
			end loop;
			
		end if;
	end process;



	platYpos1(0) <= yPlatPos1(0);
	platXpos(0) <= xPlatPos(0);
	
	platYpos1(1) <= yPlatPos1(1);
	platXpos(1) <= xPlatPos(1);

	platYpos1(2) <= yPlatPos1(2);
	platXpos(2) <= xPlatPos(2);
	
	platYpos1(3) <= yPlatPos1(3);
	platXpos(3) <= xPlatPos(3);
	
	platYpos1(4) <= yPlatPos1(4);
	platXpos(4) <= xPlatPos(4);
	
	platYpos1(5) <= yPlatPos1(5);
	platXpos(5) <= xPlatPos(5);
	
	platYpos1(6) <= yPlatPos1(6);
	platXpos(6) <= xPlatPos(6);
	
	platYpos1(7) <= yPlatPos1(7);
	platXpos(7) <= xPlatPos(7);
	
	platYpos2(7) <= yPlatPos2(7);
	platYpos2(6) <= yPlatPos2(6);
	platYpos2(5) <= yPlatPos2(5);
	platYpos2(4) <= yPlatPos2(4);
	platYpos2(3) <= yPlatPos2(3);
	platYpos2(2) <= yPlatPos2(2);
	platYpos2(1) <= yPlatPos2(1);
	platYpos2(0) <= yPlatPos2(0);
end Behavioral;			
