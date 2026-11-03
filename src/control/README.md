# src/control

- `controller_fsm.vhd` — máquina de estados do multiciclo (fetch, decode, execute, memory, write-back). Gera todos os sinais de controle (RegWrite, MemRead, MemWrite, ALUOp, PCSrc, etc.) e também o código de estado usado nos LEDs verdes da FPGA.

A entidade recebe o `opcode` (4 bits) como porta de entrada, já extraído por um decodificador de instrução que mora em outra pasta (memória/common — Parte 3, conforme `docs/divisao-equipe.md`) e é fiado via `src/top/`. `src/control/` não decodifica a palavra de instrução, só consome o opcode.

O controlador decide **o que acontece**, mas nunca executa a operação em si — isso é responsabilidade exclusiva dos módulos em `src/datapath` e `src/memory`. Essa separação é o que permite trocar a FSM sem tocar no datapath.
