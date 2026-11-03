-- Testbench de integracao do datapath com a FSM real (controller_fsm).
-- O decodificador e a memoria sao modelos simples, so para este teste:
--   * decodificador: fatia os campos do IR e gera RegSrcB (ST, BEQ, BNE)
--   * memoria: unica, 64 palavras, endereco registrado na borda de DESCIDA
--     (imita a altsyncram ligada no clock invertido, ver decisoes.md)
--
-- O programa usa as 11 instrucoes, desvios tomados e nao tomados, laco com
-- offset negativo, JMP por cima de instrucao "veneno", escrita em R0 e
-- termina em BEQ R0, R0, -1. No fim confere registradores, memoria e PC.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;

entity tb_datapath is
end entity tb_datapath;

architecture sim of tb_datapath is
    constant PERIODO : time    := 20 ns;
    constant CICLOS  : natural := 300;

    constant R0 : reg_addr := "000";
    constant R1 : reg_addr := "001";
    constant R2 : reg_addr := "010";
    constant R3 : reg_addr := "011";
    constant R4 : reg_addr := "100";
    constant R5 : reg_addr := "101";
    constant R6 : reg_addr := "110";
    constant R7 : reg_addr := "111";

    -- montam a palavra de instrucao nos formatos R, I e J
    function tipo_r(op : opcode_t; ri, rj, rk : reg_addr) return word16 is
        variable w : word16;
    begin
        w := op & ri & rj & rk & "000";
        return w;
    end function;

    function tipo_i(op : opcode_t; ri, rj : reg_addr; imm : integer) return word16 is
        variable w : word16;
    begin
        w := op & ri & rj & std_logic_vector(to_signed(imm, 6));
        return w;
    end function;

    function tipo_j(op : opcode_t; addr : natural) return word16 is
        variable w : word16;
    begin
        w := op & std_logic_vector(to_unsigned(addr, 12));
        return w;
    end function;

    type mem_t is array (0 to 63) of word16;
    signal mem : mem_t := (
        0  => tipo_i(OP_ADDI, R1, R0, 6),    -- R1 = 6
        1  => tipo_i(OP_ADDI, R2, R0, -3),   -- R2 = -3 (FFFD)
        2  => tipo_r(OP_ADD,  R3, R1, R2),   -- R3 = 3
        3  => tipo_r(OP_SUB,  R4, R1, R2),   -- R4 = 9
        4  => tipo_r(OP_AND,  R5, R1, R3),   -- R5 = 6 and 3 = 2
        5  => tipo_r(OP_OR,   R6, R1, R4),   -- R6 = 6 or 9 = 15
        6  => tipo_r(OP_SLT,  R7, R2, R1),   -- R7 = (-3 < 6) = 1
        7  => tipo_i(OP_ST,   R4, R7, 29),   -- M[R7 + 29] = M[30] = 9
        8  => tipo_i(OP_LD,   R7, R0, 30),   -- R7 = M[30] = 9
        9  => tipo_i(OP_BEQ,  R7, R4, 1),    -- 9 = 9: desvia para 11
        10 => tipo_i(OP_ADDI, R1, R0, 31),   -- veneno (pulado)
        11 => tipo_i(OP_BNE,  R7, R4, 1),    -- 9 = 9: nao desvia
        12 => tipo_i(OP_ADDI, R5, R5, 1),    -- R5 = 3 (prova que nao desviou)
        13 => tipo_i(OP_ADDI, R2, R2, 1),    -- laco: R2 = -2, -1, 0
        14 => tipo_i(OP_BNE,  R2, R0, -2),   -- volta para 13 enquanto R2 /= 0
        15 => tipo_j(OP_JMP,  17),           -- pula 16
        16 => tipo_i(OP_ADDI, R1, R0, 30),   -- veneno (pulado)
        17 => tipo_i(OP_ADDI, R0, R0, 9),    -- escrita em R0 ignorada
        18 => tipo_i(OP_BEQ,  R0, R0, -1),   -- fim: desvia para si mesmo
        others => (others => '0')
    );

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
    signal fim   : boolean   := false;

    -- controle
    signal PCWrite, PCWriteCond, BNE, IorD, IRWrite : std_logic;
    signal MemRead, MemWrite, MemToReg, RegWrite, ALUSrcA : std_logic;
    signal ALUSrcB, PCSource : std_logic_vector(1 downto 0);
    signal ALUOp     : std_logic_vector(2 downto 0);
    signal led_state : std_logic_vector(4 downto 0);

    -- decodificador
    signal instr   : word16;
    signal opcode  : opcode_t;
    signal RegSrcB : std_logic;

    -- memoria e observacao
    signal mem_addr, mem_write_data, mem_read_data : word16;
    signal mem_addr_reg : natural range 0 to 63 := 0;
    signal pc_out, alu_result, rdm_out : word16;
    signal reg_dump : std_logic_vector(127 downto 0);
begin

    clk_proc: process
    begin
        while not fim loop
            clk <= '0'; wait for PERIODO / 2;
            clk <= '1'; wait for PERIODO / 2;
        end loop;
        wait;
    end process;

    u_fsm: entity work.controller_fsm
        port map (
            clk => clk, reset => reset, opcode => opcode,
            PCWrite => PCWrite, PCWriteCond => PCWriteCond, BNE => BNE,
            IorD => IorD, IRWrite => IRWrite, MemRead => MemRead, MemWrite => MemWrite,
            MemToReg => MemToReg, RegWrite => RegWrite, ALUSrcA => ALUSrcA,
            ALUSrcB => ALUSrcB, ALUOp => ALUOp, PCSource => PCSource,
            led_state => led_state
        );

    -- modelo do decodificador
    opcode  <= instr(15 downto 12);
    RegSrcB <= '1' when opcode = OP_ST or opcode = OP_BEQ or opcode = OP_BNE else '0';

    dut: entity work.datapath
        port map (
            clk => clk, reset => reset,
            PCWrite => PCWrite, PCWriteCond => PCWriteCond, BNE => BNE,
            IorD => IorD, IRWrite => IRWrite, MemToReg => MemToReg, RegWrite => RegWrite,
            ALUSrcA => ALUSrcA, ALUSrcB => ALUSrcB, ALUOp => ALUOp, PCSource => PCSource,
            RegSrcB => RegSrcB,
            ri => instr(11 downto 9), rj => instr(8 downto 6), rk => instr(5 downto 3),
            imm => instr(5 downto 0), jump_addr => instr(11 downto 0),
            mem_addr => mem_addr, mem_write_data => mem_write_data, mem_read_data => mem_read_data,
            instr => instr, pc_out => pc_out, alu_result => alu_result, rdm_out => rdm_out,
            reg_dump => reg_dump
        );

    -- modelo da memoria: escrita e registro do endereco na borda de descida
    mem_proc: process(clk)
        variable addr : natural range 0 to 63;
    begin
        if falling_edge(clk) then
            addr := to_integer(unsigned(mem_addr(5 downto 0)));
            if MemWrite = '1' then
                mem(addr) <= mem_write_data;
            end if;
            mem_addr_reg <= addr;
        end if;
    end process;

    mem_read_data <= mem(mem_addr_reg);

    process
        variable falhas : natural := 0;

        procedure verifica(cond : boolean; nome : string) is
        begin
            if not cond then
                report "FALHA " & nome severity error;
                falhas := falhas + 1;
            end if;
        end procedure;

        -- extrai Rn do reg_dump (R7..R0)
        function reg(n : natural; dump : std_logic_vector(127 downto 0)) return word16 is
            variable w : word16;
        begin
            w := dump(16*n + 15 downto 16*n);
            return w;
        end function;
    begin
        wait for PERIODO;
        reset <= '0';
        wait for PERIODO * CICLOS;

        verifica(reg(0, reg_dump) = x"0000", "R0 = 0 (escrita ignorada)");
        verifica(reg(1, reg_dump) = x"0006", "R1 = 6 (ADDI; venenos pulados)");
        verifica(reg(2, reg_dump) = x"0000", "R2 = 0 (laco com BNE negativo)");
        verifica(reg(3, reg_dump) = x"0003", "R3 = 3 (ADD)");
        verifica(reg(4, reg_dump) = x"0009", "R4 = 9 (SUB)");
        verifica(reg(5, reg_dump) = x"0003", "R5 = 3 (AND + BNE nao tomado)");
        verifica(reg(6, reg_dump) = x"000F", "R6 = 15 (OR)");
        verifica(reg(7, reg_dump) = x"0009", "R7 = 9 (SLT como base do ST + LD)");
        verifica(mem(30) = x"0009", "M[30] = 9 (ST)");
        verifica(pc_out = x"0012" or pc_out = x"0013", "PC parado no halt (18/19)");

        if falhas = 0 then
            report "tb_datapath: OK" severity note;
        else
            report "tb_datapath: " & integer'image(falhas) & " falha(s)" severity failure;
        end if;
        fim <= true;
        wait;
    end process;

end architecture sim;
