# sim/testbenches

Um testbench por módulo (`tb_alu.vhd`, `tb_register_file.vhd`, `tb_controller_fsm.vhd`, ...) para validar cada peça isoladamente antes da integração, mais um testbench de integração (`tb_cpu_top.vhd`) que roda os programas de `programs/mif` e verifica o resultado final nos registradores/memória.

O `tb_cpu.vhd` faz a integração sem a placa: FSM, datapath, decodificador e memória real carregando `programs/mif/programa_completo.mif`, conferindo os registradores. O `tb_cpu_top.vhd` testa o `cpu_top` inteiro só pelos pinos da placa: aperta o `KEY[0]` com quique (1 ciclo por aperto), confere PC nos HEX0–3, RDM/ULA nos HEX4–7 com o SW17 nas duas posições, os LEDs de estado e um reset no meio do programa. A memória usa a biblioteca `altera_mf`, que já vem com o ModelSim do Quartus. O caminho do `.mif` é relativo ao diretório onde o `vsim` roda; para rodar de outro lugar, passe `-gMIF_FILE=<caminho>` (vale para o `tb_memory`, o `tb_cpu` e o `tb_cpu_top`).

Testar módulos isolados só é possível porque eles não têm dependências escondidas entre si (ver `src/top/README.md`).
