library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.array_guySprite.all;

----------------------------
-- The guy spriter is in charge of returning the correct RGB value for a pixel based on the current location in the sprite to draw
--
-- Pixel colors are simply a 3 member array of vectors representing the RGB values
-- The color palate is a 11 member array of pixel colors, which has the RGB values for each color
--
-- The y signal input determines which row of the sprite we are going to look at, so the current
-- row_vector points to the yth row of the sprite
--
-- Since we have 11 colors we need at least 4 bits to determine the color, to the sprite rows are vectors of the total width*4 bits
-- The x signal input determines which column we are looking at, and takes those corresponding 4 bits of data of the current row vector
--
-- After we get the 4 bits from the row vector representing some color, we then look in the color palate for that color and
-- load the appropriate RGB values
--
-- In the case of Congos sprite, we wanted to display a different one whether he was facing left or right so
-- We had an additional input and loaded a different sprite based on that input
-----------------------------
entity guySpriter is
    Port ( x		: in std_logic_vector(9 downto 0);    -- inner vector position ( pixel data)       
           y		: in std_logic_vector(9 downto 0);    -- outer array index(rows)
           dir		: in integer;
           
           
           Red		: out std_logic_vector(9 downto 0);
           Green	: out std_logic_vector(9 downto 0);
           Blue		: out std_logic_vector(9 downto 0));
	end guySpriter;
	
architecture Behavioral of guySpriter is


	type pixel_color is array(0 to 2) of std_logic_vector(9 downto 0); 
   type color_palate is array(0 to 10) of pixel_color;
   constant palate : color_palate :=
   ( -- 0 forest green ( background)
	( "0000100100", -- red
	  "0010000100", -- green
	  "0000000000"), -- blue
	-- 1 brown
	( "0011000000", -- red
	  "0010000100", -- green
	  "0000110000"), -- blue
	-- 2 oj
	( "1001100000", -- red
	  "0101100000", -- green
	  "0001100000"), -- blue  
	 -- 3 tan
	( "1011100000", -- red
	  "0111100000", -- green
	  "0011100000"), -- blue   
	 -- 4 light yellow
	( "1101100000", -- red
	  "1001100000", -- green
	  "0011100000"), -- blue  
	 -- 5 yellow
	( "1111100000", -- red
	  "1101100000", -- green
	  "0101100000"), -- blue  
	 -- 6 black
	( "0000000000", -- red
	  "0000000000", -- green
	  "0000000000"), -- blue  
	 -- 7 dark red
	( "0100100000", -- red
	  "0001100000", -- green
	  "0001000000"), -- blue  
	 -- 8 light red
	( "0110000000", -- red
	  "0010100000", -- green
	  "0001100000"), -- blue  
	 -- 9 white
	( "1111111111", -- red
	  "1111111111", -- green
	  "1111111111"), -- blue  
	 -- A grey
	( "1001100000", -- red
	  "1001100000", -- green
	  "1011100000")); -- blue  

	  
	type sprite is array(0 to 26) of std_logic_vector(107 downto 0);
	constant GUY_SPRITEL : sprite :=
	(x"000000000000006111000000000",
	 x"000000000006611781000000000",
	 x"000000000661788881111011100",
	 x"001110006677888822870122210",	 
	 x"012221166678888828887733221",
	 x"124332766678888887788754321",
	 x"124532766678822287822854321",
	 x"12444274767823A99739A723310",
	 x"12333272487833999239A731100",
	 x"01233873347833966336A721000",
	 x"00112782237723A66336A710000",
	 x"000113782277882777772810000",
	 x"000013273277723443274210000",
	 x"01001237889A834554375310000",
	 x"121001326999834555325210000",
	 x"121000136A9A783455523100000",
	 x"121000123667778244231100000",
	 x"121000012877778888111000000",
	 x"122100011877782332100000000",
	 x"012100006777234542100000000",
	 x"012210006778345553100000000",
	 x"001221006772455553100000000",
	 x"000122106782455543100000000",
	 x"000012111782345732124680000",
	 x"000001226778233328100000000",
	 x"000000116177822281100000000",
	 x"000000000167788871000000000");
	 
	 constant GUY_SPRITER : sprite :=
	(x"000000000111600000000000000",
	 x"000000000187116600000000000",
	 x"001110111188887166000000000", 	
	 x"012221078228888776600011100", 	
     x"122337788828888876661122210", 	
	 x"123457887788888876667233421", 	
	 x"123458228782228876667235421", 	
	 x"013327A93799A32876747244421", 	
	 x"001137A93299933878427233321", 	
	 x"000127A63366933874337833210", 	
	 x"000017A63366A32773228721100", 	
	 x"000018277777288772287311000", 	
	 x"000012472344327772372310000", 	
	 x"000013573455438A98873210010", 	
	 x"000012523555438999623100121", 		
	 x"000001325554387A9A631000121", 	
	 x"000001132442877766321000121", 	
	 x"000000111888877778210000121", 	
	 x"000000001233287778110001221", 	
	 x"000000001245432777600001210", 	
	 x"000000001355543877600012210", 	
	 x"000000001355554277600122100", 	
	 x"000000001345554287601221000", 	
	 x"000086421237543287111210000", 	
	 x"000000001823332877622100000", 	
	 x"000000001182228771611000000", 	
	 x"000000000178887761000000000"); 

	
signal rowVector : std_logic_vector(107 downto 0);	
signal pixelIndex: std_logic_vector(3 downto 0);

signal xSig, ySig : std_logic_vector(9 downto 0);
signal yInt	: integer;
signal dirReg : std_logic;
	
begin

xSig <= x;
ySig <= y;


get_row : process(ySig)
begin
if( dir = 1) then
	case ySig is
		when "0000000000" =>
			rowVector <= GUY_SPRITEL(0);
		when "0000000001" =>
			rowVector <= GUY_SPRITEL(1);
		when "0000000010" =>
			rowVector <= GUY_SPRITEL(2);
		when "0000000011" =>
			rowVector <= GUY_SPRITEL(3);
		when "0000000100" =>
			rowVector <= GUY_SPRITEL(4);
		when "0000000101" =>
			rowVector <= GUY_SPRITEL(5);
		when "0000000110" =>
			rowVector <= GUY_SPRITEL(6);	
		when "0000000111" =>
			rowVector <= GUY_SPRITEL(7);	
		when "0000001000" =>
			rowVector <= GUY_SPRITEL(8);	
		when "0000001001" =>
			rowVector <= GUY_SPRITEL(9);	
		when "0000001010" =>
			rowVector <= GUY_SPRITEL(10);	
		when "0000001011" =>
			rowVector <= GUY_SPRITEL(11);	
		when "0000001100" =>
			rowVector <= GUY_SPRITEL(12);	
		when "0000001101" =>
			rowVector <= GUY_SPRITEL(13);
		when "0000001110" =>
			rowVector <= GUY_SPRITEL(14);
		when "0000001111" =>
			rowVector <= GUY_SPRITEL(15);
		when "0000010000" =>
			rowVector <= GUY_SPRITEL(16);
		when "0000010001" =>
			rowVector <= GUY_SPRITEL(17);
		when "0000010010" =>
			rowVector <= GUY_SPRITEL(18);
		when "0000010011" =>
			rowVector <= GUY_SPRITEL(19);
		when "0000010100" =>
			rowVector <= GUY_SPRITEL(20);
		when "0000010101" =>
			rowVector <= GUY_SPRITEL(21);
		when "0000010110" =>
			rowVector <= GUY_SPRITEL(22);
		when "0000010111" =>
			rowVector <= GUY_SPRITEL(23);
		when "0000011000" =>
			rowVector <= GUY_SPRITEL(24);
		when "0000011001" =>
			rowVector <= GUY_SPRITEL(25);
		when "0000011010" =>
			rowVector <= GUY_SPRITEL(26);																									
				
					
		when others =>
			null;
	end case;
elsif( dir = 2 ) then
	case ySig is
		when "0000000000" =>
			rowVector <= GUY_SPRITER(0);
		when "0000000001" =>
			rowVector <= GUY_SPRITER(1);
		when "0000000010" =>
			rowVector <= GUY_SPRITER(2);
		when "0000000011" =>
			rowVector <= GUY_SPRITER(3);
		when "0000000100" =>
			rowVector <= GUY_SPRITER(4);
		when "0000000101" =>
			rowVector <= GUY_SPRITER(5);
		when "0000000110" =>
			rowVector <= GUY_SPRITER(6);	
		when "0000000111" =>
			rowVector <= GUY_SPRITER(7);	
		when "0000001000" =>
			rowVector <= GUY_SPRITER(8);	
		when "0000001001" =>
			rowVector <= GUY_SPRITER(9);	
		when "0000001010" =>
			rowVector <= GUY_SPRITER(10);	
		when "0000001011" =>
			rowVector <= GUY_SPRITER(11);	
		when "0000001100" =>
			rowVector <= GUY_SPRITER(12);	
		when "0000001101" =>
			rowVector <= GUY_SPRITER(13);
		when "0000001110" =>
			rowVector <= GUY_SPRITER(14);
		when "0000001111" =>
			rowVector <= GUY_SPRITER(15);
		when "0000010000" =>
			rowVector <= GUY_SPRITER(16);
		when "0000010001" =>
			rowVector <= GUY_SPRITER(17);
		when "0000010010" =>
			rowVector <= GUY_SPRITER(18);
		when "0000010011" =>
			rowVector <= GUY_SPRITER(19);
		when "0000010100" =>
			rowVector <= GUY_SPRITER(20);
		when "0000010101" =>
			rowVector <= GUY_SPRITER(21);
		when "0000010110" =>
			rowVector <= GUY_SPRITER(22);
		when "0000010111" =>
			rowVector <= GUY_SPRITER(23);
		when "0000011000" =>
			rowVector <= GUY_SPRITER(24);
		when "0000011001" =>
			rowVector <= GUY_SPRITER(25);
		when "0000011010" =>
			rowVector <= GUY_SPRITER(26);
		when others =>
			null;
end case;			
end if;		
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
		when "0000011010" =>
			pixelIndex <= rowVector(107 downto 104);					
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
		when x"9" =>
			Red <= palate(9)(0);
			Green <= palate(9)(1);
			Blue <= palate(9)(2);
		when x"A" =>
			Red <= palate(10)(0);
			Green <= palate(10)(1);
			Blue <= palate(10)(2);							
		when others =>
			null;
	end case;	
	
end process;
end Behavioral;
