# sim/testbenches

Um testbench por módulo (`tb_alu.vhd`, `tb_register_file.vhd`, `tb_controller_fsm.vhd`, ...) para validar cada peça isoladamente antes da integração, mais um testbench de integração (`tb_cpu_top.vhd`) que roda os programas de `programs/mif` e verifica o resultado final nos registradores/memória.

Testar módulos isolados só é possível porque eles não têm dependências escondidas entre si (ver `src/top/README.md`).
