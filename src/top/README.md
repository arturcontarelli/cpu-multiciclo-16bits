# src/top

`cpu_top.vhd` — entidade de topo. É o **único** lugar onde os módulos de `control`, `datapath`, `memory` e `io` se conectam entre si (inversão de dependência: os módulos de baixo nível não conhecem uns aos outros, só o topo os conhece e os liga).

Responsabilidades exclusivas desta pasta:
- instanciar todos os módulos;
- fazer a fiação (port map) entre eles;
- mapear portas externas da FPGA (botão de clock, switches, LEDs, HEX).

Não deve conter lógica de negócio (nenhuma ALU, nenhuma FSM aqui) — apenas composição.
