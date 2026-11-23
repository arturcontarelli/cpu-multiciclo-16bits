# sim/testbenches

Um testbench por módulo (`tb_alu.vhd`, `tb_register_file.vhd`, `tb_controller_fsm.vhd`, ...) para validar cada peça isoladamente antes da integração, mais um testbench de integração (`tb_cpu_top.vhd`) que roda os programas de `programs/mif` e verifica o resultado final nos registradores/memória.

Enquanto o `cpu_top` não existe, o `tb_cpu.vhd` faz a integração sem a placa: FSM, datapath, decodificador e memória real carregando `programs/mif/programa_completo.mif`. A memória usa a biblioteca `altera_mf`, que já vem com o ModelSim do Quartus. O caminho do `.mif` é relativo ao diretório onde o `vsim` roda; para rodar de outro lugar, passe `-gMIF_FILE=<caminho>` (vale para o `tb_memory` e o `tb_cpu`).

Testar módulos isolados só é possível porque eles não têm dependências escondidas entre si (ver `src/top/README.md`).
