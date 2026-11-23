# src/io

Periféricos da FPGA, isolados do núcleo da CPU (a CPU não deveria depender de como ela é exibida):

- `debouncer.vhd` — filtra o ruído (quique) de um botão `KEY`: sincroniza no `CLOCK_50` e só aceita a mudança depois de 20 ms estável. Entrega o nível invertido (`1` = apertado), já pronto para ser clock ou reset.
- `clock_reset.vhd` — gera o `cpu_clk` e o `cpu_reset` a partir do `KEY[0]` e do `KEY[1]` (dois `debouncer`). Soltar o reset também gera uma borda de descida no clock, para a memória registrar o endereço 0 (motivo no cabeçalho do arquivo).
- `hex_display.vhd` — decodificador binário → 7 segmentos (ativo em 0), reutilizado (DRY) para todos os displays HEX0–HEX7 em vez de duplicar a tabela de segmentos em cada display.
- `hex_mux.vhd` — multiplexa RDM (`SW17 = 0`) vs. saída da ULA (`SW17 = 1`) nos displays HEX4–HEX7.

Esses módulos só existem para a demonstração na placa; a lógica da CPU em si (`src/control`, `src/datapath`, `src/memory`) não depende de nada aqui. Explicação completa: seção "Integração na placa" de `docs/especificacao/01-descricao-topologia.md`.
