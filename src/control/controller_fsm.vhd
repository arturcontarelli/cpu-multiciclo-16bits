library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity controller_fsm is
    port (
        clk    : in  std_logic;
        reset  : in  std_logic;
        opcode : in  opcode_t;

        PCWrite     : out std_logic;
        PCWriteCond : out std_logic;
        BNE         : out std_logic;
        IorD        : out std_logic;
        IRWrite     : out std_logic;
        MemRead     : out std_logic;
        MemWrite    : out std_logic;
        MemToReg    : out std_logic;
        RegWrite    : out std_logic;
        ALUSrcA     : out std_logic;
        ALUSrcB     : out std_logic_vector(1 downto 0);
        ALUOp       : out std_logic_vector(2 downto 0);
        PCSource    : out std_logic_vector(1 downto 0);
        led_state   : out std_logic_vector(4 downto 0)
    );
end entity controller_fsm;

architecture rtl of controller_fsm is

    type state_t is (
        st_fetch, st_decode,
        st_addr_calc, st_exec_r,
        st_mem_read, st_mem_write,
        st_wb_alu, st_wb_mem,
        st_branch, st_jump
    );

    signal current_state, next_state : state_t;

begin

    -- BNE nao depende do estado, so do opcode
    BNE <= '1' when opcode = OP_BNE else '0';

    -- processo 1: registrador de estado
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= st_fetch;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- processo 2: logica de transicao de estados
    process(current_state, opcode)
    begin
        case current_state is
            when st_fetch =>
                next_state <= st_decode;

            when st_decode =>
                case opcode is
                    when OP_ADD | OP_SUB | OP_AND | OP_OR | OP_SLT =>
                        next_state <= st_exec_r;
                    when OP_ADDI | OP_LD | OP_ST =>
                        next_state <= st_addr_calc;
                    when OP_BEQ | OP_BNE =>
                        next_state <= st_branch;
                    when OP_JMP =>
                        next_state <= st_jump;
                    when others =>
                        next_state <= st_fetch;
                end case;

            when st_exec_r =>
                next_state <= st_wb_alu;

            when st_addr_calc =>
                case opcode is
                    when OP_ADDI => next_state <= st_wb_alu;
                    when OP_LD   => next_state <= st_mem_read;
                    when others  => next_state <= st_mem_write; -- OP_ST
                end case;

            when st_mem_read   => next_state <= st_wb_mem;
            when st_mem_write  => next_state <= st_fetch;
            when st_wb_alu     => next_state <= st_fetch;
            when st_wb_mem     => next_state <= st_fetch;
            when st_branch     => next_state <= st_fetch;
            when st_jump       => next_state <= st_fetch;
        end case;
    end process;

    -- processo 3: logica de saida (100% Moore, so depende do estado atual)
    process(current_state, opcode)
    begin
        -- valores default
        PCWrite     <= '0';
        PCWriteCond <= '0';
        IorD        <= '0';
        IRWrite     <= '0';
        MemRead     <= '0';
        MemWrite    <= '0';
        MemToReg    <= '0';
        RegWrite    <= '0';
        ALUSrcA     <= '0';
        ALUSrcB     <= "00";
        ALUOp       <= "010"; -- ADD
        PCSource    <= "00";
        led_state   <= "00000";

        case current_state is
            when st_fetch =>
                IRWrite   <= '1';
                MemRead   <= '1';
                IorD      <= '0';
                ALUSrcA   <= '0';
                ALUSrcB   <= "01";
                ALUOp     <= "010"; -- ADD
                PCSource  <= "00";
                PCWrite   <= '1';
                led_state <= "00001";

            when st_decode =>
                ALUSrcA   <= '0';
                ALUSrcB   <= "10";
                ALUOp     <= "010"; -- ADD
                led_state <= "00010";

            when st_addr_calc =>
                ALUSrcA   <= '1';
                ALUSrcB   <= "10";
                ALUOp     <= "010"; -- ADD
                led_state <= "00100";

            when st_exec_r =>
                ALUSrcA <= '1';
                ALUSrcB <= "00";
                case opcode is
                    when OP_ADD => ALUOp <= "010";
                    when OP_SUB => ALUOp <= "100";
                    when OP_AND => ALUOp <= "000";
                    when OP_OR  => ALUOp <= "001";
                    when OP_SLT => ALUOp <= "110";
                    when others => ALUOp <= "010";
                end case;
                led_state <= "00100";

            when st_mem_read =>
                IorD      <= '1';
                MemRead   <= '1';
                led_state <= "01000";

            when st_mem_write =>
                IorD      <= '1';
                MemWrite  <= '1';
                led_state <= "01000";

            when st_wb_alu =>
                RegWrite  <= '1';
                MemToReg  <= '0';
                led_state <= "10000";

            when st_wb_mem =>
                RegWrite  <= '1';
                MemToReg  <= '1';
                led_state <= "10000";

            when st_branch =>
                ALUSrcA     <= '1';
                ALUSrcB     <= "00";
                ALUOp       <= "100"; -- SUB
                PCSource    <= "01";
                PCWriteCond <= '1';
                led_state   <= "00100";

            when st_jump =>
                PCWrite   <= '1';
                PCSource  <= "10";
                led_state <= "00100";
        end case;
    end process;

end architecture rtl;
