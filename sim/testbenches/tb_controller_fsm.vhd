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
    signal finished : boolean := false;

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
        variable falhas : integer := 0;

        -- espera a borda de subida e mais 1 ns, para conferir as saidas
        -- depois que o registrador de estado ja atualizou
        procedure tick is
        begin
            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure;

        procedure verifica(cond : boolean; msg : string) is
        begin
            if not cond then
                report "FALHA " & msg severity error;
                falhas := falhas + 1;
            end if;
        end procedure;
    begin
        -- reset inicial
        reset <= '1'; wait for CLK_PERIOD;
        reset <= '0'; verifica(led_state = "00001", "reset: devia iniciar em FETCH");

        --  ------------
        --  |ADD (Tipo R)|
        --  -------------

        opcode <= OP_ADD;
        tick; -- Fetch -> decode
        verifica(led_state = "00010", "ADD: devia estar em DECODE");
        tick; -- Decode -> Exec_r
        verifica(led_state = "00100" and ALUOp = "010", "ADD: ALUOp devia ser 010 em execute");
        tick; -- Exec_r -> WB_alu
        verifica(led_state = "10000" and RegWrite = '1' and MemToReg = '0', "ADD: sinais errados em Write back");
        tick;  -- WB_ALU -> Fetch
        verifica(led_state = "00001", "ADD: devia voltar para FETCH");

        -- ----------------
        -- |SUB/AND/OR/SLT| -- só confere o ALUOp em EXEC_R
        -- ---------------

        opcode <= OP_SUB;
        tick; tick;
        verifica(ALUOp = "100", "SUB: ALUOp devia ser 100");
        tick; tick;

        opcode <= OP_AND;
        tick; tick;
        verifica(ALUOp = "000", "AND: ALUOp devia ser 000");
        tick; tick;

        opcode <= OP_OR;
        tick; tick;
        verifica(ALUOp = "001", "OR: ALUOp devia ser 001");
        tick; tick;

        opcode <= OP_SLT;
        tick; tick;
        verifica(ALUOp = "110", "SLT: ALUOp devia ser 110");
        tick; tick;

        -- -----
        -- |ADDI|
        -- -----   
        opcode <= OP_ADDI;
        tick; -- DECODE
        tick; -- ADDR_CALC
        verifica(led_state = "00100" and ALUSrcA = '1' and ALUSrcB = "10" and ALUOp = "010", "ADDI: sinais errados em ADDR_CALC");
        tick; -- WB_ALU
        verifica(RegWrite = '1' and MemToReg = '0', "ADDI: esperava escrever ALUOut");
        tick; -- FETCH

         ---------------------------------------------------------------
        -- LD
        ---------------------------------------------------------------
        opcode <= OP_LD;
        tick; -- DECODE
        tick; -- ADDR_CALC
        tick; -- MEM_READ
        verifica(led_state = "01000" and IorD = '1' and MemRead = '1', "LD: sinais errados em MEM_READ");
        tick; -- WB_MEM
        verifica(RegWrite = '1' and MemToReg = '1', "LD: esperava escrever RDM");
        tick; -- FETCH

        ---------------------------------------------------------------
        -- ST
        ---------------------------------------------------------------
        opcode <= OP_ST;
        tick; -- DECODE
        tick; -- ADDR_CALC
        tick; -- MEM_WRITE
        verifica(led_state = "01000" and IorD = '1' and MemWrite = '1', "ST: sinais errados em MEM_WRITE");
        tick; -- FETCH

        ---------------------------------------------------------------
        -- BEQ
        ---------------------------------------------------------------
        opcode <= OP_BEQ;
        tick; -- DECODE
        tick; -- BRANCH
        verifica(led_state = "00100" and PCWriteCond = '1' and BNE = '0' and ALUOp = "100" and PCSource = "01", "BEQ: sinais errados em BRANCH");
        tick; -- FETCH

        ---------------------------------------------------------------
        -- BNE
        ---------------------------------------------------------------
        opcode <= OP_BNE;
        tick; -- DECODE
        tick; -- BRANCH
        verifica(led_state = "00100" and PCWriteCond = '1' and BNE = '1', "BNE: BNE devia ser 1");
        tick; -- FETCH

        ---------------------------------------------------------------
        -- JMP
        ---------------------------------------------------------------
        opcode <= OP_JMP;
        tick; -- DECODE
        tick; -- JUMP
        verifica(led_state = "00100" and PCWrite = '1' and PCSource = "10", "JMP: sinais errados em JUMP");
        tick; -- FETCH

        ---------------------------------------------------------------
        -- reset no meio de uma instrucao (assincrono)
        ---------------------------------------------------------------
        opcode <= OP_LD;
        tick; -- DECODE
        tick; -- ADDR_CALC
        reset <= '1';
        wait for CLK_PERIOD / 4;
        verifica(led_state = "00001", "reset: devia voltar a FETCH imediatamente, sem esperar borda");
        reset <= '0';
        wait for CLK_PERIOD;

        if falhas = 0 then
            report "tb_controller_fsm: OK" severity note;
        else
            report "tb_controller_fsm: " & integer'image(falhas) & " falha(s)" severity failure;
        end if;
        finished <= true;
        wait;
    end process;

end architecture sim;