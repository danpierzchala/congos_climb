library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.array_platPos.all;
-----------------------------------------------
-- The physics engine is in charge of taking in the processed user input and piloting Congo
-- through the game. If he collides with any object, update the game state accordingly
-- 
-- The physics engine runs on the main system clock and has a global reset signal
-- 
-- Inside the physics engine there is a platform_generator and a banana_generator
-- The platform generator updates the position of the (16)platforms every frame
-- and generates the platforms needed for the game as necessary when they have fallen off the bottom of the screen
--
-- The banana generator updates the position of the banana every frame, and generates the random bananas accordingly
-- 
-- The engine also outputs the score based on collisions with the objects, gaining  1 point per platform and 5 points per banana
----------------------------------------------
entity physics_engine is
    Port ( clk		: in std_logic;
           Reset	: in std_logic;
           fStart	: in std_logic;
           L		: in std_logic;
           R		: in std_logic;
           platW	: out std_logic_vector(9 downto 0);
           dead		: out std_logic;
           guyPosX	: out std_logic_vector(9 downto 0);
           guyPosY	: out std_logic_vector(9 downto 0);
           endgame	: out std_logic;
           score	: out std_logic_vector(7 downto 0);
           bananaPosX : out std_logic_vector(9 downto 0);
           bananaPosY : out std_logic_vector(9 downto 0);
           platPosX	: out platArray;
           platPosY1: out platArray;
           platPosY2: out platArray;
           jCount	: out std_logic_vector(7 downto 0));
	end physics_engine;
	
architecture Behavioral of physics_engine is	

----------------
-- The platform generator updates the platform position every frame clock
-- and outputs the new positions accordingly. The rate at which the platforms move down the screen
-- is used as an input, which could be varied by the physics engine itself
----------------
component platform_gen is
	Port ( frameClk	: in std_logic;
           Reset	: in std_logic;
           platXpos : out platArray;
           platYpos1: out platArray;
           platYpos2: out platArray;
           platS	: in std_logic_vector(9 downto 0));
end component;	

----------------
-- The banana generator updates the banana position every frame clock
-- and outputs the new position accordingly. If the banana has fallen too low on the screen
-- it disappears and reappears at a new location. The rate at which the banana moves down the screen
-- is used as an input, which could be varied by the physics engine itself
----------------
component banana_gen is
    Port ( frameClk	: in std_logic;
           Reset	: in std_logic;
           bananaS: in std_logic_vector(9 downto 0);
           collided: in std_logic;
           bananaXpos : out std_logic_vector(9 downto 0);
           bananaYpos : out std_logic_vector(9 downto 0));
end component;

signal yPlats1, yPlats2, xPlats : platArray;
signal guyPosXsig : std_logic_vector(9 downto 0) :="0101000000";
signal guyPosYsig : std_logic_vector(9 downto 0) :="0101000000";

signal guyPosXsig2, guyPosYsig2 : std_logic_vector(9 downto 0);
signal bananaPosXsig, bananaPosYsig : std_logic_vector(9 downto 0);
constant banWidth 	: std_logic_vector(3 downto 0) := "0111";
constant banHeight	: std_logic_vector(3 downto 0) := "1011";

signal collidedSig	: std_logic;

signal leftR, rightR : std_logic;

signal leftVel, rightVel : std_logic_vector(3 downto 0);

signal bananaCount	: std_logic_vector(7 downto 0);

signal frameCount : std_logic_vector(15 downto 0);
signal movePlats	: std_logic;

signal platWidth	 : std_logic_vector(9 downto 0) := "0000100110";
constant platHeight  : std_logic_vector(9 downto 0) := "0000000100";

signal xGuy, yGuy, sGuy : std_logic_vector(9 downto 0);
signal platSpeed : std_logic_vector(9 downto 0) := "0000000010";

signal isColliding : std_logic;
signal isJumping   : std_logic;
signal jumpTimer	: std_logic_vector(3 downto 0);
signal jumpCount	: std_logic_vector(7 downto 0);

signal isdead : std_logic := '0';

begin

sGuy <= "0000001101";

------------------------
-- The physics frame sequencer is in charge of moving frame to frame and updating the game state accordingly, and
-- at the end of the frame sequence, all possible positions have been updated, and it is safe to draw to the screen
-- so a flag is set and used as an output which is sent to the display_engine
-----------------------
physics_frame_sequence : process(Reset, clk, fStart)
begin
	if(falling_edge(clk)) then
		if(Reset = '1') then
			guyPosXsig <= "0101000000";
			guyPosYsig <= "0000000001";
			isdead <= '0';
			bananaCount <= "00000000";
			frameCount <= x"0000";
			jumpCount <= x"00";
			platWidth <= "0000100110";
		-- If it is the start of a new frame sample the Left and Right signal inputs	
		elsif(fStart = '1') then
			leftR <= L;
			rightR <= R;
			frameCount <= x"0001";
			movePlats <= '0';
			isColliding <= '0';			
		end if;
		
		if(frameCount = x"1000") then
			frameCount <= x"0000";
		elsif((frameCount /= x"0000") and (isdead = '0')) then
			frameCount <= frameCount + x"0001";
			
			
			case frameCount is
				-------------------------------	
				-- In the second frame, adjust Congos X position based on the user input
				-------------------------------
				when x"0002" => 
					if(leftR = '1') then
						guyPosXsig <= guyPosXsig - "1000";
					elsif(rightR = '1') then
						guyPosXsig <= guyPosXsig + "1000";
					end if;
				-------------------------------	
				-- In the third frame, update the platform positions, which is used by setting the movePlats 0->1
				-------------------------------	
				when x"0003" =>
					movePlats <= '1';
				-------------------------------	
				-- In the fourth frame, detect whether Congo is colliding with any platforms, and if so, set a flag
				-------------------------------	
				when x"0004" =>
					if( (((guyPosXsig)<= (xPlats(0) + platWidth)) and ((guyPosXsig ) >= (xPlats(0) - platWidth)) and
					     ((guyPosYsig + sGuy) > (yPlats1(0) - platHeight)) and (guyPosYsig + sGuy) < (yPlats1(0) + platHeight)) or
						(((guyPosXsig) <= (xPlats(1) + platWidth)) and ((guyPosXsig ) >= (xPlats(1) - platWidth)) and
					     ((guyPosYsig + sGuy) > (yPlats1(1) - platHeight)) and (guyPosYsig + sGuy) < (yPlats1(1) + platHeight)) or 
						(((guyPosXsig) <= (xPlats(2) + platWidth)) and ((guyPosXsig ) >= (xPlats(2) - platWidth)) and
					     ((guyPosYsig + sGuy) > (yPlats1(2) - platHeight)) and (guyPosYsig + sGuy) < (yPlats1(2) + platHeight)) or 
						(((guyPosXsig) <= (xPlats(3) + platWidth)) and ((guyPosXsig ) >= (xPlats(3) - platWidth)) and
					     ((guyPosYsig + sGuy) > (yPlats1(3) - platHeight)) and (guyPosYsig + sGuy) < (yPlats1(3) + platHeight)) or 
						(((guyPosXsig) <= (xPlats(4) + platWidth)) and ((guyPosXsig ) >= (xPlats(4) - platWidth)) and
					     ((guyPosYsig + sGuy) > (yPlats1(4) - platHeight)) and (guyPosYsig + sGuy) < (yPlats1(4) + platHeight)) or 
						(((guyPosXsig) <= (xPlats(5) + platWidth)) and ((guyPosXsig ) >= (xPlats(5) - platWidth)) and
					     ((guyPosYsig + sGuy) > (yPlats1(5) - platHeight)) and (guyPosYsig + sGuy) < (yPlats1(5) + platHeight)) or 
						(((guyPosXsig) <= (xPlats(6) + platWidth)) and ((guyPosXsig) >= (xPlats(6) - platWidth)) and
					     ((guyPosYsig + sGuy) > (yPlats1(6) - platHeight)) and (guyPosYsig + sGuy) < (yPlats1(6) + platHeight)) or 
						(((guyPosXsig) <= (xPlats(7) + platWidth)) and ((guyPosXsig) >= (xPlats(7) - platWidth)) and
					     ((guyPosYsig + sGuy) > (yPlats1(7) - platHeight)) and (guyPosYsig + sGuy) < (yPlats1(7) + platHeight)) or
					     
					     
					     (((guyPosXsig) <= (xPlats(0) + platWidth)) and ((guyPosXsig ) >= (xPlats(0) - platWidth)) and
					     ((guyPosYsig + sGuy) > (yPlats2(0) - platHeight)) and (guyPosYsig + sGuy) < (yPlats2(0) + platHeight)) or
						(((guyPosXsig) <= (xPlats(1) + platWidth)) and ((guyPosXsig ) >= (xPlats(1) - platWidth)) and
					     ((guyPosYsig + sGuy) > (yPlats2(1) - platHeight)) and (guyPosYsig + sGuy) < (yPlats2(1) + platHeight)) or 
						(((guyPosXsig) <= (xPlats(2) + platWidth)) and ((guyPosXsig ) >= (xPlats(2) - platWidth)) and
					     ((guyPosYsig + sGuy) > (yPlats2(2) - platHeight)) and (guyPosYsig + sGuy) < (yPlats2(2) + platHeight)) or 
						(((guyPosXsig) <= (xPlats(3) + platWidth)) and ((guyPosXsig) >= (xPlats(3) - platWidth)) and
					     ((guyPosYsig + sGuy) > (yPlats2(3) - platHeight)) and (guyPosYsig + sGuy) < (yPlats2(3) + platHeight)) or 
						(((guyPosXsig) <= (xPlats(4) + platWidth)) and ((guyPosXsig ) >= (xPlats(4) - platWidth)) and
					     ((guyPosYsig + sGuy) > (yPlats2(4) - platHeight)) and (guyPosYsig + sGuy) < (yPlats2(4) + platHeight)) or 
						(((guyPosXsig) <= (xPlats(5) + platWidth)) and ((guyPosXsig ) >= (xPlats(5) - platWidth)) and
					     ((guyPosYsig + sGuy) > (yPlats2(5) - platHeight)) and (guyPosYsig + sGuy) < (yPlats2(5) + platHeight)) or 
						(((guyPosXsig) <= (xPlats(6) + platWidth)) and ((guyPosXsig ) >= (xPlats(6) - platWidth)) and
					     ((guyPosYsig + sGuy) > (yPlats2(6) - platHeight)) and (guyPosYsig + sGuy) < (yPlats2(6) + platHeight)) or 
						(((guyPosXsig) <= (xPlats(7) + platWidth)) and ((guyPosXsig ) >= (xPlats(7) - platWidth)) and
					     ((guyPosYsig + sGuy) > (yPlats2(7) - platHeight)) and (guyPosYsig + sGuy) < (yPlats2(7) + platHeight)) ) then
						isColliding <= '1';
						jumpCount <= jumpCount + "0001";
					end if;	
				-------------------------------	
				-- In the fifth frame, based on the colliding flag, set the jump timer and update Congos Y position 
				-------------------------------	
				when x"0005" =>
					if( isColliding = '1') then
						jumpTimer <= "1111";
						isJumping <= '1';
						guyPosYsig <= guyPosYsig - "100000";
					end if;
				-------------------------------	
				-- In the sixth frame, If Congo is jumping adjust his Y position correctly based on how long he has been jumping for, otherwise add gravity
				-------------------------------	
				when x"0006" =>
					if( isJumping = '1') then
						isColliding <= '0';
						case jumpTimer is
							when "1111" =>
								guyPosYsig <= guyPosYsig - "100000";
							when "1110" =>
								guyPosYsig <= guyPosYsig - "100000";
							when "1101" =>
								guyPosYsig <= guyPosYsig - "10000";	
							when "1100" =>
								guyPosYsig <= guyPosYsig - "1000";
							when "1011" =>
								guyPosYsig <= guyPosYsig - "100";
							when "1010" =>
								guyPosYsig <= guyPosYsig - "10";
							when "1001" =>
								guyPosYsig <= guyPosYsig - "1";
							when "0000" =>
								isJumping <= '0';
								platSpeed <= "0000000010";
							when others =>
									null;
						end case;
					else 
						guyPosYsig <= guyPosYsig + "0110";			
					end if;
				-------------------------------	
				-- In Frame 7 decrease the jump timer
				-------------------------------	
				when x"0007" =>
					jumpTimer <= jumpTimer - "1";
				-------------------------------	
				-- In Frame 8 if Congos updated position lies outside of the screen range wrap him to the other side
				-------------------------------	
				when x"0008" => -- check to wrap guy
					if( guyPosXsig <= "0000000000" ) then
						guyPosXSig <= "1010000000";
					elsif( guyPosXsig > "1010000000" ) then
						guyPosXsig <= "0000000000";
					end if;
				-------------------------------	
				-- In Frame 9 Decrease the platform width by 5 for every 10 platforms hit, until you reach only 10 pixels wide
				-------------------------------	
				when x"0009" =>
					case jumpCount is
						when "00001010" =>
							platWidth <= "0000100011";
						when "00010100" =>
							platWidth <= "0000011110";
						when "00011110" =>
							platWidth <= "0000011001";
						when "00101000" =>
							platWidth <= "0000010100";
						when "00110010" =>
							platWidth <= "0000001111";
						when "00111100" =>
							platWidth <= "0000001010";						
						when others =>
							null;
					end case;
				-------------------------------	
				-- In Frame 10 Detect whether Congo has fallen to the bottom of the screen, if so a flag i set
				-------------------------------	
				when x"000A" =>
						if( (guyPosYsig > "111010110") and (guyPosYsig < "111100000")) then
							isdead <= '1';
						else
							isdead <= '0';
						end if;	
				-------------------------------	
				-- In Frame 11 Detect whether Congo has reached a banana and if so set a flag
				-------------------------------		
				when x"000B" =>
						if( ((guyPosXsig - sGuy < bananaPosXsig) and (guyPosXsig + Sguy > bananaPosXsig)) and 
							((guyPosYsig - sGuy < bananaPosYsig) and (guyPosYsig + Sguy > bananaPosYsig))) then
							collidedSig <= '1';
							bananaCount <= bananaCount + x"5";
						else
							collidedSig <= '0';
						end if;			
							
				when others =>
					null;
			end case;
		end if;			
	end if;	
end process;						

		


platPosX <= xPlats;
platPosY1 <= yPlats1;
platPosY2 <= yPlats2;
platW <= platWidth;

guyPosY <= guyPosYsig;
guyPosX <= guyPosXsig;

bananaPosY <= bananaPosYsig;
bananaPosX <= bananaPosXsig;

jCount <= jumpCount;

score <= bananaCount;

platform_instance : platform_gen
	Port Map( frameClk	=> movePlats,
				Reset	=> Reset,
				platXpos => xPlats,
				platYpos1 => yPlats1,
				platYpos2 => yPlats2,
				platS => platSpeed);
				
banana_instance : banana_gen
    Port Map( frameClk	=> movePlats,
           Reset	=> Reset,
           bananaS	=> platSpeed,
           bananaXpos => bananaPosXsig,
           bananaYpos => bananaPosYsig,
           collided => collidedSig );			
				
end Behavioral;				
