library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

library work;
use work.array_platPos.all;
---------------------------------------
-- The display engine is in charge of displaying the game to the VGA display
-- It takes in all positional inputs in order to correctly display them at their correct location on the screen
-- 
-- When displaying a platform, banana, or Congo, we get the correct RGB values from a 'spriter component'
-- A certain X and Y value is calculated based on which pixel should be looked up of the sprite, and the spriter returns
-- the correct RGB values for that pixel

-- The display engine runs on the system clock and has the global reset signal, and produces the
-- basic required signals for correct VGA display
----------------------------------------
entity vga_display_engine is 
  Port ( clk       : in  std_logic;
         reset     : in  std_logic;
         guyPosX	: in std_logic_vector(9 downto 0); 
         guyPosY	: in std_logic_vector(9 downto 0);
         platXpos	: in platArray;
         platYpos1 	: in platArray;
         platYpos2	: in platArray;
         platWidth	: in std_logic_vector(9 downto 0);
         banPosX	: in std_logic_vector(9 downto 0);
         banPosY	: in std_logic_vector(9 downto 0);
		leftDir		: in std_logic;
		rightDir	: in std_logic;
         
         hs        : out std_logic;  -- Horizontal sync pulse.  Active low
         vs        : out std_logic;  -- Vertical sync pulse.  Active low
         pixel_clk : out std_logic;  -- 25 MHz pixel clock output
         blank     : out std_logic;  -- Blanking interval indicator.  Active low.
         sync      : out std_logic;  -- Composite Sync signal.  Active low.  We don't use it in this lab,
                                     --   but the video DAC on the DE2 board requires an input for it.
         fStart		: out std_logic;
         Red   : out std_logic_vector(9 downto 0);
         Green : out std_logic_vector(9 downto 0);
         Blue  : out std_logic_vector(9 downto 0));
end vga_display_engine;


architecture Behavorial of vga_display_engine is


-----------------------
-- Looks up correct (x,y) pixel in the Congo sprite and returns the RGB values for that pixel
-- Will look up a different one if he is moving left or moving right
-----------------------
component guySpriter is
    Port ( x		: in std_logic_vector(9 downto 0);    -- inner vector position ( pixel data)       
           y		: in std_logic_vector(9 downto 0);    -- outer array index(rows)
           dir		: in integer;
           
           
           Red		: out std_logic_vector(9 downto 0);
           Green	: out std_logic_vector(9 downto 0);
           Blue		: out std_logic_vector(9 downto 0));
	end component;	
	
----------------------
-- Looks up forrect (x,y) pixel of the platform sprite and returns RGB value for that pixel
----------------------	
component platformSpriter is
    Port ( x		: in std_logic_vector(9 downto 0);    -- inner vector position ( pixel data)       
           y		: in std_logic_vector(9 downto 0);    -- outer array index(rows)           
           
           Red		: out std_logic_vector(9 downto 0);
           Green	: out std_logic_vector(9 downto 0);
           Blue		: out std_logic_vector(9 downto 0));
	end component;

----------------------
-- Looks up forrect (x,y) pixel of the banana sprite and returns RGB value for that pixel
----------------------	
component bananaSpriter is
    Port ( x		: in std_logic_vector(9 downto 0);    -- inner vector position ( pixel data)       
           y		: in std_logic_vector(9 downto 0);    -- outer array index(rows)           
           
           Red		: out std_logic_vector(9 downto 0);
           Green	: out std_logic_vector(9 downto 0);
           Blue		: out std_logic_vector(9 downto 0));
	end component;					

  --800 horizontal pixels indexed 0 to 799
  --525 vertical pixels indexed 0 to 524
  constant hpixels : std_logic_vector(9 downto 0) := "1100011111";
  constant vlines  : std_logic_vector(9 downto 0) := "1000001100";
  
    --horizontal pixel and vertical line counters
  signal hc, vc : std_logic_vector(9 downto 0);
  signal clkdiv : std_logic;

  --signal indicates if ok to display color for a pixel
  signal display : std_logic;


signal xPlat, yPlat1, yPlat2 : platArray;

---------------------------------------------------------
-- Arrays which hold the Xmin,Ymin and Xmax,Ymax coordinates for the block letters at the top of the screen
-- the block letters are split up into rectangles, and if the draw signal lies within those bounds paint the letter in
---------------------------------------------------------

signal letterCxMin, letterCxMax, letterCyMin, letterCyMax : platArray; -- coordinates for letter C
signal letterOxMin, letterOxMax, letterOyMin, letterOyMax : platArray; -- coordinates for letter O
signal letterNxMin, letterNxMax, letterNyMin, letterNyMax : platArray; -- coordinates for letter N
signal letterGxMin, letterGxMax, letterGyMin, letterGyMax : platArray; -- coordinates for letter G
signal letterSxMin, letterSxMax, letterSyMin, letterSyMax : platArray; -- coordinates for letter G
signal letterLxMin, letterLxMax, letterLyMin, letterLyMax : platArray; -- coordinates for letter L
signal letterIxMin, letterIxMax, letterIyMin, letterIyMax : platArray; -- coordinates for letter I
signal letterMxMin, letterMxMax, letterMyMin, letterMyMax : platArray; -- coordinates for letter M
signal letterBxMin, letterBxMax, letterByMin, letterByMax : platArray; -- coordinates for letter B

signal DrawXSig, DrawYSig : std_logic_vector(9 downto 0);

signal xGuy, yGuy, sGuy : std_logic_vector(9 downto 0);

signal drawPlat : std_logic;

-- sprite sigs
signal congX, congY, congRed, congGreen, congBlue : std_logic_vector(9 downto 0);
signal platX, platY, platRed, platGreen, platBlue : std_logic_vector(9 downto 0);
signal treeX, treeY, treeRed, treeGreen, treeBlue : std_logic_vector(9 downto 0);
signal bananaX, bananaY, bananaRed, bananaGreen, bananaBlue : std_logic_vector(9 downto 0);

signal dirReg : integer := 1;
signal DrawYint	: integer;

constant platHeight  : std_logic_vector(9 downto 0) := "0000000100";
constant treeWidth	: std_logic_vector(3 downto 0) := "1001";
constant banWidth 	: std_logic_vector(3 downto 0) := "0111";
constant banHeight	: std_logic_vector(3 downto 0) := "1011";
--constant platWidth	 : std_logic_vector(9 downto 0) := "0000101000";

begin
  -- Disable Composite Sync
  sync <= '0';
  
xPlat <= platXpos;
yPlat1 <= platYpos1;
yPlat2 <= platYpos2;

xGuy <= guyPosX;
yGuy <= guyPosY;
sGuy <= "0000001101";
 direction : process(reset, leftDir, rightDir)
	begin	
		if( leftDir = '1') then
			dirReg <= 1;
		elsif( rightDir = '1') then
			dirReg <= 2;
			
		else
			dirReg <= dirReg;
		end if;
end process;			

-- set up letter signals, each letter was divided into rectangles and the min/max coords of the rectangle based on its location
-- are stored in an array. Each letter has 4 arrays of size 8, holding the Xmin,Xmax,Ymin,Ymax coords of each rectangle for up to 
-- a total of 8
-- LETTER C
letterCxMin(0) <= "0001000110";
letterCxMax(0) <= "0001011001";
letterCyMin(0) <= "0000011010";
letterCyMax(0) <= "0000111110";

letterCxMin(1) <= "0001011001";
letterCxMax(1) <= "0001101010";
letterCyMin(1) <= "0000011010";
letterCyMax(1) <= "0000011111";

letterCxMin(2) <= "0001100010";
letterCxMax(2) <= "0001101010";
letterCyMin(2) <= "0000011111";
letterCyMax(2) <= "0000100100";

letterCxMin(3) <= "0001011001";
letterCxMax(3) <= "0001101010";
letterCyMin(3) <= "0000110110";
letterCyMax(3) <= "0000111110";

letterCxMin(4) <= "0001100010";
letterCxMax(4) <= "0001101010";
letterCyMin(4) <= "0000110001";
letterCyMax(4) <= "0000110110";

-- LETTER O
letterOxMin(0) <= "0001101110";
letterOxMax(0) <= "0010010100";
letterOyMin(0) <= "0000011010";
letterOyMax(0) <= "0000011111";

letterOxMin(1) <= "0001101110";
letterOxMax(1) <= "0010010100";
letterOyMin(1) <= "0000110101";
letterOyMax(1) <= "0000111110";

letterOxMin(2) <= "0001101110";
letterOxMax(2) <= "0010000001";
letterOyMin(2) <= "0000011010";
letterOyMax(2) <= "0000111110";

letterOxMin(3) <= "0010001010";
letterOxMax(3) <= "0010010100";
letterOyMin(3) <= "0000011010";
letterOyMax(3) <= "0000111110";

-- LETTER N
letterNxMin(0) <= "0010011000";
letterNxMax(0) <= "0010100000";
letterNyMin(0) <= "0000011010";
letterNyMax(0) <= "0000111110";

letterNxMin(1) <= "0010100000";
letterNxMax(1) <= "0010100101";
letterNyMin(1) <= "0000011111";
letterNyMax(1) <= "0000111110";

letterNxMin(2) <= "0010100101";
letterNxMax(2) <= "0010101001";
letterNyMin(2) <= "0000100011";
letterNyMax(2) <= "0000111110";

letterNxMin(3) <= "0010101001";
letterNxMax(3) <= "0010101110";
letterNyMin(3) <= "0000101000";
letterNyMax(3) <= "0000110001";

letterNxMin(4) <= "0010101110";
letterNxMax(4) <= "0010110011";
letterNyMin(4) <= "0000101100";
letterNyMax(4) <= "0000110101";

letterNxMin(5) <= "0010110011";
letterNxMax(5) <= "0010110111";
letterNyMin(5) <= "0000011010";
letterNyMax(5) <= "0000111010";

letterNxMin(6) <= "0010110111";
letterNxMax(6) <= "0010111011";
letterNyMin(6) <= "0000011010";
letterNyMax(6) <= "0000111110";

--LETTER G
letterGxMin(0) <= "0010111111";
letterGxMax(0) <= "0011010010";
letterGyMin(0) <= "0000011010";
letterGyMax(0) <= "0000111110";

letterGxMin(1) <= "0011010010";
letterGxMax(1) <= "0011100100";
letterGyMin(1) <= "0000011010";
letterGyMax(1) <= "0000011111";

letterGxMin(2) <= "0011011010";
letterGxMax(2) <= "0011100100";
letterGyMin(2) <= "0000011111";
letterGyMax(2) <= "0000100011";

letterGxMin(3) <= "0011010010";
letterGxMax(3) <= "0011100100";
letterGyMin(3) <= "0000110101";
letterGyMax(3) <= "0000111110";

letterGxMin(4) <= "0011011001";
letterGxMax(4) <= "0011100100";
letterGyMin(4) <= "0000100111";
letterGyMax(4) <= "0000110100";

letterGxMin(5) <= "0011010110";
letterGxMax(5) <= "0011011001";
letterGyMin(5) <= "0000100111";
letterGyMax(5) <= "0000110001";
-- LETTER S
letterSxMin(0) <= "0100011011";
letterSxMax(0) <= "0100101101";
letterSyMin(0) <= "0000011010";
letterSyMax(0) <= "0000101100";

letterSxMin(1) <= "0100101101";
letterSxMax(1) <= "0100111110";
letterSyMin(1) <= "0000011010";
letterSyMax(1) <= "0000011111";

letterSxMin(2) <= "0100110101";
letterSxMax(2) <= "0100111110";
letterSyMin(2) <= "0000011111";
letterSyMax(2) <= "0000100011";

letterSxMin(3) <= "0100101101";
letterSxMax(3) <= "0100111110";
letterSyMin(3) <= "0000100111";
letterSyMax(3) <= "0000101100";

letterSxMin(4) <= "0100110110";
letterSxMax(4) <= "0100111110";
letterSyMin(4) <= "0000101011";
letterSyMax(4) <= "0000111110";

letterSxMin(5) <= "0100011011";
letterSxMax(5) <= "0100111110";
letterSyMin(5) <= "0000110101";
letterSyMax(5) <= "0000111110";

letterSxMin(6) <= "0100011011";
letterSxMax(6) <= "0100101101";
letterSyMin(6) <= "0000110000";
letterSyMax(6) <= "0000110100";
-- LETTER L
letterLxMin(0) <= "0110011100";
letterLxMax(0) <= "0110101110";
letterLyMin(0) <= "0000011010";
letterLyMax(0) <= "0000111110";

letterLxMin(1) <= "0110011100";
letterLxMax(1) <= "0111000000";
letterLyMin(1) <= "0000110101";
letterLyMax(1) <= "0000111110";

letterLxMin(2) <= "0110111000";
letterLxMax(2) <= "0111000000";
letterLyMin(2) <= "0000110000";
letterLyMax(2) <= "0000111110";

-- LETTER I
letterIxMin(0) <= "0111001110";
letterIxMax(0) <= "0111100000";
letterIyMin(0) <= "0000011010";
letterIyMax(0) <= "0000111110";

letterIxMin(1) <= "0111000101";
letterIxMax(1) <= "0111101001";
letterIyMin(1) <= "0000011010";
letterIyMax(1) <= "0000100000";

letterIxMin(2) <= "0111000101";
letterIxMax(2) <= "0111101001";
letterIyMin(2) <= "0000110101";
letterIyMax(2) <= "0000111110";

-- LETTER M
letterMxMin(0) <= "0111101100";
letterMxMax(0) <= "0111111010";
letterMyMin(0) <= "0000011010";
letterMyMax(0) <= "0000111110";

letterMxMin(1) <= "0111111011";
letterMxMax(1) <= "0111111111";
letterMyMin(1) <= "0000011110";
letterMyMax(1) <= "0000110001";

letterMxMin(2) <= "0111111111";
letterMxMax(2) <= "1000000011";
letterMyMin(2) <= "0000100011";
letterMyMax(2) <= "0000110101";

letterMxMin(3) <= "1000000011";
letterMxMax(3) <= "1000000111";
letterMyMin(3) <= "0000011110";
letterMyMax(3) <= "0000110001";

letterMxMin(4) <= "1000001000";
letterMxMax(4) <= "1000010000";
letterMyMin(4) <= "0000011010";
letterMyMax(4) <= "0000111110";

-- LETTER B
letterBxMin(0) <= "1000010101";
letterBxMax(0) <= "1000110000";
letterByMin(0) <= "0000011010";
letterByMax(0) <= "0000011110";

letterBxMin(1) <= "1000010101";
letterBxMax(1) <= "1000100111";
letterByMin(1) <= "0000011010";
letterByMax(1) <= "0000111110";

letterBxMin(2) <= "1000101000";
letterBxMax(2) <= "1000110100";
letterByMin(2) <= "0000110101";
letterByMax(2) <= "0000111110";

letterBxMin(3) <= "1000110101";
letterBxMax(3) <= "1000111010";
letterByMin(3) <= "0000110000";
letterByMax(3) <= "0000111010";

letterBxMin(4) <= "1000101111";
letterBxMax(4) <= "1000110101";
letterByMin(4) <= "0000101011";
letterByMax(4) <= "0000110100";

letterBxMin(5) <= "1000101000";
letterBxMax(5) <= "1000110000";
letterByMin(5) <= "0000100111";
letterByMax(5) <= "0000101011";

letterBxMin(6) <= "1000101011";
letterBxMax(6) <= "1000110100";
letterByMin(6) <= "0000011111";
letterByMax(6) <= "0000100110";

  --Frame Start Process
  frame_start : process(hc, vc)
  begin
	if ( (hc = "0000000000") and (vc = "0000000000") ) then
		fStart <= '1';
	else
		fStart <= '0';
	end if;
  end process;		

  --This cuts the 50 Mhz clock in half to generate a 25 MHz pixel clock
  process(clk, reset)
  begin
    if (reset = '1') then
      clkdiv <= '0';
    elsif (rising_edge(clk)) then
      clkdiv <= not clkdiv;
    end if;
  end process;

  --Runs the horizontal counter  when it resets vertical counter is incremented
  counter_proc : process(clkdiv, reset)
  begin
    if (reset = '1') then
      hc <= "0000000000";
      vc <= "0000000000";
    elsif (rising_edge(clkdiv)) then
      if (hc = hpixels) then    --If hc has reached the end of pixel count
        hc <= "0000000000";
        if (vc = vlines) then      -- if vc has reached end of line count
          vc <= "0000000000";
        else
          vc <= vc + 1;
        end if;
      else
        hc <= hc + 1; -- no statement about vc, implied vc <= vc;
      end if;
    end if;
  end process;
  
  DrawXSig <= hc;
  DrawYSig <= vc;

  -- horizontal sync pulse is 96 pixels long at pixels 656-752
  -- (signal is registered to ensure clean output waveform)
  hsync_proc : process (reset, clkdiv, hc)
  begin
    if (reset = '1') then
      hs <= '0';
    elsif (rising_edge(clkdiv)) then
      if ((hc + 1) >= "1010010000" and (hc + 1) < "1011110000") then -- must check next value of hc
        hs <= '0';
      else
        hs <= '1';
      end if;
    end if;
  end process;

  -- vertical sync pulse is 2 lines(800 pixels) long at line 490-491
  --   (signal is registered to ensure clean output waveform)
  vsync_proc : process(reset, clkdiv, vc)
  begin
    if (reset = '1') then
      vs <= '0';
    elsif (rising_edge(clkdiv)) then
      if ((vc + 1) = "111101010" or (vc + 1) = "111101011") then -- must check next value of vc
        vs <= '0';
      else
        vs <= '1';
      end if;
    end if;
  end process;

  -- only display pixels between horizontal 0-639 and vertical 0-479 (640x480)
  -- (This signal is registered within the DAC chip, so we can leave it as pure combinational logic here)
  blank_proc : process(hc, vc)
  begin
    if  ((hc >= "1010000000") or (vc >= "0111100000")) then
      display <= '0';
    else
      display <= '1';
    end if;
  end process;
  
  blank <= display;
  pixel_clk <= clkdiv;
  
  
  
 ---------------- draw scene
 draw_scene : process(Reset, DrawXSig, DrawYSig, xPlat, yPlat1, yPlat2, xGuy, yGuy, drawPlat, platWidth)
	begin		
		for i in 0 to 7 loop
			
				-- First check if the platforms exist, and if they do set a drawPlat flag
				if ( (yPlat1(i) > "0") or (yPlat2(i) > "0")) then
					drawPlat <= '1';
				end if;
				
				
				-------------------------------------------------------
				-- The first prority in the draw scene is the platforms
				-- If the current pixel drawing signal is within any of the correct locations of a platform,
				-- set the RGB values to those of the correct sprite pixel
				-------------------------------------------------------
				if(((DrawXSig > xPlat(0) - platWidth) and (DrawXSig < xPlat(0) + platWidth)) and
					(( DrawYSig > yPlat1(0) - platHeight) and (DrawYSig < yPlat1(0) + platHeight)) and
					drawPlat = '1') then  --  DRAW COLUMN 0
					
						platX <= (DrawXsig - (xPlat(0) - platWidth));
						platY <= (DrawYsig - (yPlat1(0) - platHeight));								
						Red <= platRed;
						Green <= platGreen;
						Blue <= platBlue;
				elsif(((DrawXSig > xPlat(1) - platWidth) and (DrawXSig < xPlat(1) + platWidth)) and
					(( DrawYSig > yPlat1(1) - platHeight) and (DrawYSig < yPlat1(1) + platHeight)) and
					drawPlat = '1') then -- DRAW COLUMN 1
					
						platX <= (DrawXsig - (xPlat(1) - platWidth));
						platY <= (DrawYsig - (yPlat1(1) - platHeight));								
						Red <= platRed;
						Green <= platGreen;
						Blue <= platBlue;
				elsif(((DrawXSig > xPlat(2) - platWidth) and (DrawXSig < xPlat(2) + platWidth)) and
					(( DrawYSig > yPlat1(2) - platHeight) and (DrawYSig < yPlat1(2) + platHeight)) and
					drawPlat = '1') then -- DRAW COLUMN 2
					
						platX <= (DrawXsig - (xPlat(2) - platWidth));
						platY <= (DrawYsig - (yPlat1(2) - platHeight));								
						Red <= platRed;
						Green <= platGreen;
						Blue <= platBlue;
				elsif(((DrawXSig > xPlat(3) - platWidth) and (DrawXSig < xPlat(3) + platWidth)) and
					(( DrawYSig > yPlat1(3) - platHeight) and (DrawYSig < yPlat1(3) + platHeight)) and
					drawPlat = '1') then -- DRAW COLUMN 3
					
						platX <= (DrawXsig - (xPlat(3) - platWidth));
						platY <= (DrawYsig - (yPlat1(3) - platHeight));								
						Red <= platRed;
						Green <= platGreen;
						Blue <= platBlue;
				elsif(((DrawXSig > xPlat(4) - platWidth) and (DrawXSig < xPlat(4) + platWidth)) and
					(( DrawYSig > yPlat1(4) - platHeight) and (DrawYSig < yPlat1(4) + platHeight)) and
					drawPlat = '1') then --  DRAW COLUMN 4
						platX <= (DrawXsig - (xPlat(4) - platWidth));
						platY <= (DrawYsig - (yPlat1(4) - platHeight));								
						Red <= platRed;
						Green <= platGreen;
						Blue <= platBlue;
				elsif(((DrawXSig > xPlat(5) - platWidth) and (DrawXSig < xPlat(5) + platWidth)) and
					(( DrawYSig > yPlat1(5) - platHeight) and (DrawYSig < yPlat1(5) + platHeight)) and
					drawPlat = '1') then -- COLUMN 5
						platX <= (DrawXsig - (xPlat(5) - platWidth));
						platY <= (DrawYsig - (yPlat1(5) - platHeight));								
						Red <= platRed;
						Green <= platGreen;
						Blue <= platBlue;
				elsif(((DrawXSig > xPlat(6) - platWidth) and (DrawXSig < xPlat(6) + platWidth)) and
					(( DrawYSig > yPlat1(6) - platHeight) and (DrawYSig < yPlat1(6) + platHeight)) and
					drawPlat = '1') then -- COLUMN 6
						platX <= (DrawXsig - (xPlat(6) - platWidth));
						platY <= (DrawYsig - (yPlat1(6) - platHeight));								
						Red <= platRed;
						Green <= platGreen;
						Blue <= platBlue;
				elsif(((DrawXSig > xPlat(7) - platWidth) and (DrawXSig < xPlat(7) + platWidth)) and
					(( DrawYSig > yPlat1(7) - platHeight) and (DrawYSig < yPlat1(7) + platHeight)) and
					drawPlat = '1') then -- COLUMN 7
					
						platX <= (DrawXsig - (xPlat(7) - platWidth));
						platY <= (DrawYsig - (yPlat1(7) - platHeight));								
						Red <= platRed;
						Green <= platGreen;
						Blue <= platBlue;
				
				
				-------------------second group
				elsif(((DrawXSig > xPlat(0) - platWidth) and (DrawXSig < xPlat(0) + platWidth)) and
					(( DrawYSig > yPlat2(0) - platHeight) and (DrawYSig < yPlat2(0) + platHeight)) and
					drawPlat = '1') then  --  DRAW COLUMN 0
					
						platX <= (DrawXsig - (xPlat(0) - platWidth));
						platY <= (DrawYsig - (yPlat2(0) - platHeight));								
						Red <= platRed;
						Green <= platGreen;
						Blue <= platBlue;
				elsif(((DrawXSig > xPlat(1) - platWidth) and (DrawXSig < xPlat(1) + platWidth)) and
					(( DrawYSig > yPlat2(1) - platHeight) and (DrawYSig < yPlat2(1) + platHeight)) and
					drawPlat = '1') then -- DRAW COLUMN 1
					
						platX <= (DrawXsig - (xPlat(1) - platWidth));
						platY <= (DrawYsig - (yPlat2(1) - platHeight));								
						Red <= platRed;
						Green <= platGreen;
						Blue <= platBlue;
				elsif(((DrawXSig > xPlat(2) - platWidth) and (DrawXSig < xPlat(2) + platWidth)) and
					(( DrawYSig > yPlat2(2) - platHeight) and (DrawYSig < yPlat2(2) + platHeight)) and
					drawPlat = '1') then -- DRAW COLUMN 2
					
						platX <= (DrawXsig - (xPlat(2) - platWidth));
						platY <= (DrawYsig - (yPlat2(2) - platHeight));								
						Red <= platRed;
						Green <= platGreen;
						Blue <= platBlue;
				elsif(((DrawXSig > xPlat(3) - platWidth) and (DrawXSig < xPlat(3) + platWidth)) and
					(( DrawYSig > yPlat2(3) - platHeight) and (DrawYSig < yPlat2(3) + platHeight)) and
					drawPlat = '1') then -- DRAW COLUMN 3
					
						platX <= (DrawXsig - (xPlat(3) - platWidth));
						platY <= (DrawYsig - (yPlat2(3) - platHeight));								
						Red <= platRed;
						Green <= platGreen;
						Blue <= platBlue;
				elsif(((DrawXSig > xPlat(4) - platWidth) and (DrawXSig < xPlat(4) + platWidth)) and
					(( DrawYSig > yPlat2(4) - platHeight) and (DrawYSig < yPlat2(4) + platHeight)) and
					drawPlat = '1') then --  DRAW COLUMN 4
						platX <= (DrawXsig - (xPlat(4) - platWidth));
						platY <= (DrawYsig - (yPlat2(4) - platHeight));								
						Red <= platRed;
						Green <= platGreen;
						Blue <= platBlue;
				elsif(((DrawXSig > xPlat(5) - platWidth) and (DrawXSig < xPlat(5) + platWidth)) and
					(( DrawYSig > yPlat2(5) - platHeight) and (DrawYSig < yPlat2(5) + platHeight)) and
					drawPlat = '1') then -- COLUMN 5
						platX <= (DrawXsig - (xPlat(5) - platWidth));
						platY <= (DrawYsig - (yPlat2(5) - platHeight));								
						Red <= platRed;
						Green <= platGreen;
						Blue <= platBlue;
				elsif(((DrawXSig > xPlat(6) - platWidth) and (DrawXSig < xPlat(6) + platWidth)) and
					(( DrawYSig > yPlat2(6) - platHeight) and (DrawYSig < yPlat2(6) + platHeight)) and
					drawPlat = '1') then -- COLUMN 6
						platX <= (DrawXsig - (xPlat(6) - platWidth));
						platY <= (DrawYsig - (yPlat2(6) - platHeight));								
						Red <= platRed;
						Green <= platGreen;
						Blue <= platBlue;
				elsif(((DrawXSig > xPlat(7) - platWidth) and (DrawXSig < xPlat(7) + platWidth)) and
					(( DrawYSig > yPlat2(7) - platHeight) and (DrawYSig < yPlat2(7) + platHeight)) and
					drawPlat = '1') then -- COLUMN 7
					
						platX <= (DrawXsig - (xPlat(7) - platWidth));
						platY <= (DrawYsig - (yPlat2(7) - platHeight));								
						Red <= platRed;
						Green <= platGreen;
						Blue <= platBlue;
				
				-------------------------------------------------------
				-- The second prority in the draw scene is the bananas
				-- If the current pixel drawing signal is within the correct location of the banana,
				-- set the RGB values to those of the correct sprite pixel
				-------------------------------------------------------		
				elsif( ((DrawXSig >	banPosX - banWidth) and (DrawXSig < banPosX + banWidth)) and ((DrawYsig > banPosY - banHeight) and (DrawYsig < banPosY + banHeight))) then
						bananaX <= (DrawXsig - (banPosX - banWidth));
						bananaY <= (DrawYsig - (banPosY - banHeight));								
						Red <= bananaRed;
						Green <= bananaGreen;
						Blue <= bananaBlue;
							
				-------------------------------------------------------
				-- The third prority in the draw scene is Congo
				-- If the current pixel drawing signal is within Congos location,
				-- set the RGB values to those of the correct sprite pixel
				-------------------------------------------------------
				elsif( ((DrawXSig > xGuy - sGuy) and (DrawXSig < xGuy + sGuy)) and
					((DrawYSig > yGuy - sGuy) and (DrawYSig < yGuy + Sguy))) then -- draw CONGO
							
							congX <= (DrawXSig - (xGuy - sGuy));
							congY <= (DrawYsig - (yGuy - sGuy));
							
							Red <= congRed;
							Green <= congGreen;
							Blue <= congBlue;
				-------------------------------------------------------
				-- The fourth prority in the draw scene is the title CONGOS CLIMB
				-- If the current pixel drawing signal is within any of the correct bounds of the block rectangles
				-- set the RGB values to those of the title color
				-------------------------------------------------------
				elsif( 	-- LETTER C
						((DrawXSig >= letterCxMin(0) and DrawXSig <= letterCxMax(0)) and (DrawYSig >= letterCyMin(0) and DrawYSig <= letterCyMax(0))) or
					   ((DrawXSig >= letterCxMin(1) and DrawXSig <= letterCxMax(1)) and (DrawYSig >= letterCyMin(1) and DrawYSig <= letterCyMax(1))) or					
					   ((DrawXSig >= letterCxMin(2) and DrawXSig <= letterCxMax(2)) and (DrawYSig >= letterCyMin(2) and DrawYSig <= letterCyMax(2))) or
					   ((DrawXSig >= letterCxMin(3) and DrawXSig <= letterCxMax(3)) and (DrawYSig >= letterCyMin(3) and DrawYSig <= letterCyMax(3))) or
					   ((DrawXSig >= letterCxMin(4) and DrawXSig <= letterCxMax(4)) and (DrawYSig >= letterCyMin(4) and DrawYSig <= letterCyMax(4))) or
					   
					   --letter O
					   ((DrawXSig >= letterOxMin(0) and DrawXSig <= letterOxMax(0)) and (DrawYSig >= letterOyMin(0) and DrawYSig <= letterOyMax(0))) or
					   ((DrawXSig >= letterOxMin(1) and DrawXSig <= letterOxMax(1)) and (DrawYSig >= letterOyMin(1) and DrawYSig <= letterOyMax(1))) or					
					   ((DrawXSig >= letterOxMin(2) and DrawXSig <= letterOxMax(2)) and (DrawYSig >= letterOyMin(2) and DrawYSig <= letterOyMax(2))) or
					   ((DrawXSig >= letterOxMin(3) and DrawXSig <= letterOxMax(3)) and (DrawYSig >= letterOyMin(3) and DrawYSig <= letterOyMax(3))) or
					   -- LETTER N
					   ((DrawXSig >= letterNxMin(0) and DrawXSig <= letterNxMax(0)) and (DrawYSig >= letterNyMin(0) and DrawYSig <= letterNyMax(0))) or
					   ((DrawXSig >= letterNxMin(1) and DrawXSig <= letterNxMax(1)) and (DrawYSig >= letterNyMin(1) and DrawYSig <= letterNyMax(1))) or
					   ((DrawXSig >= letterNxMin(2) and DrawXSig <= letterNxMax(2)) and (DrawYSig >= letterNyMin(2) and DrawYSig <= letterNyMax(2))) or
					   ((DrawXSig >= letterNxMin(3) and DrawXSig <= letterNxMax(3)) and (DrawYSig >= letterNyMin(3) and DrawYSig <= letterNyMax(3))) or
					   ((DrawXSig >= letterNxMin(4) and DrawXSig <= letterNxMax(4)) and (DrawYSig >= letterNyMin(4) and DrawYSig <= letterNyMax(4))) or
					   ((DrawXSig >= letterNxMin(5) and DrawXSig <= letterNxMax(5)) and (DrawYSig >= letterNyMin(5) and DrawYSig <= letterNyMax(5))) or
					   ((DrawXSig >= letterNxMin(6) and DrawXSig <= letterNxMax(6)) and (DrawYSig >= letterNyMin(6) and DrawYSig <= letterNyMax(6))) or
					   -- LETTER G
					   ((DrawXSig >= letterGxMin(0) and DrawXSig <= letterGxMax(0)) and (DrawYSig >= letterGyMin(0) and DrawYSig <= letterGyMax(0))) or
					   ((DrawXSig >= letterGxMin(1) and DrawXSig <= letterGxMax(1)) and (DrawYSig >= letterGyMin(1) and DrawYSig <= letterGyMax(1))) or
					   ((DrawXSig >= letterGxMin(2) and DrawXSig <= letterGxMax(2)) and (DrawYSig >= letterGyMin(2) and DrawYSig <= letterGyMax(2))) or
					   ((DrawXSig >= letterGxMin(3) and DrawXSig <= letterGxMax(3)) and (DrawYSig >= letterGyMin(3) and DrawYSig <= letterGyMax(3))) or
					   ((DrawXSig >= letterGxMin(4) and DrawXSig <= letterGxMax(4)) and (DrawYSig >= letterGyMin(4) and DrawYSig <= letterGyMax(4))) or
					   ((DrawXSig >= letterGxMin(5) and DrawXSig <= letterGxMax(5)) and (DrawYSig >= letterGyMin(5) and DrawYSig <= letterGyMax(5))) or
					   --LETTER O
					   ((DrawXSig >= (letterOxMin(0) + "1111010") and DrawXSig <= (letterOxMax(0) + "1111010")) and (DrawYSig >= letterOyMin(0) and DrawYSig <= letterOyMax(0))) or
					   ((DrawXSig >= (letterOxMin(1) + "1111010") and DrawXSig <= (letterOxMax(1) + "1111010")) and (DrawYSig >= letterOyMin(1) and DrawYSig <= letterOyMax(1))) or					
					   ((DrawXSig >= (letterOxMin(2) + "1111010") and DrawXSig <= (letterOxMax(2) + "1111010")) and (DrawYSig >= letterOyMin(2) and DrawYSig <= letterOyMax(2))) or
					   ((DrawXSig >= (letterOxMin(3) + "1111010") and DrawXSig <= (letterOxMax(3) + "1111010")) and (DrawYSig >= letterOyMin(3) and DrawYSig <= letterOyMax(3))) or
					   -- APOS (')
					   ((DrawXSig >= "100010011" and DrawXSig <= "100010111") and (DrawYSig >= "11010" and DrawYSig <= "100011")) or
					   --LETTER S
					   ((DrawXSig >= letterSxMin(0) and DrawXSig <= letterSxMax(0)) and (DrawYSig >= letterSyMin(0) and DrawYSig <= letterSyMax(0))) or
					   ((DrawXSig >= letterSxMin(1) and DrawXSig <= letterSxMax(1)) and (DrawYSig >= letterSyMin(1) and DrawYSig <= letterSyMax(1))) or
					   ((DrawXSig >= letterSxMin(2) and DrawXSig <= letterSxMax(2)) and (DrawYSig >= letterSyMin(2) and DrawYSig <= letterSyMax(2))) or
					   ((DrawXSig >= letterSxMin(3) and DrawXSig <= letterSxMax(3)) and (DrawYSig >= letterSyMin(3) and DrawYSig <= letterSyMax(3))) or
					   ((DrawXSig >= letterSxMin(4) and DrawXSig <= letterSxMax(4)) and (DrawYSig >= letterSyMin(4) and DrawYSig <= letterSyMax(4))) or
					   ((DrawXSig >= letterSxMin(5) and DrawXSig <= letterSxMax(5)) and (DrawYSig >= letterSyMin(5) and DrawYSig <= letterSyMax(5))) or
					   ((DrawXSig >= letterSxMin(6) and DrawXSig <= letterSxMax(6)) and (DrawYSig >= letterSyMin(6) and DrawYSig <= letterSyMax(6))) or
					   					   
					   -- LETTER C
					   ((DrawXSig >= (letterCxMin(0) + "100101101") and DrawXSig <= (letterCxMax(0) + "100101101")) and (DrawYSig >= letterCyMin(0) and DrawYSig <= letterCyMax(0))) or
					   ((DrawXSig >= (letterCxMin(1) + "100101101") and DrawXSig <= (letterCxMax(1) + "100101101")) and (DrawYSig >= letterCyMin(1) and DrawYSig <= letterCyMax(1))) or					
					   ((DrawXSig >= (letterCxMin(2) + "100101101") and DrawXSig <= (letterCxMax(2) + "100101101")) and (DrawYSig >= letterCyMin(2) and DrawYSig <= letterCyMax(2))) or
					   ((DrawXSig >= (letterCxMin(3) + "100101101") and DrawXSig <= (letterCxMax(3) + "100101101")) and (DrawYSig >= letterCyMin(3) and DrawYSig <= letterCyMax(3))) or
					   ((DrawXSig >= (letterCxMin(4) + "100101101") and DrawXSig <= (letterCxMax(4) + "100101101")) and (DrawYSig >= letterCyMin(4) and DrawYSig <= letterCyMax(4))) or
					   -- LETTER L
					   ((DrawXSig >= letterLxMin(0) and DrawXSig <= letterLxMax(0)) and (DrawYSig >= letterLyMin(0) and DrawYSig <= letterLyMax(0))) or
					   ((DrawXSig >= letterLxMin(1) and DrawXSig <= letterLxMax(1)) and (DrawYSig >= letterLyMin(1) and DrawYSig <= letterLyMax(1))) or
					   ((DrawXSig >= letterLxMin(2) and DrawXSig <= letterLxMax(2)) and (DrawYSig >= letterLyMin(2) and DrawYSig <= letterLyMax(2))) or
					   -- LETTER I
					   ((DrawXSig >= letterIxMin(0) and DrawXSig <= letterIxMax(0)) and (DrawYSig >= letterIyMin(0) and DrawYSig <= letterIyMax(0))) or
					   ((DrawXSig >= letterIxMin(1) and DrawXSig <= letterIxMax(1)) and (DrawYSig >= letterIyMin(1) and DrawYSig <= letterIyMax(1))) or
					   ((DrawXSig >= letterIxMin(2) and DrawXSig <= letterIxMax(2)) and (DrawYSig >= letterIyMin(2) and DrawYSig <= letterIyMax(2))) or
					   -- LETTER M
					   ((DrawXSig >= letterMxMin(0) and DrawXSig <= letterMxMax(0)) and (DrawYSig >= letterMyMin(0) and DrawYSig <= letterMyMax(0))) or
					   ((DrawXSig >= letterMxMin(1) and DrawXSig <= letterMxMax(1)) and (DrawYSig >= letterMyMin(1) and DrawYSig <= letterMyMax(1))) or
					   ((DrawXSig >= letterMxMin(2) and DrawXSig <= letterMxMax(2)) and (DrawYSig >= letterMyMin(2) and DrawYSig <= letterMyMax(2))) or
					   ((DrawXSig >= letterMxMin(3) and DrawXSig <= letterMxMax(3)) and (DrawYSig >= letterMyMin(3) and DrawYSig <= letterMyMax(3))) or
					   ((DrawXSig >= letterMxMin(4) and DrawXSig <= letterMxMax(4)) and (DrawYSig >= letterMyMin(4) and DrawYSig <= letterMyMax(4))) or
					   -- LETTER B
					   ((DrawXSig >= letterBxMin(0) and DrawXSig <= letterBxMax(0)) and (DrawYSig >= letterByMin(0) and DrawYSig <= letterByMax(0))) or
					   ((DrawXSig >= letterBxMin(1) and DrawXSig <= letterBxMax(1)) and (DrawYSig >= letterByMin(1) and DrawYSig <= letterByMax(1))) or
					   ((DrawXSig >= letterBxMin(2) and DrawXSig <= letterBxMax(2)) and (DrawYSig >= letterByMin(2) and DrawYSig <= letterByMax(2))) or
					   ((DrawXSig >= letterBxMin(3) and DrawXSig <= letterBxMax(3)) and (DrawYSig >= letterByMin(3) and DrawYSig <= letterByMax(3))) or
					   ((DrawXSig >= letterBxMin(4) and DrawXSig <= letterBxMax(4)) and (DrawYSig >= letterByMin(4) and DrawYSig <= letterByMax(4))) or
					   ((DrawXSig >= letterBxMin(5) and DrawXSig <= letterBxMax(5)) and (DrawYSig >= letterByMin(5) and DrawYSig <= letterByMax(5))) or
					   ((DrawXSig >= letterBxMin(6) and DrawXSig <= letterBxMax(6)) and (DrawYSig >= letterByMin(6) and DrawYSig <= letterByMax(6)))
					) then
					Red <= "1010100100";
					Green <= "1001010000";
					Blue <= "0110100100";	
				-------------------------------------------------------
				-- The last prority in the draw scene is the baclground
				-- If there is nothing of higher priority in the current pixel location, draw the background
				-- which is a single color, forest green
				-------------------------------------------------------	
				else
					Red <= "0000100100";
					Green <= "0010000100";
					Blue <= "0000000000";
				end if;
			end loop;	
	end process draw_scene; 


congoSprite_instance : guySpriter
    Port Map( x	=>	congX,   -- inner vector position ( pixel data)       
              y =>	congY,	-- outer array index(rows)
              dir => dirReg,
           
           Red	=> congRed,
           Green => congGreen,	
           Blue	=> congBlue);	
           
platformSprite_instance : platformSpriter 
    Port Map ( x => platX,       
           y	=> platY,
           
           
           Red	=> platRed,
           Green =>	platGreen,
           Blue	=>	platBlue);             	           	

bananaSprite_instance : bananaSpriter 
    Port Map ( x => bananaX,       
           y	=> bananaY,
           
           
           Red	=> bananaRed,
           Green =>	bananaGreen,
           Blue	=>	bananaBlue);	             	           	

end Behavorial;    
