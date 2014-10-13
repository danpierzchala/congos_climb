library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;
library work;
use work.array_platPos.all;

----------------
-- The banana generator is in charge of randomly generating a banana on the screen and updating its position
-- The generator runs on the frame clock, and takes an inputs collided and speed from the physics engine
-- If a collision was detected, collided = '1' and a new banana is generated
-- Otherwise, the banana moves down the screen at a rate of bananaS which is determined by the physics engine
----------------
entity banana_gen is
    Port ( frameClk	: in std_logic;
           Reset	: in std_logic;
           bananaS: in std_logic_vector(9 downto 0);
           bananaXpos : out std_logic_vector(9 downto 0);
           bananaYpos : out std_logic_vector(9 downto 0);
           collided	: in std_logic);
		end banana_gen;
		
architecture Behavioral of banana_gen is


signal randomCounter : integer;
signal randomCounter2 : integer;
signal randomPick : integer;
signal randomPick2: integer;
signal randomVec : std_logic_vector(9 downto 0);
signal bananaExists : std_logic;

signal bananaXsig, bananaYsig : std_logic_vector(9 downto 0);

begin

	generate_banana: process(Reset, frameClk, bananaS, collided)
	begin
		if(reset = '1') then	
			bananaYsig <= "0000000001";
			bananaXsig <= "0001100100";
		elsif(rising_edge(frameClk)) then
			randomCounter2 <= randomCounter2 + 6347;
			randomPick2 <= randomCounter2 mod randomCounter;
			randomCounter <= randomCounter + randomPick2;
			randomPick <= randomCounter mod 600;
			randomVec <= std_logic_vector(to_unsigned(randomPick, 10));
			
			if(bananaYsig > "0000000000") then
					bananaYsig <= bananaYsig + bananaS;
					bananaExists <= '1';
			end if;
			
			if( bananaExists = '0') then
				bananaXsig <= randomVec;
				bananaYsig <= "0000000001";
				bananaExists <= '1';
			end if;
			
			if(bananaYsig > "0101011110") then
					bananaYsig <= "0000000001";
					bananaExists <= '0';
			end if;
			
			if(collided = '1') then
				bananaYsig <= "0000000000";
				bananaExists <= '0';
			end if;	
			
		end if;
	end process;
	
bananaYpos <= bananaYsig;
bananaXpos <= bananaXsig;	

end Behavioral;			
