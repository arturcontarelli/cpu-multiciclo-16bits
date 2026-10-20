# src/control

- `instruction_decoder.vhd` — extrai opcode, Ri, Rj, Rk e imediato da palavra de instrução (puramente combinacional, sem estado).
- `controller_fsm.vhd` — máquina de estados do multiciclo (fetch, decode, execute, memory, write-back). Gera todos os sinais de controle (RegWrite, MemRead, MemWrite, ALUOp, PCSrc, etc.) e também o código de estado usado nos LEDs verdes da FPGA.

O controlador decide **o que acontece**, mas nunca executa a operação em si — isso é responsabilidade exclusiva dos módulos em `src/datapath` e `src/memory`. Essa separação é o que permite trocar a FSM sem tocar no datapath.
