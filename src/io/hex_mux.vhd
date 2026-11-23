-- Escolhe o que aparece nos displays HEX4-HEX7 (Parte 4 - Integracao FPGA).
-- O enunciado pede que o SW17 alterne entre o valor lido da memoria (RDM) e
-- a saida da ULA:
--   sel = SW17 = '0' -> RDM
--   sel = SW17 = '1' -> saida da ULA (combinacional, valor do estado atual)
--
-- Fica em src/io (e nao no datapath) porque so existe para a demonstracao na
-- placa: a CPU nao depende de como e exibida.

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity hex_mux is
    port (
        sel   : in  std_logic;   -- SW17
        rdm   : in  word16;      -- sel = 0
        ula   : in  word16;      -- sel = 1
        saida : out word16       -- vai para HEX7..HEX4
    );
end entity hex_mux;

architecture rtl of hex_mux is
begin
    saida <= ula when sel = '1' else rdm;
end architecture rtl;
