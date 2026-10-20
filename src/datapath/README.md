# src/datapath

Módulos do caminho de dados. Cada um com responsabilidade única (SRP) e porta mínima (interface segregada):

- `alu.vhd` — executa ADD, SUB, AND, OR, SLT a partir de um `alu_op`; não sabe o que é uma instrução.
- `register_file.vhd` — 8 registradores de 16 bits, leitura em 2 portas (Rj, Rk) e escrita em 1 (Ri); não sabe quando deve escrever (isso vem do controlador via `RegWrite`).
- `pc.vhd` — registrador do Program Counter + lógica de próximo PC.
- `sign_extend.vhd` — estende o imediato (6 bits → 16 bits) com sinal.
- `mux_n.vhd` — multiplexador genérico parametrizável (largura e nº de entradas), reutilizado em todos os pontos de seleção do datapath em vez de duplicar lógica de mux (DRY).

Nenhum módulo aqui conhece o controlador ou a memória — apenas recebe/envia sinais pelas portas. A fiação entre eles é feita em `src/top/cpu_top.vhd`.
