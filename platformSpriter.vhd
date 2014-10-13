library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

----------------------------
-- The platform spriter is in charge of returning the correct RGB value for a pixel based on the current location in the sprite to draw
--
-- Pixel colors are simply a 3 member array of vectors representing the RGB values
-- The color palate is a 9 member array of pixel colors, which has the RGB values for each color
--
-- The y signal input determines which row of the sprite we are going to look at, so the current
-- row_vector points to the yth row of the sprite
--
-- Since we have 9 colors we need at least 4 bits to determine the color, to the sprite rows are vectors of the total width*4 bits
-- The x signal input determines which column we are looking at, and takes those corresponding 4 bits of data of the current row vector
--
-- After we get the 4 bits from the row vector representing some color, we then look in the color palate for that color and
-- load the appropriate RGB values
-----------------------------

entity platformSpriter is
    Port ( x		: in std_logic_vector(9 downto 0);    -- inner vector position ( pixel data)       
           y		: in std_logic_vector(9 downto 0);    -- outer array index(rows)
           
           
           Red		: out std_logic_vector(9 downto 0);
           Green	: out std_logic_vector(9 downto 0);
           Blue		: out std_logic_vector(9 downto 0));
	end platformSpriter;
	
architecture Behavioral of platformSpriter is


	type pixel_color is array(0 to 2) of std_logic_vector(9 downto 0); 
   type color_palate is array(0 to 8) of pixel_color;
   constant palate : color_palate :=
   ( -- 0 dark green 
	( "0000110000", -- red
	  "0011110000", -- green
	  "0000100000"), -- blue
	-- 1 kelly green
	( "0010001100", -- red
	  "0111000000", -- green
	  "0010001100"), -- blue
	-- 2 green
	( "0101100000", -- red
	  "1001000100", -- green
	  "0011100000"), -- blue  
	 -- 3 light green
	( "1000111100", -- red
	  "1100000100", -- green
	  "0101011100"), -- blue   
	 -- 4 yellow green
	( "1100000000", -- red
	  "1101100100", -- green
	  "0111100000"), -- blue  
	 -- 5 tan
	( "1110111100", -- red
	  "1111010100", -- green
	  "1010000000"), -- blue  
	 -- 6 dark tan
	( "1010001000", -- red
	  "1010001000", -- green
	  "0110001100"), -- blue  
	 -- 7 white
	( "0100100000", -- red
	  "0001100000", -- green
	  "0001000000"), -- blue  
	 -- 8 background
	( "0000100100", -- red
	  "0010000100", -- green
	  "0000000000")); -- blue  
	  
	type sprite is array(0 to 15) of std_logic_vector(303 downto 0);
	constant PLATFORM_SPRITE : sprite :=
	(x"8888888888888888888888888888888888888888888888888888888888888888888888888888",
	 x"8888888888888888882088888823888888882288888880688888888881188888840688888888",
	 x"8888888888288888886028888830688836888860388888304888368888303888881048883888",
	 x"8888888888008888688001888610048603886840018882100486068868600188821008820888",	 
	 x"8888888888103884064111656033005106840661114560360150048604612145213601500888",
	 x"8888888888001111000034430155310204810010344101553002055100003441015521030888",
	 x"8888888412034201100013442155441066111000134421554410661110101434225453103620",
	 x"8426345400245213320002455145552143033100024551455512420431000245414554124200",
	 x"8600044560451035520001344125541352255201013531255314422541001145414554144200",
	 x"8810003540451155300220111113431354452001201111135313544520021011111352135520",
	 x"8880002540442655014432232101311454450144322321012114544402443133210221255410",
	 x"8885110220434555245542385100101454442485324851001024544425553248400011145420",
	 x"0025410001334533455420384000001235335554203830000012353355541048600001124520",
	 x"8002210012314531332100651000001133222321004510000111332223110054100000114310",
	 x"8800022321201542232012320001221121123310123100012211211333102231000132112102",
	 x"8880045541111334554245201116541111345542452011145411113455324520112453111113");
	 

	
signal rowVector : std_logic_vector(303 downto 0);	
signal pixelIndex: std_logic_vector(3 downto 0);

signal xSig, ySig : std_logic_vector(9 downto 0);
signal yInt	: integer;
signal dirReg : std_logic;
	
begin

xSig <= x;
ySig <= y;


get_row : process(ySig)
begin
	case ySig is
		when "0000000000" =>
			rowVector <= PLATFORM_SPRITE(0);
		when "0000000001" =>
			rowVector <= PLATFORM_SPRITE(1);
		when "0000000010" =>
			rowVector <= PLATFORM_SPRITE(2);
		when "0000000011" =>
			rowVector <= PLATFORM_SPRITE(3);
		when "0000000100" =>
			rowVector <= PLATFORM_SPRITE(4);
		when "0000000101" =>
			rowVector <= PLATFORM_SPRITE(5);
		when "0000000110" =>
			rowVector <= PLATFORM_SPRITE(6);
		when "0000000111" =>
			rowVector <= PLATFORM_SPRITE(7);
		when "0000001000" =>
			rowVector <= PLATFORM_SPRITE(8);
		when "0000001001" =>
			rowVector <= PLATFORM_SPRITE(9);
		when "0000001010" =>
			rowVector <= PLATFORM_SPRITE(10);
		when "0000001011" =>
			rowVector <= PLATFORM_SPRITE(11);
		when "0000001100" =>
			rowVector <= PLATFORM_SPRITE(12);
		when "0000001101" =>
			rowVector <= PLATFORM_SPRITE(13);
		when "0000001110" =>
			rowVector <= PLATFORM_SPRITE(14);
		when "0000001111" =>
			rowVector <= PLATFORM_SPRITE(15);																																										
		when others =>
			null;
	end case;	
end process;			
		
	
get_pixel_data : process(rowVector, xSig)	
begin
	case xSig is
		when "0000000000" =>
			pixelIndex <= rowVector(3 downto 0);
		when "0000000001" =>
			pixelIndex <= rowVector(7 downto 4);
		when "0000000010" =>
			pixelIndex <= rowVector(11 downto 8);
		when "0000000011" =>
			pixelIndex <= rowVector(15 downto 12);
		when "0000000100" =>
			pixelIndex <= rowVector(19 downto 16);
		when "0000000101" =>
			pixelIndex <= rowVector(23 downto 20);
		when "0000000110" =>
			pixelIndex <= rowVector(27 downto 24);
		when "0000000111" =>
			pixelIndex <= rowVector(31 downto 28);
		when "0000001000" =>
			pixelIndex <= rowVector(35 downto 32);
		when "0000001001" =>
			pixelIndex <= rowVector(39 downto 36);
		when "0000001010" =>
			pixelIndex <= rowVector(43 downto 40);
		when "0000001011" =>
			pixelIndex <= rowVector(47 downto 44);											
		when "0000001100" =>
			pixelIndex <= rowVector(51 downto 48);
		when "0000001101" =>
			pixelIndex <= rowVector(55 downto 52);
		when "0000001110" =>
			pixelIndex <= rowVector(59 downto 56);
		when "0000001111" =>
			pixelIndex <= rowVector(63 downto 60);
		when "0000010000" =>
			pixelIndex <= rowVector(67 downto 64);
		when "0000010001" =>
			pixelIndex <= rowVector(71 downto 68);
		when "0000010010" =>
			pixelIndex <= rowVector(75 downto 72);
		when "0000010011" =>
			pixelIndex <= rowVector(79 downto 76);
		when "0000010100" =>
			pixelIndex <= rowVector(83 downto 80);
		when "0000010101" =>
			pixelIndex <= rowVector(87 downto 84);
		when "0000010110" =>
			pixelIndex <= rowVector(91 downto 88);
		when "0000010111" =>
			pixelIndex <= rowVector(95 downto 92);
		when "0000011000" =>
			pixelIndex <= rowVector(99 downto 96);
		when "0000011001" =>
			pixelIndex <= rowVector(103 downto 100);
		when "0000011010" => ------------------------------
			pixelIndex <= rowVector(107 downto 104);
		when "0000011011" =>
			pixelIndex <= rowVector(111 downto 108);
		when "0000011100" =>
			pixelIndex <= rowVector(115 downto 112);
		when "0000011101" =>
			pixelIndex <= rowVector(119 downto 116);
		when "0000011110" =>
			pixelIndex <= rowVector(123 downto 120);
		when "0000011111" =>
			pixelIndex <= rowVector(127 downto 124);
		when "0000100000" =>
			pixelIndex <= rowVector(131 downto 128);
		when "0000100001" =>
			pixelIndex <= rowVector(135 downto 132);
		when "0000100010" =>
			pixelIndex <= rowVector(139 downto 136);
		when "0000100011" =>
			pixelIndex <= rowVector(143 downto 140);
		when "0000100100" =>
			pixelIndex <= rowVector(147 downto 144);
		when "0000100101" =>
			pixelIndex <= rowVector(151 downto 148);
		when "0000100110" =>
			pixelIndex <= rowVector(155 downto 152);
		when "0000100111" =>
			pixelIndex <= rowVector(159 downto 156);
		when "0000101000" =>
			pixelIndex <= rowVector(163 downto 160);
		when "0000101001" =>
			pixelIndex <= rowVector(167 downto 164);
		when "0000101010" =>
			pixelIndex <= rowVector(171 downto 168);
		when "0000101011" =>
			pixelIndex <= rowVector(175 downto 172);
		when "0000101100" =>
			pixelIndex <= rowVector(179 downto 176);
		when "0000101101" =>
			pixelIndex <= rowVector(183 downto 180);
		when "0000101110" =>
			pixelIndex <= rowVector(187 downto 184);
		when "0000101111" =>
			pixelIndex <= rowVector(191 downto 188);
		when "0000110000" =>
			pixelIndex <= rowVector(195 downto 192);
		when "0000110001" =>
			pixelIndex <= rowVector(199 downto 196);
		when "0000110010" =>
			pixelIndex <= rowVector(203 downto 200);
		when "0000110011" =>
			pixelIndex <= rowVector(207 downto 204);
		when "0000110100" =>
			pixelIndex <= rowVector(211 downto 208);
		when "0000110101" =>
			pixelIndex <= rowVector(215 downto 212);
		when "0000110110" =>
			pixelIndex <= rowVector(219 downto 216);
		when "0000110111" =>
			pixelIndex <= rowVector(223 downto 220);
		when "0000111000" =>
			pixelIndex <= rowVector(227 downto 224);
		when "0000111001" =>
			pixelIndex <= rowVector(231 downto 228);
		when "0000111010" =>
			pixelIndex <= rowVector(235 downto 232);
		when "0000111011" =>
			pixelIndex <= rowVector(239 downto 236);
		when "0000111100" =>
			pixelIndex <= rowVector(243 downto 240);
		when "0000111101" =>
			pixelIndex <= rowVector(247 downto 244);
		when "0000111110" =>
			pixelIndex <= rowVector(251 downto 248);
		when "0000111111" =>
			pixelIndex <= rowVector(255 downto 252);
		when "0001000000" =>
			pixelIndex <= rowVector(259 downto 256);
		when "0001000001" =>
			pixelIndex <= rowVector(263 downto 260);
		when "0001000010" =>
			pixelIndex <= rowVector(267 downto 264);
		when "0001000011" =>
			pixelIndex <= rowVector(271 downto 268);
		when "0001000100" =>
			pixelIndex <= rowVector(275 downto 272);
		when "0001000101" =>
			pixelIndex <= rowVector(279 downto 276);
		when "0001000110" =>
			pixelIndex <= rowVector(283 downto 280);
		when "0001000111" =>
			pixelIndex <= rowVector(287 downto 284);
		when "0001001000" =>
			pixelIndex <= rowVector(291 downto 288);
		when "0001001001" =>
			pixelIndex <= rowVector(295 downto 292);
		when "0001001010" =>
			pixelIndex <= rowVector(299 downto 296);
		when "0001001011" =>
			pixelIndex <= rowVector(303 downto 300);
																																					
		when others =>
			null;
	end case;
	
	
	case pixelIndex is
		when x"0" =>
			Red <= palate(0)(0);
			Green <= palate(0)(1);
			Blue <= palate(0)(2);
		when x"1" =>
			Red <= palate(1)(0);
			Green <= palate(1)(1);
			Blue <= palate(1)(2);
		when x"2" =>
			Red <= palate(2)(0);
			Green <= palate(2)(1);
			Blue <= palate(2)(2);
		when x"3" =>
			Red <= palate(3)(0);
			Green <= palate(3)(1);
			Blue <= palate(3)(2);
		when x"4" =>
			Red <= palate(4)(0);
			Green <= palate(4)(1);
			Blue <= palate(4)(2);
		when x"5" =>
			Red <= palate(5)(0);
			Green <= palate(5)(1);
			Blue <= palate(5)(2);
		when x"6" =>
			Red <= palate(6)(0);
			Green <= palate(6)(1);
			Blue <= palate(6)(2);
		when x"7" =>
			Red <= palate(7)(0);
			Green <= palate(7)(1);
			Blue <= palate(7)(2);
		when x"8" =>
			Red <= palate(8)(0);
			Green <= palate(8)(1);
			Blue <= palate(8)(2);						
		when others =>
			null;
	end case;	
	
end process;
end Behavioral;
