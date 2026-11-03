-- Testbench da ULA: aplica cada operacao com casos de borda
-- (estouro, resultado negativo, SLT com sinal, flag zero) e confere
-- resultado e zero. Termina com "tb_alu: OK" ou com a contagem de falhas.

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity tb_alu is
end entity tb_alu;

architecture sim of tb_alu is
    signal a, b, result : word16;
    signal alu_op       : std_logic_vector(2 downto 0);
    signal zero         : std_logic;
begin

    dut: entity work.alu
        port map (a => a, b => b, alu_op => alu_op, result => result, zero => zero);

    process
        variable falhas : natural := 0;

        procedure check(op : std_logic_vector(2 downto 0); va, vb, esperado : word16;
                        zero_esperado : std_logic; nome : string) is
        begin
            alu_op <= op;
            a <= va;
            b <= vb;
            wait for 10 ns;
            if result /= esperado or zero /= zero_esperado then
                report "FALHA " & nome severity error;
                falhas := falhas + 1;
            end if;
        end procedure;
    begin
        -- AND / OR
        check("000", x"F0F0", x"FF00", x"F000", '0', "AND");
        check("000", x"0F0F", x"F0F0", x"0000", '1', "AND sem bits em comum -> zero");
        check("001", x"F0F0", x"0F00", x"FFF0", '0', "OR");

        -- ADD (tambem usado para PC+1, PC+imm e Rj+imm)
        check("010", x"0005", x"0003", x"0008", '0', "ADD 5+3");
        check("010", x"0005", x"FFFF", x"0004", '0', "ADD 5+(-1)");
        check("010", x"7FFF", x"0001", x"8000", '0', "ADD estouro de sinal (sem flag)");
        check("010", x"FFFF", x"0001", x"0000", '1', "ADD -1+1 -> zero");

        -- SUB (tambem usado por BEQ/BNE)
        check("100", x"0005", x"0003", x"0002", '0', "SUB 5-3");
        check("100", x"0003", x"0005", x"FFFE", '0', "SUB 3-5 = -2");
        check("100", x"1234", x"1234", x"0000", '1', "SUB iguais -> zero (BEQ desvia)");

        -- SLT com sinal
        check("110", x"0003", x"0005", x"0001", '0', "SLT 3<5");
        check("110", x"0005", x"0003", x"0000", '1', "SLT 5<3 falso");
        check("110", x"FFFF", x"0001", x"0001", '0', "SLT -1<1 (com sinal)");
        check("110", x"0001", x"FFFF", x"0000", '1', "SLT 1<-1 falso");
        check("110", x"0007", x"0007", x"0000", '1', "SLT iguais falso");

        -- codigo nao usado
        check("011", x"FFFF", x"FFFF", x"0000", '1', "codigo invalido -> 0");

        if falhas = 0 then
            report "tb_alu: OK" severity note;
        else
            report "tb_alu: " & integer'image(falhas) & " falha(s)" severity failure;
        end if;
        wait;
    end process;

end architecture sim;
