library ieee;
use ieee.std_logic_1164.all;

use work.pipeline_types.all;

entity register_idex is
	port(
		input: in idex_t;
		clk  : in std_logic;
		reset  : in std_logic;
		
		output: out idex_t		
	);
end entity;

architecture Behaviour of register_idex is
begin
	latch : process(input, clk)
	begin
		if reset = '1' then
			-- Clear all damaging signals, in effect creating a noop
			output.ctrl_m <= (others => '0');
			output.ctrl_wb.reg_write <= '0';
		elsif rising_edge(clk) then
			output <= input;
		end if;
	end process;
end architecture;