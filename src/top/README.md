# src/top

`cpu_top.vhd` — entidade de topo. É o **único** lugar onde os módulos de `control`, `datapath`, `memory` e `io` se conectam entre si (inversão de dependência: os módulos de baixo nível não conhecem uns aos outros, só o topo os conhece e os liga).

Responsabilidades exclusivas desta pasta:
- instanciar todos os módulos;
- fazer a fiação (port map) entre eles;
- mapear portas externas da FPGA (botão de clock, switches, LEDs, HEX).

Não deve conter lógica de negócio (nenhuma ALU, nenhuma FSM aqui) — apenas composição. Por isso as inversões dos botões ficam no `debouncer` e o pulso de clock do reset fica no `clock_reset` (ambos em `src/io`); no topo só existem ligações, fatias de barramento e constantes (`LEDG <= cpu_clk & "000" & led_state`).

As portas têm os mesmos nomes de `quartus/pinos_de2_115.qsf`. A fiação do núcleo (FSM + decodificador + datapath + memória) é idêntica à de `sim/testbenches/tb_cpu.vhd`; o `tb_cpu_top.vhd` testa o topo inteiro pelos pinos.
