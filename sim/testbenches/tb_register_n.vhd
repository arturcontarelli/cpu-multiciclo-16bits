-- Testbench do registrador generico: carga com en = 1, manutencao com
-- en = 0 e reset assincrono.

library ieee;
use ieee.std_logic_1164.all;

entity tb_register_n is
end entity tb_register_n;

architecture sim of tb_register_n is
    constant PERIODO : time := 20 ns;

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
    signal en    : std_logic := '0';
    signal d     : std_logic_vector(15 downto 0) := (others => '0');
    signal q     : std_logic_vector(15 downto 0);
    signal fim   : boolean := false;
begin

    dut: entity work.register_n
        generic map (WIDTH => 16)
        port map (clk => clk, reset => reset, en => en, d => d, q => q);

    clk_proc: process
    begin
        while not fim loop
            clk <= '0'; wait for PERIODO / 2;
            clk <= '1'; wait for PERIODO / 2;
        end loop;
        wait;
    end process;

    process
        variable falhas : natural := 0;

        procedure ciclo(en_v : std_logic; valor, esperado : std_logic_vector(15 downto 0); nome : string) is
        begin
            wait until falling_edge(clk);
            en <= en_v;
            d  <= valor;
            wait until rising_edge(clk);
            wait for 1 ns;
            if q /= esperado then
                report "FALHA " & nome severity error;
                falhas := falhas + 1;
            end if;
        end procedure;
    begin
        wait for PERIODO;
        if q /= x"0000" then
            report "FALHA reset inicial" severity error;
            falhas := falhas + 1;
        end if;
        reset <= '0';

        ciclo('1', x"ABCD", x"ABCD", "en = 1 carrega");
        ciclo('0', x"1234", x"ABCD", "en = 0 mantem");
        ciclo('1', x"1234", x"1234", "en = 1 sobrescreve");

        wait until falling_edge(clk);
        wait for 2 ns;
        reset <= '1';
        wait for 1 ns;
        if q /= x"0000" then
            report "FALHA reset assincrono" severity error;
            falhas := falhas + 1;
        end if;

        if falhas = 0 then
            report "tb_register_n: OK" severity note;
        else
            report "tb_register_n: " & integer'image(falhas) & " falha(s)" severity failure;
        end if;
        fim <= true;
        wait;
    end process;

end architecture sim;
