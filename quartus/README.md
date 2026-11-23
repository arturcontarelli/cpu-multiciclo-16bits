# quartus

Projeto Quartus para síntese e gravação na FPGA e pin planning (mapeamento de botão de clock, switches, LEDs e displays HEX às portas de `src/top/cpu_top.vhd`).

- `criar_projeto.tcl` — cria o projeto (`cpu_multiciclo.qpf/.qsf`) com o dispositivo, o topo `cpu_top`, todos os `.vhd`, o `.mif` e os pinos. Os `.qpf/.qsf` gerados estão no `.gitignore`: a fonte é este script.
- `pinos_de2_115.qsf` — pinos da DE2-115 usados pelo `cpu_top` (fonte única dos pinos; o script lê daqui).
- `pinout.md` — o que cada pino faz no projeto, nomes das portas do `cpu_top`, detalhes elétricos e como o clock da CPU é gerado.
- `mapa_placa.svg` — desenho da placa com o que cada botão, chave, LED e display faz.

## Compilar e gravar

1. Num terminal, **dentro desta pasta**: `quartus_sh -t criar_projeto.tcl`
   (no Windows: `C:\intelFPGA_lite\<versão>\quartus\bin64\quartus_sh.exe -t criar_projeto.tcl`).
   Para outro programa: `quartus_sh -t criar_projeto.tcl <nome>` (usa `programs/mif/<nome>.mif`).
2. Quartus → *File → Open Project* → `quartus/cpu_multiciclo.qpf`.
3. *Processing → Start Compilation*.
4. *Tools → Programmer* → Hardware Setup: **USB-Blaster** → modo **JTAG** → *Add File* `output_files/cpu_multiciclo.sof` → **Start**. (A chave RUN/PROG da placa fica em **RUN**.)
5. Na placa: aperte **KEY1** (reset) uma vez e use **KEY0** para avançar ciclo a ciclo.

Alternativa sem script (pela interface): *New Project Wizard* nesta pasta, dispositivo `EP4CE115F29C7`, topo `cpu_top`, adicionar os `.vhd` da lista do script e depois *Assignments → Import Assignments…* → `pinos_de2_115.qsf`.
