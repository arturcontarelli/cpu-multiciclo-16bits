library ieee;
use IEEE.STD_LOGIC_1164.ALL;    

package cpu_pkg is

    -- largura da palavra e dos campos de instrução
    subtype word16 is std_logic_vector(15 downto 0);
    subtype reg_addr is std_logic_vector(2 downto 0); -- 8 registradores
    subtype opcode_t is std_logic_vector(3 downto 0); -- 4 bits de opcode

   -- opcodes (tabela do enunciado)
    constant OP_ADD  : opcode_t := "0000";
    constant OP_SUB  : opcode_t := "0001";
    constant OP_AND  : opcode_t := "0010";
    constant OP_OR   : opcode_t := "0011";
    constant OP_SLT  : opcode_t := "0100";
    constant OP_ADDI : opcode_t := "0101";
    constant OP_LD   : opcode_t := "0110";
    constant OP_ST   : opcode_t := "0111";
    constant OP_BEQ  : opcode_t := "1000";
    constant OP_BNE  : opcode_t := "1001";
    constant OP_JMP  : opcode_t := "1010";

end package cpu_pkg;