# Divisão de Trabalho — Projeto CPU Multiciclo 16 bits

Divisão sugerida para um grupo de 5 pessoas, baseada na descrição do projeto (`docs/descricao-projeto.md`).

---

## 1. Unidade de Controle (FSM)

- Projetar a máquina de estados do multiciclo (fetch, decode, execute, memory, write-back)
- Definir a tabela de estados × sinais de controle (RegWrite, MemRead, MemWrite, ALUOp, PCSrc, etc.)
- Implementar em VHDL (`controller.vhd`)
- Gerar o diagrama de estados para o documento de especificação
- Mapear os estados para os LEDs verdes (requisito da FPGA)

## 2. Caminho de Dados — ALU e Banco de Registradores

- Implementar a ALU (ADD, SUB, AND, OR, SLT) com as flags necessárias
- Implementar o banco de registradores (8 registradores de 16 bits — 3 bits de endereço)
- Implementar o PC, o somador de PC e a lógica de desvio (BEQ/BNE/JMP)
- Montar o diagrama de caminho de dados completo

## 3. Memória e Decodificação de Instruções

- Implementar a memória de instrução/dados (ou memória única, conforme topologia escolhida)
- Implementar o decodificador de instrução (extração de opcode, Ri, Rj, Rk, imediato, extensão de sinal)
- Criar os arquivos `.mif` de inicialização
- Garantir os formatos R, I e J corretamente (4+3+3+3+3 bits, etc.)

## 4. Integração FPGA (top-level) e Periféricos

- Integrar todos os módulos no `top_level.vhd`
- Implementar o debouncer do botão de clock
- Implementar os displays HEX0–HEX3 (valor do PC) e HEX4–HEX7 (RDM/saída da ULA, multiplexado pelo switch 17)
- Sintetizar, gravar na placa e validar fisicamente

## 5. Testes, Documentação e Coordenação

- Escrever os programas de teste (um para cada instrução + um programa combinado)
- Validar resultados em simulação (ModelSim/Quartus) antes da gravação na FPGA
- Consolidar o documento de especificação (descrição textual, topologia, registradores, diagramas, resultados, dificuldades, uso de IA)
- Organizar a entrega no Canvas (pdf + .vhd + .mif) e preparar a apresentação

---

## Observações importantes

- As pessoas das partes 2 e 3 devem alinhar a interface (sinais que trafegam entre ALU/regs e memória) no início, já que são as duas peças mais acopladas do datapath.
- A pessoa da parte 1 (controle) depende do que as partes 2 e 3 definirem como sinais de entrada/saída dos seus módulos — vale uma reunião curta de "contrato de sinais" antes de codificar.
- A pessoa da parte 5 deve começar a escrever a documentação desde o início (não deixar para o final), coletando material das outras 4 partes.
- Todos devem registrar quais trechos foram desenvolvidos com uso de IA e por quê, já que isso é item obrigatório de entrega.
