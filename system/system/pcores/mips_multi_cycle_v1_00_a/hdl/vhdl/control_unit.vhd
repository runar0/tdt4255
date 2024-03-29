
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.mips_constant_pkg.all;

entity control_unit is
    port ( 
        clk        : in std_logic;
        reset      : in std_logic; 
        opcode     : in std_logic_vector (5 DOWNTO 0);
        enable     : in std_logic;
        reg_dst    : out std_logic;
        branch     : out std_logic;
        mem_to_reg : out std_logic;
        alu_op     : out ALU_OP;
        mem_write  : out std_logic;
        alu_src    : out std_logic;
        reg_write  : out std_logic;
        jump       : out std_logic;
        pc_latch   : out std_logic := '0';
        link       : out std_logic
     );
end control_unit;

architecture Behavioral of control_unit is

    -- Control unit states
    type const_state is (STATE_FETCH, STATE_EXECUTE, STATE_STALL, STATE_RESET);
    signal state : const_state := STATE_RESET;
    signal next_state : const_state; 
    
    -- opcodes
    constant OP_ALU : std_logic_vector (5 downto 0) := "000000";
    constant OP_LW  : std_logic_vector (5 downto 0) := "100011";
    constant OP_SW  : std_logic_vector (5 downto 0) := "101011";
    constant OP_LUI : std_logic_vector (5 downto 0) := "001111";
    constant OP_BEQ : std_logic_vector (5 downto 0) := "000100";
    constant OP_J   : std_logic_vector (5 downto 0) := "000010";
    constant OP_JAL : std_logic_vector (5 downto 0) := "000011";

begin

    -- State machine control process
    control_unit_state_machine_control: process(clk, enable, reset)
    begin
        if rising_edge(clk) and enable = '1' then
            if reset = '1' then
                state <= STATE_RESET;
            else             
                 if next_state = STATE_FETCH and state /= STATE_RESET then
                    pc_latch <= '1';
                    state <= next_state;
                 else 
                    pc_latch <= '0';
                    state <= next_state;
                 end if;
            end if;
        end if;
    end process;
    
    -- Actual state machine
    control_unit_state_machine: process(state, opcode)
    begin
        case state is
            when STATE_FETCH =>
                mem_write <= '0';
                reg_write <= '0';
                
                next_state <= STATE_EXECUTE;
                
            when STATE_EXECUTE =>
                case opcode is
                    when OP_ALU =>
                        reg_dst <= '1';
                        branch <= '0';
                        mem_to_reg <= '0';
                        alu_op <= ALUOP_FUNC;
                        mem_write <= '0';
                        alu_src <= '0';
                        reg_write <= '1';
                        jump <= '0';
                        link <= '0';
                        
                        next_state <= STATE_FETCH;
                    
                    when OP_LW =>
                        reg_dst <= '0';
                        branch <= '0';
                        mem_to_reg <= '1';
                        alu_op <= ALUOP_LOAD_STORE;
                        mem_write <= '0';
                        alu_src <= '1';
                        reg_write <= '1';
                        jump <= '0';
                        link <= '0';
                        
                        next_state <= STATE_STALL;
                    
                    when OP_SW =>
                        reg_dst <= '0';
                        branch <= '0';
                        mem_to_reg <= '0';
                        alu_op <= ALUOP_LOAD_STORE;
                        mem_write <= '1';
                        alu_src <= '1';
                        reg_write <= '0';
                        jump <= '0';
                        link <= '0';
                        
                        next_state <= STATE_STALL;
                        
                    when OP_LUI =>
                        reg_dst <= '0';
                        branch <= '0';
                        mem_to_reg <= '0';
                        alu_op <= ALUOP_LDI;
                        mem_write <= '0';
                        alu_src <= '1';
                        reg_write <= '1';
                        jump <= '0';
                        link <= '0';
                                               
                        next_state <= STATE_FETCH;
                        
                    when OP_BEQ =>
                        reg_dst <= '1';
                        branch <= '1';
                        mem_to_reg <= '0';
                        alu_op <= ALUOP_BRANCH;
                        mem_write <= '0';
                        alu_src <= '0';
                        reg_write <= '0';
                        jump <= '0';
                        link <= '0';
                        
                        next_state <= STATE_FETCH;
                        
                    when OP_J =>
                        reg_dst <= '1';
                        branch <= '0';
                        mem_to_reg <= '0';
                        alu_op <= ALUOP_BRANCH;
                        mem_write <= '0';
                        alu_src <= '0';
                        reg_write <= '0';
                        jump <= '1';
                        link <= '0';
                        
                        next_state <= STATE_FETCH;

                    when OP_JAL =>
                        reg_dst <= '1';
                        branch <= '0';
                        mem_to_reg <= '0';
                        alu_op <= ALUOP_BRANCH;
                        mem_write <= '0';
                        alu_src <= '0';
                        reg_write <= '1';
                        jump <= '1';
                        link <= '1';

                        next_state <= STATE_FETCH;                        
                    
                    when others =>
                        reg_dst <= '0';
                        branch <= '0';
                        mem_to_reg <= '0';
                        alu_op <= ALUOP_FUNC;
                        mem_write <= '0';
                        alu_src <= '0';
                        reg_write <= '0';
                        jump <= '0';
                        link <= '0';
                        
                        next_state <= STATE_FETCH;                                
                end case;
                
            when STATE_STALL =>
                next_state <= STATE_FETCH;

            -- Initial state, and state after reset has been toggled, do no harm and enter FETCH
            when STATE_RESET =>      
                reg_dst <= '0';
                branch <= '0';
                mem_to_reg <= '0';
                alu_op <= ALUOP_FUNC;
                mem_write <= '0';
                alu_src <= '0';
                reg_write <= '0';
                jump <= '0';
                link <= '0';
                
                next_state <= STATE_FETCH;                     
                
        end case;
    end process;

end Behavioral;
