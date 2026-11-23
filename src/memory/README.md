# src/memory

- `memory.vhd` — memória **única** de instruções e dados (4096 × 16), uma `altsyncram` inicializada por um `.mif` (generic `MIF_FILE`). Fica no clock invertido para que a leitura síncrona da RAM não exija estados de espera na FSM. O endereço (PC ou ALUOut) é escolhido pelo mux `IorD` dentro do datapath; aqui só chega o endereço pronto. Justificativa em `docs/especificacao/01-descricao-topologia.md`.
- `instruction_decoder.vhd` — puramente combinacional: separa os campos do IR (opcode, Ri, Rj, Rk, imediato, endereço do JMP) e gera o `RegSrcB` (1 em ST, BEQ e BNE). Formatos em `docs/especificacao/03-formato-instrucoes.md`.

Nenhum módulo daqui conhece a FSM ou o datapath; a ligação é feita em `src/top/cpu_top.vhd`.
