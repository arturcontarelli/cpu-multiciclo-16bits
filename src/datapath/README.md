# src/datapath

Módulos do caminho de dados. Cada um com responsabilidade única (SRP) e porta mínima (interface segregada):

- `alu.vhd` — executa ADD, SUB, AND, OR, SLT a partir de um `alu_op` de 3 bits (mesmo código do `ALUOp` da FSM); não sabe o que é uma instrução.
- `register_file.vhd` — 8 registradores de 16 bits, R0 sempre 0, leitura em 2 portas e escrita em 1; não sabe quando deve escrever (isso vem do controlador via `RegWrite`).
- `pc.vhd` — registrador do Program Counter; escreve quando `PCWrite OR (PCWriteCond AND (zero XOR BNE))`.
- `sign_extend.vhd` — estende o imediato (6 bits → 16 bits) com sinal.
- `mux_n.vhd` — multiplexador genérico (largura e nº de entradas), reutilizado em todos os pontos de seleção (DRY). As entradas chegam concatenadas, com a entrada 0 nos bits baixos.
- `register_n.vhd` — registrador genérico com enable, usado para IR, RDM, A, B e ALUOut.
- `datapath.vhd` — compõe os módulos acima. Recebe pelas portas os sinais de controle (FSM), os campos da instrução e o `RegSrcB` (decodificador) e o dado lido da memória; entrega o endereço e o dado de escrita da memória, o IR e as saídas para os displays.

Nenhum módulo aqui conhece o controlador, o decodificador ou a memória — apenas recebe/envia sinais pelas portas. A ligação do `datapath` com esses blocos é feita em `src/top/cpu_top.vhd`.
