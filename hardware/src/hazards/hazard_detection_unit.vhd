library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.mips_constant_pkg.all;
use work.pipeline_types.all;

entity hazard_detection_unit is
	port (
		idex_rt : in std_logic_vector(4 downto 0);
		idex_mem_read : in std_logic;
		idex_jump : in std_logic;

		idex_branch : in std_logic;
		idex_predict_taken : in std_logic;

		ifid_rt : in std_logic_vector(4 downto 0);
		ifid_rs : in std_logic_vector(4 downto 0);

		stall : out std_logic;
		flush : out std_logic
	);
end hazard_detection_unit;

architecture Behavioral of hazard_detection_unit is

begin

	flush <= idex_jump or (idex_predict_taken and idex_branch);
	
	process(idex_rt, idex_mem_read, ifid_rt, ifid_rs)
	begin

		if idex_mem_read /= '1' then
				stall <= '0';
		else
			if (idex_rt = ifid_rs) or (idex_rt = ifid_rt) then
				stall <= '1';
			else
				stall <= '0';
			end if;
		end if;

	end process;

end Behavioral;
