-- Decodificador de 1 digito hexadecimal (4 bits) para display de 7 segmentos
-- (Parte 4 - Integracao FPGA). Reutilizado nos 8 displays HEX0-HEX7 (DRY).
--
-- Convencoes da DE2-115 (ver quartus/pinout.md):
--   - segmentos ativos em 0: '0' acende o segmento;
--   - segmentos(0) = a, segmentos(1) = b, ..., segmentos(6) = g.
--
--        a
--       ---
--    f |   | b
--       -g-
--    e |   | c
--       ---
--        d
--
-- Letras: A b C d E F (b e d minusculos para nao confundir com 8 e 0).

library ieee;
use ieee.std_logic_1164.all;

entity hex_display is
    port (
        digito    : in  std_logic_vector(3 downto 0);
        segmentos : out std_logic_vector(6 downto 0)   -- g f e d c b a
    );
end entity hex_display;

architecture rtl of hex_display is
begin

    with digito select
        segmentos <=
            "1000000" when "0000",   -- 0
            "1111001" when "0001",   -- 1
            "0100100" when "0010",   -- 2
            "0110000" when "0011",   -- 3
            "0011001" when "0100",   -- 4
            "0010010" when "0101",   -- 5
            "0000010" when "0110",   -- 6
            "1111000" when "0111",   -- 7
            "0000000" when "1000",   -- 8
            "0010000" when "1001",   -- 9
            "0001000" when "1010",   -- A
            "0000011" when "1011",   -- b
            "1000110" when "1100",   -- C
            "0100001" when "1101",   -- d
            "0000110" when "1110",   -- E
            "0001110" when "1111",   -- F
            "1111111" when others;   -- apagado (so em simulacao: 'U', 'X'...)

end architecture rtl;
