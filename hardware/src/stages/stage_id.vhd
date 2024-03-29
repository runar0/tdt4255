library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.mips_constant_pkg.all;
use work.pipeline_types.all;

entity stage_id is
	generic (
		N : integer := 32);
	port (
		-- Component Control
		clk : in std_logic;
		reset : in std_logic;

		stall : in std_logic;
		flush : in std_logic;
		
		predict_taken : in std_logic;
		jump_target : out std_logic_vector(N-1 downto 0);
		
		-- Write Back
		wb : in wb_t;
		-- Stage Input
		ifid : in ifid_t;
		-- Stage Output
		idex : out idex_t;
		
		-- Forwarding signals
		forwarding_C : in std_logic;
		forwarding_D : in std_logic
		);
end stage_id;

architecture Behavioral of stage_id is

	component control_unit is
		port (
        opcode     : in std_logic_vector (5 DOWNTO 0);
				
				ctrl_ex    : out ctrl_ex_t;
				ctrl_m     : out ctrl_m_t;
				ctrl_wb    : out ctrl_wb_t
		);
	end component;

	component register_file is
		port (
		clk        : in std_logic;
		reset      : in std_logic;
		rw         : in std_logic;
		rs_addr    : in std_logic_vector (RADDR_BUS-1 downto 0);
		rt_addr    : in std_logic_vector (RADDR_BUS-1 downto 0);
		rd_addr    : in std_logic_vector (RADDR_BUS-1 downto 0);
		write_data : in std_logic_vector (DDATA_BUS-1 downto 0);
		rs         : out std_logic_vector (DDATA_BUS-1 downto 0);
		rt         : out std_logic_vector (DDATA_BUS-1 downto 0)
	);
	end component;

	component sign_extend is
		port (
			a : in std_logic_vector(15 downto 0);
			r : out std_logic_vector(N-1 downto 0)
		);
	end component;

	component adder is         
		generic (
			N: natural := 32
		);
		port(
			x    : in std_logic_vector (N-1 downto 0);
			y    : in std_logic_vector (N-1 downto 0);
			cin  : in std_logic;
			cout : out std_logic;
			r    : out std_logic_vector (N-1 downto 0)
		);
	end component;

	signal sign_extended : std_logic_vector(N-1 downto 0);

	signal ctrl_ex : ctrl_ex_t;
	signal ctrl_m  : ctrl_m_t;
	signal ctrl_wb : ctrl_wb_t;
	
	signal reg1, reg2 : std_logic_vector(N-1 downto 0);
	
	signal forwarded_reg1, forwarded_reg2 : std_logic_vector(N-1 downto 0);

begin

	cu: control_unit
		port map (
			-- Component Control
			opcode     => ifid.instruction(31 downto 26),

			-- Control signals
			ctrl_ex    => ctrl_ex,
			ctrl_m     => ctrl_m,
			ctrl_wb    => ctrl_wb
		);

	rf : register_file
		port map (
			-- Component Control
			clk        => clk,
			reset      => reset,

			-- Write back
			rw         => wb.reg_write,
			write_data => wb.write_data,
			rd_addr    => wb.write_addr,

			-- Read register
			rs_addr    => ifid.instruction(25 downto 21),
			rt_addr    => ifid.instruction(20 downto 16),
			rs         => reg1,
			rt         => reg2
		);

	se : sign_extend
		port map(
			a => ifid.instruction(15 downto 0),
			r => sign_extended
		);

	branch: adder
		port map (
			x => ifid.pc_incremented,
			y => sign_extended,
			cin => '0',
			r => idex.branch_target
		);

	process(stall, flush, ctrl_ex, ctrl_m, ctrl_wb)
	begin
		if stall = '0' and flush = '0' then
			idex.ctrl_ex <= ctrl_ex;
			idex.ctrl_m  <= ctrl_m;
			idex.ctrl_wb <= ctrl_wb;
		else
			idex.ctrl_ex.alu_op <= ALUOP_FUNC;
			idex.ctrl_ex.reg_dst <= '0';
			idex.ctrl_ex.alu_src <= '0';
			idex.ctrl_ex.jump <= '0';
			idex.ctrl_ex.branch <= '0';
			idex.ctrl_m  <= (others => '0');
		   idex.ctrl_wb <= (others => '0');
		end if;
	end process;
	
	process(reg1, reg2, forwarding_C, forwarding_D, wb.write_data) 
	begin
		if forwarding_C = '1' then
			forwarded_reg1 <= wb.write_data;
		else
			forwarded_reg1 <= reg1;
		end if;
		if forwarding_D = '1' then
			forwarded_reg2 <= wb.write_data;
		else
			forwarded_reg2 <= reg2;
		end if;
	end process;
	
	idex.predict_taken <= predict_taken;
	idex.reg1 <= forwarded_reg1;
	idex.reg2 <= forwarded_reg2;
	
	-- Jump Target is High bits of PC concatenated with the address portion of
	-- the instruction
	jump_target   <= ifid.pc_incremented(31 downto 26) & ifid.instruction(25 downto 0);
	idex.sign_extended <= sign_extended;
	
	-- Assume R-type instructions, let execute handle this 
	idex.read_reg_rs_addr <= ifid.instruction(25 downto 21);
	idex.read_reg_rt_addr <= ifid.instruction(20 downto 16);
	idex.write_reg_rd_addr <= ifid.instruction(15 downto 11);
	
	idex.pc_current <= ifid.pc_current;
	idex.pc_incremented <= ifid.pc_incremented;
	
end Behavioral;
