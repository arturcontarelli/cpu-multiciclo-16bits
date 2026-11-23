# Testes

Todos os testes estão em `sim/testbenches/` e rodam no ModelSim do Quartus 20.1. Cada testbench confere as saídas com `if ... report "FALHA"` e termina com `tb_<nome>: OK` ou com a contagem de falhas. Todos compilam em VHDL-93 e VHDL-2008.

## Testes por módulo

| Testbench | O que testa |
|---|---|
| `tb_alu` | As 5 operações, `zero`, estouro (`0x7FFF + 1`), resultado negativo e SLT com sinal. |
| `tb_register_file` | Escrita e leitura nas duas portas, escrita em R0 ignorada e reset assíncrono. |
| `tb_pc` | As 4 combinações de BEQ/BNE com `zero`, `PCWrite` incondicional e reset assíncrono. |
| `tb_sign_extend` | Imediatos positivos, negativos e nos limites (−32 e +31). |
| `tb_mux_n`, `tb_register_n` | Mux e registrador genéricos com larguras diferentes. |
| `tb_controller_fsm` | Sequência de estados e sinais de controle para os 11 opcodes, `BNE`/`PCWriteCond` e reset no meio de uma instrução. |
| `tb_instruction_decoder` | Campos dos três formatos e `RegSrcB` para os 16 opcodes. |
| `tb_memory` | Conteúdo do `.mif`, temporização da leitura no clock invertido, escrita e leitura de volta, bits altos do endereço ignorados. |

## Testes de integração

Os três usam o programa `programs/asm/programa_completo.asm`, que usa as 11 instruções: desvio tomado e não tomado, laço com desvio para trás, JMP por cima de instrução "veneno", ST seguido de LD do mesmo endereço e escrita em R0. Estado final esperado: R1 = 6, R2 = 0, R3 = 3, R4 = 9, R5 = 3, R6 = `000F`, R7 = 9, PC parado em 18.

| Testbench | O que integra |
|---|---|
| `tb_datapath` | Datapath + FSM real, com modelos simples de memória e decodificador. |
| `tb_cpu` | FSM + datapath + decodificador + memória real (`altsyncram`) carregando o `.mif`: a CPU inteira sem a placa. |
| `tb_cpu_top` | O `cpu_top` inteiro, testado **só pelos pinos da placa** (detalhes abaixo). |

**Teste de mutação.** Para mostrar que os testes detectam erros, foram plantados defeitos de propósito, um de cada vez, e todos foram pegos: SLT sem sinal, R0 gravável, BNE ignorado, `RegSrcB` sem o BNE, `PCSource = 00` ligado ao ALUOut, uma palavra do `.mif` trocada e memória sem o clock invertido.

### `tb_cpu_top`: a placa simulada

Testa o `cpu_top` como alguém olhando a placa, com o programa `programa_completo.mif`:

- aperta o `KEY[0]` **com quique** (3 rebotes de 40 ns antes e depois) e confere que cada aperto gera exatamente um ciclo;
- confere ciclo a ciclo a primeira instrução (`ADDI R1, R0, 6`): PC nos HEX0–3, estado nos LEDG4–0, RDM e ULA nos HEX4–7 com o SW17 nas duas posições;
- confere o LEDG8 com o botão apertado e solto;
- roda o programa até o fim e confere o PC parado em `0012`/`0013`;
- dá **reset no meio do programa** e confere que a primeira instrução é buscada de novo corretamente (o teste que pegou o problema descrito em [08](08-dificuldades.md)).

## Teste na placa

Depois de gravar e apertar o reset (`KEY[1]`), avança-se com o `KEY[0]` e compara-se a placa com o gabarito completo da seção [07](07-resultados-discussao.md). Pontos que valem mostrar na apresentação:

| Apertos | O que observar | Prova que |
|---|---|---|
| 0 → 4 | LEDs: fetch → decode → execute → write-back → fetch; PC 0000 → 0001 | FSM e ADDI |
| 1 | SW17 = 0: `5206` (a instrução lida); SW17 = 1: `0007` (PC + 6, alvo especulativo do desvio) | RDM, ULA e mux do SW17 |
| 30–31 | ST: execute com ULA = `001E` (endereço 30) e depois memory | cálculo de endereço do ST |
| 36 | LD em write-back com RDM = `0009` | o ST gravou e o LD leu de volta |
| 38 → 40 | BEQ: PC vai de `000A` para `000B`, pulando o "veneno" do endereço 10 | desvio tomado |
| 41 → 43 | BNE não tomado: PC segue em `000C` | desvio não tomado |
| 53 → 54 | BNE do laço: PC volta de `000F` para `000D` | desvio para trás |
| 69 → 71 | JMP: PC vai para `0011` | salto incondicional |
| 75 em diante | PC alterna `0012`/`0013` para sempre | fim de programa (`BEQ R0, R0, -1`) |

O PC mostrado é o valor no estado atual. No FETCH ele é o endereço da instrução que está sendo buscada; do DECODE em diante ele já foi incrementado (PC + 1).
