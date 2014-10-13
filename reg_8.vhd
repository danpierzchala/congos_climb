library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity reg_8 is
	Port ( Clk : in std_logic;
		   Reset : in std_logic;
		   D : in std_logic_vector(7 downto 0);
		   Shift_In : in std_logic;
		   Load : in std_logic;
		   Shift_En : in std_logic;
		   Shift_Out : out std_logic;
		   Data_Out : out std_logic_vector(7 downto 0));
end reg_8;

architecture Behavioral of reg_8 is
signal reg_value: std_logic_vector(7 downto 0); 
begin
operate_reg: process(Load, Shift_En, Clk, Shift_In, Reset)
begin
	if(Reset = '1') then
		reg_value <= x"00";
	elsif(rising_edge(Clk)) then
		if(Shift_En = '1') then
			reg_value <= Shift_In & reg_value(7 downto 1);
			-- operator & concatenates two bit-fields
		elsif(Load='1') then
			reg_value <= D;
		else
			reg_value <= reg_value;
		end if;
	end if;
end process;
Data_Out <= reg_value;
Shift_Out <= reg_value(0);



end Behavioral;

