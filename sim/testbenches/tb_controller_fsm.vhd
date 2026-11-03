library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity tb_controller_fsm is
end entity tb_controller_fsm;

architecture sim of tb_controller_fsm is

    constant CLK_PERIOD : time := 20 ns;

    signal clk    : std_logic := '0';
    signal reset  : std_logic := '0';
    signal opcode : opcode_t := OP_ADD;
    signal finished : std_logic := false;

    signal PCWrite, PCWriteCond, BNE, IorD, IRWrite : std_logic;
    signal MemRead, MemWrite, MemToReg, RegWrite    : std_logic;
    signal ALUSrcA                                  : std_logic;
    signal ALUSrcB, PCSource                        : std_logic_vector(1 downto 0);
    signal ALUOp                                    : std_logic_vector(2 downto 0);
    signal led_state                                : std_logic_vector(4 downto 0);

begin
    uut: entity work.controller_fsm
        port map (
            clk => clk, reset => reset, opcode => opcode,
            PCWrite => PCWrite, PCWriteCond => PCWriteCond, BNE => BNE,
            IorD => IorD, IRWrite => IRWrite, 
            MemRead => MemRead, MemWrite => MemWrite,
            MemToReg => MemToReg, RegWrite => RegWrite,
            ALUSrcA => ALUSrcA, ALUSrcB => ALUSrcB,
            PCSource => PCSource, ALUOp => ALUOp,
            led_state => led_state
        );
    
    clk_gen: process
    begin
        while not finished loop
            clk <= '0'; wait for CLK_PERIOD/2;
            clk <= '1'; wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    stim: process
    begin
        -- reset inicial
        reset <= '1'; wait for CLK_PERIOD;
        reset <= '0'; assert led_state = "00001" report "reset: devia iniciar em FETCH" severity error;

        --  ------------
        --  |ADD (Tipo R)|
        --  -------------

        opcode <= OP_ADD;
        wait until rising_edge(clk); -- Fetch -> decode
        assert led_state = "00010" report "ADD: devia estar em DECODE" severity error;
        wait until rising_edge(clk); -- Decode -> Exec_r
        assert led_state = "00100" and ALUOp = "010" report "ADD: ALUOp devia ser 010 em execute" severity error;
        wait until rising_edge(clk); -- Exec_r -> WB_alu
        assert led_state = "10000" and RegWrite = '1' and MemToReg = '0' report "ADD: sinais errados em Write back" severity error;
        wait until rising_edge(clk);  -- WB_ALU -> Fetch
        assert led_state = "00001" report "ADD: devia voltar para FETCH" severity

        -- ----------------
        -- |SUB/AND/OR/SLT| -- só confere o ALUOp em EXEC_R
        -- ---------------

        opcode <= OP_SUB;
        wait until rising_edge(clk); wait until rising_edge(clk);
        assert ALUOp = "100" report "SUB: ALUOp devia ser 100" severity error;
        wait until rising_edge(clk); wait until rising_edge(clk);

        opcode <= OP_AND;
        wait until rising_edge(clk); wait until rising_edge(clk);
        assert ALUOp = "000" report "AND: ALUOp devia ser 000" severity error;
        wait until rising_edge(clk); wait until rising_edge(clk);

        opcode <= OP_OR;
        wait until rising_edge(clk); wait until rising_edge(clk);
        assert ALUOp = "001" report "OR: ALUOp devia ser 001" severity error;
        wait until rising_edge(clk); wait until rising_edge(clk);

        opcode <= OP_SLT;
        wait until rising_edge(clk); wait until rising_edge(clk);
        assert ALUOp = "110" report "SLT: ALUOp devia ser 110" severity error;
        wait until rising_edge(clk); wait until rising_edge(clk);

        -- -----
        -- |ADDI|
        -- -----   
        opcode <= OP_ADDI;
        wait until rising_edge(clk); -- DECODE
        wait until rising_edge(clk); -- ADDR_CALC
        assert led_state = "00100" and ALUSrcA = '1' and ALUSrcB = "10" and ALUOp = "010"
            report "ADDI: sinais errados em ADDR_CALC" severity error;
        wait until rising_edge(clk); -- WB_ALU
        assert RegWrite = '1' and MemToReg = '0' report "ADDI: esperava escrever ALUOut" severity error;
        wait until rising_edge(clk); -- FETCH

         ---------------------------------------------------------------
        -- LD
        ---------------------------------------------------------------
        opcode <= OP_LD;
        wait until rising_edge(clk); -- DECODE
        wait until rising_edge(clk); -- ADDR_CALC
        wait until rising_edge(clk); -- MEM_READ
        assert led_state = "01000" and IorD = '1' and MemRead = '1' report "LD: sinais errados em MEM_READ" severity error;
        wait until rising_edge(clk); -- WB_MEM
        assert RegWrite = '1' and MemToReg = '1' report "LD: esperava escrever RDM" severity error;
        wait until rising_edge(clk); -- FETCH

        ---------------------------------------------------------------
        -- ST
        ---------------------------------------------------------------
        opcode <= OP_ST;
        wait until rising_edge(clk); -- DECODE
        wait until rising_edge(clk); -- ADDR_CALC
        wait until rising_edge(clk); -- MEM_WRITE
        assert led_state = "01000" and IorD = '1' and MemWrite = '1' report "ST: sinais errados em MEM_WRITE" severity error;
        wait until rising_edge(clk); -- FETCH

        ---------------------------------------------------------------
        -- BEQ
        ---------------------------------------------------------------
        opcode <= OP_BEQ;
        wait until rising_edge(clk); -- DECODE
        wait until rising_edge(clk); -- BRANCH
        assert led_state = "00100" and PCWriteCond = '1' and BNE = '0' and ALUOp = "100" and PCSource = "01"
            report "BEQ: sinais errados em BRANCH" severity error;
        wait until rising_edge(clk); -- FETCH

        ---------------------------------------------------------------
        -- BNE
        ---------------------------------------------------------------
        opcode <= OP_BNE;
        wait until rising_edge(clk); -- DECODE
        wait until rising_edge(clk); -- BRANCH
        assert led_state = "00100" and PCWriteCond = '1' and BNE = '1'
            report "BNE: BNE devia ser 1" severity error;
        wait until rising_edge(clk); -- FETCH

        ---------------------------------------------------------------
        -- JMP
        ---------------------------------------------------------------
        opcode <= OP_JMP;
        wait until rising_edge(clk); -- DECODE
        wait until rising_edge(clk); -- JUMP
        assert led_state = "00100" and PCWrite = '1' and PCSource = "10" report "JMP: sinais errados em JUMP" severity error;
        wait until rising_edge(clk); -- FETCH

        ---------------------------------------------------------------
        -- reset no meio de uma instrucao (assincrono)
        ---------------------------------------------------------------
        opcode <= OP_LD;
        wait until rising_edge(clk); -- DECODE
        wait until rising_edge(clk); -- ADDR_CALC
        reset <= '1';
        wait for CLK_PERIOD / 4;
        assert led_state = "00001" report "reset: devia voltar a FETCH imediatamente, sem esperar borda" severity error;
        reset <= '0';
        wait for CLK_PERIOD;

        report "tb_controller_fsm: todos os testes passaram" severity note;
        finished <= true;
        wait;
    end process;

end architecture sim;