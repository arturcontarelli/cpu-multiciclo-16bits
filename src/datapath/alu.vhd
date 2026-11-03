-- ULA de 16 bits, adaptada do Lab05 (ula.vhd).
-- Removidos NOR, Overflow e Cout: nenhuma instrucao do projeto usa.
--
-- Codigos de alu_op (os mesmos que a FSM gera em ALUOp):
--   000 AND | 001 OR | 010 ADD | 100 SUB | 110 SLT (comparacao com sinal)
-- zero = 1 quando o resultado e 0; usado por BEQ/BNE (A - B).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;

entity alu is
    port (
        a      : in  word16;
        b      : in  word16;
        alu_op : in  std_logic_vector(2 downto 0);
        result : out word16;
        zero   : out std_logic
    );
end entity alu;

architecture rtl of alu is
    signal res : word16;
begin

    process(a, b, alu_op)
    begin
        case alu_op is
            when "000" => res <= a and b;
            when "001" => res <= a or b;
            when "010" => res <= std_logic_vector(unsigned(a) + unsigned(b));
            when "100" => res <= std_logic_vector(unsigned(a) - unsigned(b));
            when "110" =>
                if signed(a) < signed(b) then
                    res <= x"0001";
                else
                    res <= x"0000";
                end if;
            when others => res <= (others => '0');
        end case;
    end process;

    result <= res;
    zero   <= '1' when res = x"0000" else '0';

end architecture rtl;
