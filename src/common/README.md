# src/common

Pacote VHDL (`cpu_pkg.vhd`) com tudo que é compartilhado entre módulos, para evitar duplicação (DRY):

- Constantes de opcode (ADD, SUB, AND, OR, SLT, ADDI, LD, ST, BEQ, BNE, JMP)
- Tipos e subtipos (ex.: `word16`, `reg_addr`)
- Larguras de bits dos campos de instrução (Tipo R, I, J)

Nenhum outro módulo deve redefinir essas constantes — todos importam este pacote.
