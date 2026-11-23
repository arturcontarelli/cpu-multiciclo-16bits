-- Decodificador de instrucao: puramente combinacional.
-- Separa os campos da palavra guardada no IR (formatos R, I e J ocupam
-- sempre as mesmas posicoes, entao nao depende do formato) e gera o
-- RegSrcB, que escolhe a segunda porta de leitura do banco:
--   0 = Rk (tipo R), 1 = Ri (ST: dado a gravar; BEQ/BNE: comparacao).
-- O RegSrcB sai daqui, e nao da FSM, porque A e B ja sao lidos no DECODE.

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity instruction_decoder is
    port (
        instr     : in  word16;
        opcode    : out opcode_t;
        ri        : out reg_addr;
        rj        : out reg_addr;
        rk        : out reg_addr;
        imm       : out std_logic_vector(5 downto 0);
        jump_addr : out std_logic_vector(11 downto 0);
        RegSrcB   : out std_logic
    );
end entity instruction_decoder;

architecture rtl of instruction_decoder is
    signal op : opcode_t;
begin
    op <= instr(15 downto 12);

    opcode    <= op;
    ri        <= instr(11 downto 9);
    rj        <= instr(8 downto 6);
    rk        <= instr(5 downto 3);
    imm       <= instr(5 downto 0);
    jump_addr <= instr(11 downto 0);

    RegSrcB <= '1' when op = OP_ST or op = OP_BEQ or op = OP_BNE else '0';
end architecture rtl;
