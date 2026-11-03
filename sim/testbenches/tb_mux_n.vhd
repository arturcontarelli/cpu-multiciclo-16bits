-- Testbench do mux generico nas duas configuracoes usadas no datapath:
-- 4 entradas de 16 bits (PCSource, ALUSrcB) e 2 entradas de 3 bits (RegSrcB).

library ieee;
use ieee.std_logic_1164.all;

entity tb_mux_n is
end entity tb_mux_n;

architecture sim of tb_mux_n is
    signal sel4  : std_logic_vector(1 downto 0);
    signal in4   : std_logic_vector(63 downto 0);
    signal out4  : std_logic_vector(15 downto 0);

    signal sel2  : std_logic_vector(0 downto 0);
    signal in2   : std_logic_vector(5 downto 0);
    signal out2  : std_logic_vector(2 downto 0);
begin

    dut4: entity work.mux_n
        generic map (WIDTH => 16, SEL_BITS => 2)
        port map (sel => sel4, data_in => in4, data_out => out4);

    dut2: entity work.mux_n
        generic map (WIDTH => 3, SEL_BITS => 1)
        port map (sel => sel2, data_in => in2, data_out => out2);

    process
        variable falhas : natural := 0;

        procedure verifica(cond : boolean; nome : string) is
        begin
            if not cond then
                report "FALHA " & nome severity error;
                falhas := falhas + 1;
            end if;
        end procedure;
    begin
        -- entrada 3 & entrada 2 & entrada 1 & entrada 0
        in4 <= x"3333" & x"2222" & x"1111" & x"0000";
        sel4 <= "00"; wait for 10 ns; verifica(out4 = x"0000", "4x16 sel 00");
        sel4 <= "01"; wait for 10 ns; verifica(out4 = x"1111", "4x16 sel 01");
        sel4 <= "10"; wait for 10 ns; verifica(out4 = x"2222", "4x16 sel 10");
        sel4 <= "11"; wait for 10 ns; verifica(out4 = x"3333", "4x16 sel 11");

        in2 <= "101" & "010";
        sel2 <= "0"; wait for 10 ns; verifica(out2 = "010", "2x3 sel 0");
        sel2 <= "1"; wait for 10 ns; verifica(out2 = "101", "2x3 sel 1");

        if falhas = 0 then
            report "tb_mux_n: OK" severity note;
        else
            report "tb_mux_n: " & integer'image(falhas) & " falha(s)" severity failure;
        end if;
        wait;
    end process;

end architecture sim;
