-- Banco de 8 registradores de 16 bits, adaptado do Lab05 (banco_registradores.vhd).
-- Leitura combinacional em duas portas, escrita sincrona (borda de subida)
-- quando RegWrite = 1. R0 vale sempre 0: escritas nele sao ignoradas.
-- Reset assincrono zera todos os registradores.
--
-- Quem escolhe os enderecos e o top/decodificador: porta A = Rj,
-- porta B = Rk ou Ri (RegSrcB), escrita = Ri.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;

entity register_file is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        RegWrite    : in  std_logic;
        read_addr_a : in  reg_addr;
        read_addr_b : in  reg_addr;
        write_addr  : in  reg_addr;
        write_data  : in  word16;
        read_data_a : out word16;
        read_data_b : out word16;
        -- depuracao: R7 (bits altos) ... R0 (bits baixos), para testbench e placa
        reg_dump    : out std_logic_vector(127 downto 0)
    );
end entity register_file;

architecture rtl of register_file is
    type reg_array_t is array (0 to 7) of word16;
    signal regs : reg_array_t := (others => (others => '0'));
begin

    process(clk, reset)
    begin
        if reset = '1' then
            regs <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if RegWrite = '1' and write_addr /= "000" then
                regs(to_integer(unsigned(write_addr))) <= write_data;
            end if;
        end if;
    end process;

    read_data_a <= regs(to_integer(unsigned(read_addr_a)));
    read_data_b <= regs(to_integer(unsigned(read_addr_b)));

    reg_dump <= regs(7) & regs(6) & regs(5) & regs(4) & regs(3) & regs(2) & regs(1) & regs(0);

end architecture rtl;
