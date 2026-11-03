-- Registrador generico de WIDTH bits com enable e reset assincrono.
-- Usado para IR (en = IRWrite) e para RDM, A, B e ALUOut (en = '1',
-- escritos em todo ciclo).

library ieee;
use ieee.std_logic_1164.all;

entity register_n is
    generic (
        WIDTH : positive := 16
    );
    port (
        clk   : in  std_logic;
        reset : in  std_logic;
        en    : in  std_logic;
        d     : in  std_logic_vector(WIDTH-1 downto 0);
        q     : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity register_n;

architecture rtl of register_n is
    signal reg : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
begin

    process(clk, reset)
    begin
        if reset = '1' then
            reg <= (others => '0');
        elsif rising_edge(clk) then
            if en = '1' then
                reg <= d;
            end if;
        end if;
    end process;

    q <= reg;

end architecture rtl;
