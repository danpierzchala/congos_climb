library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

----------------------------
-- The banana spriter is in charge of returning the correct RGB value for a pixel based on the current location in the sprite to draw
--
-- Pixel colors are simply a 3 member array of vectors representing the RGB values
-- The color palate is a 11 member array of pixel colors, which has the RGB values for each color
--
-- The y signal input determines which row of the sprite we are going to look at, so the current
-- row_vector points to the yth row of the sprite
--
-- We use 4 bits to determine the color, so the sprite rows are vectors of the total width*4 bits
-- The x signal input determines which column we are looking at, and takes those corresponding 4 bits of data of the current row vector
--
-- After we get the 4 bits from the row vector representing some color, we then look in the color palate for that color and
-- load the appropriate RGB values
--
-- In the case of Congos sprite, we wanted to display a different one whether he was facing left or right so
-- We had an additional input and loaded a different sprite based on that input
-----------------------------
entity bananaSpriter is
    Port ( x		: in std_logic_vector(9 downto 0);    -- inner vector position ( pixel data)       
           y		: in std_logic_vector(9 downto 0);    -- outer array index(rows)
           
           
           Red		: out std_logic_vector(9 downto 0);
           Green	: out std_logic_vector(9 downto 0);
           Blue		: out std_logic_vector(9 downto 0));
	end bananaSpriter;
	
architecture Behavioral of bananaSpriter is


	type pixel_color is array(0 to 2) of std_logic_vector(9 downto 0); 
   type color_palate is array(0 to 3) of pixel_color;
   constant palate : color_palate :=
   ( -- 0 bg
	( "0000100100", -- red
	  "0010000100", -- green
	  "0000000000"), -- blue
	-- 1 tan
	( "1111001000", -- red
	  "1110010100", -- green
	  "1001010100"), -- blue
	-- 2 yellow
	( "1111111000", -- red
	  "1110010100", -- green
	  "0001110000"), -- blue  
	 -- 3 brown
	( "1010100000", -- red
	  "0110111000", -- green
	  "0010010000")); -- blue  
	  
	type sprite is array(0 to 22) of std_logic_vector(59 downto 0);
	constant BANANA_SPRITE : sprite :=
	(x"000003100000000",
	 x"000003300000000",
	 x"000001210000000",
	 x"000000222000000",	 
	 x"000000212220000",
	 x"000000212222000",
	 x"000001211222100",
	 x"000001211222100",
	 x"000001221222200",
	 x"000001321222200",
	 x"000001222222200",
	 x"000001221222210",
	 x"000002222222300",
	 x"000002212222300",
	 x"000012122222100",
	 x"000022122223100",
	 x"000221222223000",
	 x"001222222330000",
	 x"002222222310000",
	 x"022232333100000",
	 x"233232331000000",
	 x"333333100000000",
	 x"033310000000000");
	 

	
signal rowVector : std_logic_vector(59 downto 0);	
signal pixelIndex: std_logic_vector(3 downto 0);

signal xSig, ySig : std_logic_vector(9 downto 0);
signal yInt	: integer;
	
begin

xSig <= x;
ySig <= y;


get_row : process(ySig)
begin
	case ySig is
		when "0000000000" =>
			rowVector <= BANANA_SPRITE(0);
		when "0000000001" =>
			rowVector <= BANANA_SPRITE(1);
		when "0000000010" =>
			rowVector <= BANANA_SPRITE(2);
		when "0000000011" =>
			rowVector <= BANANA_SPRITE(3);
		when "0000000100" =>
			rowVector <= BANANA_SPRITE(4);
		when "0000000101" =>
			rowVector <= BANANA_SPRITE(5);
		when "0000000110" =>
			rowVector <= BANANA_SPRITE(6);
		when "0000000111" =>
			rowVector <= BANANA_SPRITE(7);
		when "0000001000" =>
			rowVector <= BANANA_SPRITE(8);
		when "0000001001" =>
			rowVector <= BANANA_SPRITE(9);
		when "0000001010" =>
			rowVector <= BANANA_SPRITE(10);
		when "0000001011" =>
			rowVector <= BANANA_SPRITE(11);
		when "0000001100" =>
			rowVector <= BANANA_SPRITE(12);
		when "0000001101" =>
			rowVector <= BANANA_SPRITE(13);
		when "0000001110" =>
			rowVector <= BANANA_SPRITE(14);
		when "0000001111" =>
			rowVector <= BANANA_SPRITE(15);
		when "0000010000" =>
			rowVector <= BANANA_SPRITE(16);
		when "0000010001" =>
			rowVector <= BANANA_SPRITE(17);
		when "0000010010" =>
			rowVector <= BANANA_SPRITE(18);
		when "0000010011" =>
			rowVector <= BANANA_SPRITE(19);
		when "0000010100" =>
			rowVector <= BANANA_SPRITE(20);
		when "0000010101" =>
			rowVector <= BANANA_SPRITE(21);
		when "0000010110" =>
			rowVector <= BANANA_SPRITE(22);																																																									
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
		when others =>
			null;
	end case;	
	
end process;
end Behavioral;
