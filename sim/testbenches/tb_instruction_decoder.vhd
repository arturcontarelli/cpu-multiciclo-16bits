-- Testbench do decodificador: campos dos tres formatos e RegSrcB para os 16
-- opcodes (1 so em ST, BEQ e BNE).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;

entity tb_instruction_decoder is
end entity tb_instruction_decoder;

architecture sim of tb_instruction_decoder is
    signal instr     : word16 := (others => '0');
    signal opcode    : opcode_t;
    signal ri, rj, rk : reg_addr;
    signal imm       : std_logic_vector(5 downto 0);
    signal jump_addr : std_logic_vector(11 downto 0);
    signal RegSrcB   : std_logic;
begin
    dut: entity work.instruction_decoder
        port map (
            instr => instr, opcode => opcode, ri => ri, rj => rj, rk => rk,
            imm => imm, jump_addr => jump_addr, RegSrcB => RegSrcB
        );

    process
        variable falhas : natural := 0;
        variable op     : opcode_t;
        variable esperado : std_logic;

        procedure verifica(cond : boolean; nome : string) is
        begin
            if not cond then
                report "FALHA " & nome severity error;
                falhas := falhas + 1;
            end if;
        end procedure;
    begin
        -- tipo R: SUB R4, R1, R2 = 0001 100 001 010 000
        instr <= x"1850";
        wait for 10 ns;
        verifica(opcode = OP_SUB, "R: opcode");
        verifica(ri = "100", "R: ri");
        verifica(rj = "001", "R: rj");
        verifica(rk = "010", "R: rk");
        verifica(RegSrcB = '0', "R: RegSrcB = Rk");

        -- tipo I: ST R4, R7, 29 = 0111 100 111 011101
        instr <= x"79DD";
        wait for 10 ns;
        verifica(opcode = OP_ST, "I: opcode");
        verifica(ri = "100", "I: ri");
        verifica(rj = "111", "I: rj");
        verifica(imm = "011101", "I: imm");
        verifica(RegSrcB = '1', "I: RegSrcB = Ri no ST");

        -- tipo I com imediato negativo: BEQ R0, R0, -1 = 1000 000 000 111111
        instr <= x"803F";
        wait for 10 ns;
        verifica(opcode = OP_BEQ, "BEQ: opcode");
        verifica(imm = "111111", "BEQ: imm = -1");

        -- tipo J: JMP 0xABC = 1010 1010 1011 1100
        instr <= x"AABC";
        wait for 10 ns;
        verifica(opcode = OP_JMP, "J: opcode");
        verifica(jump_addr = x"ABC", "J: jump_addr");

        -- RegSrcB para todos os opcodes (inclusive os livres)
        for i in 0 to 15 loop
            op := std_logic_vector(to_unsigned(i, 4));
            instr <= op & "000000000000";
            wait for 10 ns;
            if op = OP_ST or op = OP_BEQ or op = OP_BNE then
                esperado := '1';
            else
                esperado := '0';
            end if;
            verifica(RegSrcB = esperado, "RegSrcB do opcode " & integer'image(i));
        end loop;

        if falhas = 0 then
            report "tb_instruction_decoder: OK" severity note;
        else
            report "tb_instruction_decoder: " & integer'image(falhas) & " falha(s)" severity failure;
        end if;
        wait;
    end process;
end architecture sim;
