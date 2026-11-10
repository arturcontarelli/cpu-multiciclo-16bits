-- Extensao de sinal do imediato: 6 bits (-32 a +31) -> 16 bits.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;

entity sign_extend is
    port (
        imm     : in  std_logic_vector(5 downto 0);
        imm_ext : out word16
    );
end entity sign_extend;

architecture rtl of sign_extend is
begin
    imm_ext <= std_logic_vector(resize(signed(imm), 16));
end architecture rtl;
