-- Program Counter de 16 bits.
-- O valor de entrada (pc_next) vem do mux PCSource no datapath.
-- O PC e escrito quando:
--   PCWrite = 1                              (FETCH, JUMP)
--   ou PCWriteCond = 1 e (zero xor BNE) = 1  (BRANCH: BEQ desvia se zero = 1,
--                                             BNE desvia se zero = 0)
-- Reset assincrono volta o PC para 0.

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity pc is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        PCWrite     : in  std_logic;
        PCWriteCond : in  std_logic;
        BNE         : in  std_logic;
        zero        : in  std_logic;
        pc_next     : in  word16;
        pc_out      : out word16
    );
end entity pc;

architecture rtl of pc is
    signal pc_reg : word16 := (others => '0');
    signal pc_en  : std_logic;
begin

    pc_en <= PCWrite or (PCWriteCond and (zero xor BNE));

    process(clk, reset)
    begin
        if reset = '1' then
            pc_reg <= (others => '0');
        elsif rising_edge(clk) then
            if pc_en = '1' then
                pc_reg <= pc_next;
            end if;
        end if;
    end process;

    pc_out <= pc_reg;

end architecture rtl;
