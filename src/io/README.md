# src/io

Periféricos da FPGA, isolados do núcleo da CPU (a CPU não deveria depender de como ela é exibida):

- `debouncer.vhd` — trata o ruído do botão usado como clock manual.
- `hex_display.vhd` — decodificador binário → 7 segmentos, reutilizado (DRY) para todos os displays HEX0–HEX7 em vez de duplicar a tabela de segmentos em cada display.
- `hex_mux.vhd` — multiplexa RDM vs. saída da ULA nos displays HEX4–HEX7 conforme o switch 17.

Esses módulos só existem para a demonstração na placa; a lógica da CPU em si (`src/control`, `src/datapath`, `src/memory`) não deve depender de nada aqui.
