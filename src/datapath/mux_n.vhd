-- Multiplexador generico: 2**SEL_BITS entradas de WIDTH bits.
-- As entradas chegam concatenadas em data_in, com a entrada 0 nos bits
-- baixos:  data_in => entrada3 & entrada2 & entrada1 & entrada0
-- (barramento unico em vez de array para funcionar em VHDL-93 no Quartus).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_n is
    generic (
        WIDTH    : positive := 16;
        SEL_BITS : positive := 1
    );
    port (
        sel      : in  std_logic_vector(SEL_BITS-1 downto 0);
        data_in  : in  std_logic_vector(WIDTH * (2**SEL_BITS) - 1 downto 0);
        data_out : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity mux_n;

architecture rtl of mux_n is
begin

    -- laco com fatias constantes: sintetizavel (fatia com indice variavel nao e)
    process(sel, data_in)
    begin
        data_out <= (others => '0');
        for i in 0 to 2**SEL_BITS - 1 loop
            if to_integer(unsigned(sel)) = i then
                data_out <= data_in((i+1)*WIDTH - 1 downto i*WIDTH);
            end if;
        end loop;
    end process;

end architecture rtl;
