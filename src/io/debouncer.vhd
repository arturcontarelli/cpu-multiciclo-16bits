-- Debouncer de botao da DE2-115 (Parte 4 - Integracao FPGA).
--
-- Um botao mecanico "quica": ao ser apertado ou solto, o contato abre e fecha
-- varias vezes durante alguns milissegundos. Como o KEY[0] e o proprio clock
-- da CPU, cada quique viraria uma borda de clock extra (varios ciclos por
-- aperto). Este modulo so aceita uma mudanca de nivel depois que o botao fica
-- CONTAGEM ciclos seguidos do CLOCK_50 no mesmo valor.
--
-- Funcionamento:
--   1. sincronizador de 2 flip-flops: o botao e assincrono ao CLOCK_50; os dois
--      FFs evitam metaestabilidade antes de comparar o valor;
--   2. contador: enquanto a entrada sincronizada for diferente do nivel estavel,
--      conta; se voltar ao nivel estavel antes do fim (quique), zera; ao chegar
--      em CONTAGEM, aceita o novo nivel;
--   3. saida invertida: os KEY da placa sao ativos em 0, a saida e ativa em 1
--      (1 = apertado). Assim o cpu_top liga a saida direto no clk/reset da CPU,
--      sem logica no topo.
--
-- CONTAGEM padrao = 1_000_000 ciclos de 50 MHz = 20 ms. No testbench usa-se um
-- valor pequeno para a simulacao ser rapida.
--
-- A saida vem de um registrador (mais um inversor), entao nao tem glitch: e
-- seguro usa-la como clock da CPU.

library ieee;
use ieee.std_logic_1164.all;

entity debouncer is
    generic (
        CONTAGEM : positive := 1_000_000      -- 20 ms a 50 MHz
    );
    port (
        clk   : in  std_logic;                -- CLOCK_50
        btn_n : in  std_logic;                -- botao cru, ativo em 0 (KEY)
        btn   : out std_logic                 -- nivel estavel, ativo em 1
    );
end entity debouncer;

architecture rtl of debouncer is
    -- valores iniciais = botao solto ('1'), valem no power-up da FPGA
    signal sync_1, sync_2 : std_logic := '1';
    signal estavel        : std_logic := '1';
    signal contador       : natural range 0 to CONTAGEM - 1 := 0;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            -- sincronizador
            sync_1 <= btn_n;
            sync_2 <= sync_1;

            -- filtro por tempo
            if sync_2 = estavel then
                contador <= 0;                 -- nada mudou (ou foi quique)
            elsif contador = CONTAGEM - 1 then
                estavel  <= sync_2;            -- ficou estavel tempo suficiente
                contador <= 0;
            else
                contador <= contador + 1;
            end if;
        end if;
    end process;

    btn <= not estavel;

end architecture rtl;
