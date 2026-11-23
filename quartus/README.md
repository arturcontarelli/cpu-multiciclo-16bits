# quartus

Projeto Quartus para síntese e gravação na FPGA: `.qpf`, `.qsf` e pin planning (mapeamento de botão de clock, switches, LEDs e displays HEX às portas de `src/top/cpu_top.vhd`).

Mantenha o pin planning documentado aqui (comentários no `.qsf` ou um arquivo `pinout.md`) para que qualquer membro do grupo possa regravar a placa sem precisar redescobrir os pinos.

- `pinos_de2_115.qsf` — pinos da DE2-115 usados pelo `cpu_top`, prontos para importar no Quartus.
- `pinout.md` — o que cada pino faz no projeto, nomes das portas do `cpu_top`, detalhes elétricos e como o clock da CPU é gerado.
