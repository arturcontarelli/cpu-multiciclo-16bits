-- Gera o clock e o reset da CPU a partir dos botoes da placa
-- (Parte 4 - Integracao FPGA).
--
--   KEY[0] -> debouncer -> clock manual da CPU (cada aperto = 1 ciclo)
--   KEY[1] -> debouncer -> reset assincrono, ativo em 1
--
-- Por que o reset tambem entra no clock (cpu_clk = clk_db or reset_db):
-- a memoria (altsyncram) registra o endereco na borda de DESCIDA do clock da
-- CPU (clock invertido, ver src/memory/memory.vhd). O reset zera o PC na hora,
-- mas a memoria continua com o endereco registrado na ultima vez que o KEY[0]
-- foi solto. Sem uma borda de descida entre o reset e o proximo aperto, o
-- FETCH logo apos o reset carregaria no IR a instrucao do endereco ANTIGO, e
-- nao a do endereco 0 (o tb_cpu_top pega esse erro).
-- Com o OR, apertar o KEY[1] sobe o clock (sem efeito: tudo esta em reset) e
-- solta-lo desce o clock junto com o fim do reset: a memoria registra o
-- endereco 0 (PC ja zerado) e o primeiro aperto do KEY[0] busca M[0].
-- No power-up o problema nao aparece porque o registrador de endereco da RAM
-- ja comeca em 0.
--
-- Fica em src/io porque so existe por causa dos botoes da placa; assim o
-- cpu_top continua sem logica propria.

library ieee;
use ieee.std_logic_1164.all;

entity clock_reset is
    generic (
        CONTAGEM : positive := 1_000_000      -- 20 ms a 50 MHz (ver debouncer)
    );
    port (
        clk_50    : in  std_logic;            -- CLOCK_50
        key_clk   : in  std_logic;            -- KEY[0], ativo em 0
        key_reset : in  std_logic;            -- KEY[1], ativo em 0
        cpu_clk   : out std_logic;            -- clock da CPU
        cpu_reset : out std_logic             -- reset da CPU, ativo em 1
    );
end entity clock_reset;

architecture rtl of clock_reset is
    signal clk_db, reset_db : std_logic;
begin

    u_deb_clk: entity work.debouncer
        generic map (CONTAGEM => CONTAGEM)
        port map (clk => clk_50, btn_n => key_clk, btn => clk_db);

    u_deb_reset: entity work.debouncer
        generic map (CONTAGEM => CONTAGEM)
        port map (clk => clk_50, btn_n => key_reset, btn => reset_db);

    cpu_clk   <= clk_db or reset_db;
    cpu_reset <= reset_db;

end architecture rtl;
