-- Testbench da extensao de sinal: extremos positivo e negativo do imediato.

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity tb_sign_extend is
end entity tb_sign_extend;

architecture sim of tb_sign_extend is
    signal imm     : std_logic_vector(5 downto 0);
    signal imm_ext : word16;
begin

    dut: entity work.sign_extend
        port map (imm => imm, imm_ext => imm_ext);

    process
        variable falhas : natural := 0;

        procedure check(v : std_logic_vector(5 downto 0); esperado : word16; nome : string) is
        begin
            imm <= v;
            wait for 10 ns;
            if imm_ext /= esperado then
                report "FALHA " & nome severity error;
                falhas := falhas + 1;
            end if;
        end procedure;
    begin
        check("000000", x"0000", "0");
        check("000001", x"0001", "+1");
        check("011111", x"001F", "+31 (maior positivo)");
        check("111111", x"FFFF", "-1");
        check("111110", x"FFFE", "-2");
        check("100000", x"FFE0", "-32 (menor negativo)");

        if falhas = 0 then
            report "tb_sign_extend: OK" severity note;
        else
            report "tb_sign_extend: " & integer'image(falhas) & " falha(s)" severity failure;
        end if;
        wait;
    end process;

end architecture sim;
