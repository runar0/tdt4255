library ieee;
use ieee.std_logic_1164.all;

use work.mips_constant_pkg.all;
use work.pipeline_types.all;

entity stage_ex is
	generic (
		N: natural := 32
	);
	port (
		input     : in idex_t;
		
		-- Forwarding control signals and data
		forwarding_a : in std_logic_vector(1 downto 0);
		forwarding_b : in std_logic_vector(1 downto 0);
		ex_mem_rd    : in std_logic_vector(N-1 downto 0);
		mem_wb_rd    : in std_logic_vector(N-1 downto 0);
		
		reg_values_equal : out std_logic;
		
		flush : out std_logic;
		pc_corrected : out std_logic_vector(N-1 downto 0);
		
		output: out exmem_t
	);
end stage_ex; 

architecture behavorial of stage_ex is

	-- instantiating components
	 component alu is
        generic (N : natural := 32);
        port (
            x : in std_logic_vector(N-1 downto 0);
            y : in std_logic_vector(N-1 downto 0);
            alu_in : in ALU_INPUT;
            r : out std_logic_vector(N-1 downto 0);
            flags : out ALU_FLAGS
        );
    end component;

	component alu_control is
        port (
            alu_op : in ALU_OP;
            func : in STD_LOGIC_VECTOR (5 downto 0);
            alu_func : out ALU_INPUT
        );
    end component;

	-- ALU control signals
	signal alu_input 			: ALU_INPUT;
	
	-- Internal reg 1 and 2 signals after forwarding
	signal reg_1_internal : std_logic_vector (N-1 downto 0);
	signal reg_2_internal : std_logic_vector (N-1 downto 0);
	
	-- Final ALU B input after alusrc mux	
	signal alu_b_in         : std_logic_vector (N-1 downto 0);
	
	signal equals : std_logic;
	
	begin
	-- signal relaying
	output.ctrl_wb 		  <= input.ctrl_wb;
	output.ctrl_m 		  <= input.ctrl_m;
	output.write_mem_data <= reg_2_internal;
	
	-- ALU control unit
	alu_ctrl: alu_control
		port map (
			-- ALU_OP comes from control unit, function from instruction
			alu_op 		=> input.ctrl_ex.alu_op,
			func		=> input.sign_extended (5 downto 0),
			
			-- control outputs
			alu_func 	=> alu_input
		);
		
	-- ALU
	alu1: alu
		port map (
			x 		=> reg_1_internal,
			y 		=> alu_b_in,
			alu_in 	=> alu_input,
			r 		=> output.alu_result,
			flags  	=> output.flags
		);
		
	-- Forwarding ALU A input mux
	alu_forward_a_in_mux : process(input.reg1, forwarding_a, ex_mem_rd, mem_wb_rd)
	begin
		case forwarding_a is
			when "10" =>
				reg_1_internal <= ex_mem_rd;
			when "01" =>
				reg_1_internal <= mem_wb_rd;
			when others =>
				reg_1_internal <= input.reg1;
		end case;
	end process;
		
	-- ALU B input mux
	alu_forward_b_in_mux : process(input.reg2, forwarding_b, ex_mem_rd, mem_wb_rd)
	begin
		case forwarding_b is 
			when "10" =>
				reg_2_internal <= ex_mem_rd;
			when "01" =>
				reg_2_internal <= mem_wb_rd;
			when others =>
				reg_2_internal <= input.reg2;
		end case;
	end process;			
		
	-- ALU src mux
	alu_input_mux: process(reg_2_internal, input.sign_extended, input.ctrl_ex.alu_src)
	begin
		if input.ctrl_ex.alu_src = '0' then
			alu_b_in <= reg_2_internal;
		else 
			alu_b_in <= input.sign_extended;
		end if;
	end process;
	
	reg_write_mux: process(input.read_reg_rt_addr, input.write_reg_rd_addr, input.ctrl_ex.reg_dst)
	begin
		if input.ctrl_ex.reg_dst = '0' then
			output.write_reg_addr <= input.read_reg_rt_addr;
		else 
			output.write_reg_addr <= input.write_reg_rd_addr;
		end if;
	end process;
	
	equals <= '1' when (reg_1_internal xor reg_2_internal) = X"00000000" else '0';
	reg_values_equal <= equals;
	
	branch_correction: process( input.ctrl_ex.branch, equals, input.predict_taken )
	begin
		if input.ctrl_ex.branch = '1' then
				
			if equals /= input.predict_taken then
				flush <= '1';
				
				if equals = '1' then
					pc_corrected <= input.branch_target;
				else 
					pc_corrected <= input.pc_incremented;
				end if;
				
			else
				flush <= '0';
				pc_corrected <= (others => '0');
		   end if;
		else
			flush <= '0';
			pc_corrected <= (others => '0');
		end if;	
	end process;
	
end architecture;
