# src/memory

- `instruction_memory.vhd` — ROM/RAM inicializada via `.mif`, somente leitura durante a execução.
- `data_memory.vhd` — memória de dados, leitura e escrita (`MemRead`/`MemWrite` vindos do controlador).

Se o projeto usar memória única compartilhada entre instrução e dados (decisão de equipe), documentar aqui a justificativa e ajustar esta pasta para refletir isso — mantendo o restante dos módulos alheios a essa decisão (eles só veem as portas de endereço/dado).
