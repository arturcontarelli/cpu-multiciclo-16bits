# Unidade de Controle (FSM)

Responsável: Tiago (`src/control/controller_fsm.vhd`).

## Visão geral

O controlador é uma máquina de estados finita (FSM) que decide, a cada pulso do botão de clock (debounced), qual conjunto de sinais de controle fica ativo. Ele **não executa** nenhuma operação — apenas gera os sinais que o datapath (`src/datapath`) e a memória (`src/memory`) usam para executar. O estado atual também é exposto nos LEDs verdes da FPGA (ver seção "LEDs verdes").

Entradas do controlador:
- `opcode(3:0)` — vem de um decodificador de instrução que mora fora de `src/control/` (responsabilidade da Parte 3, memória/common, conforme `docs/divisao-equipe.md`), fiado via `src/top/`.
- `zero` — flag de igualdade vinda da ALU (`src/datapath/alu.vhd`). A ALU calcula `Ri - Rj`; `zero = 1` quando o resultado é 0.
- `clk` (pulso debounced) e `reset`.

Saídas do controlador: sinais de controle listados na tabela da seção "Sinais de controle", mais `led_state`.

## Estados

Onze estados, agrupados nos 5 estágios clássicos do multiciclo que o enunciado pede (fetch, decode, execute, memory, write-back):

| Estado | Estágio macro | O que acontece |
|---|---|---|
| `FETCH` | Fetch | Busca a instrução na memória (`Mem[PC]`) e carrega no IR; calcula `PC+1` em paralelo. |
| `DECODE` | Decode | Lê os registradores Rj/Rk para os latches A/B; calcula especulativamente o alvo de branch (`PC+1 + imediato`) e guarda em ALUOut. |
| `EXEC_R` | Execute | ALU executa a operação R-type (ADD/SUB/AND/OR/SLT) sobre A e B. |
| `EXEC_ADDI` | Execute | ALU calcula `A + imediato` (ADDI). |
| `EXEC_ADDR` | Execute | ALU calcula o endereço efetivo `A + imediato` (para LD/ST). |
| `BRANCH` | Execute | Decide se o branch é tomado (BEQ/BNE) e escreve o PC condicionalmente. |
| `JUMP` | Execute | Escreve o PC incondicionalmente com o endereço de 12 bits do JMP. |
| `MEM_READ` | Memory | Lê a memória de dados no endereço calculado (LD). |
| `MEM_WRITE` | Memory | Escreve a memória de dados no endereço calculado (ST). |
| `WB_ALU` | Write-back | Escreve o resultado da ALU (ALUOut) no banco de registradores (R-type, ADDI). |
| `WB_MEM` | Write-back | Escreve o dado lido da memória (MDR) no banco de registradores (LD). |

Registradores intermediários do datapath que esta FSM assume (ver `docs/especificacao/05-caminho-dados.md`): `IR`, `A`, `B`, `ALUOut`, `MDR`. Carregam o valor do estado anterior sem sinal de enable dedicado (padrão multiciclo clássico) — só `PCWrite`, `PCWriteCond`, `IRWrite`, `RegWrite`, `MemRead` e `MemWrite` são enables explícitos vindos do controlador.

## Tabela de transições

```
FETCH -> DECODE                                   (sempre)

DECODE -> EXEC_R        se opcode ∈ {ADD,SUB,AND,OR,SLT}
DECODE -> EXEC_ADDI     se opcode = ADDI
DECODE -> EXEC_ADDR     se opcode ∈ {LD,ST}
DECODE -> BRANCH        se opcode ∈ {BEQ,BNE}
DECODE -> JUMP          se opcode = JMP

EXEC_R      -> WB_ALU
EXEC_ADDI   -> WB_ALU
EXEC_ADDR   -> MEM_READ   se opcode = LD
EXEC_ADDR   -> MEM_WRITE  se opcode = ST

MEM_READ    -> WB_MEM
MEM_WRITE   -> FETCH
WB_ALU      -> FETCH
WB_MEM      -> FETCH
BRANCH      -> FETCH
JUMP        -> FETCH
```

## Sinais de controle

| Sinal | Largura | Significado |
|---|---|---|
| `PCWrite` | 1 | Habilita escrita incondicional do PC (FETCH, JUMP). |
| `PCWriteCond` | 1 | Habilita escrita condicional do PC (BRANCH), combinada internamente com a polaridade de BEQ/BNE — ver nota abaixo. |
| `IorD` | 1 | Endereço de memória: `0` = PC (FETCH), `1` = ALUOut (LD/ST). Memória única (topologia fechada). |
| `IRWrite` | 1 | Habilita escrita no registrador de instrução (FETCH). |
| `MemRead` | 1 | Habilita leitura de memória. |
| `MemWrite` | 1 | Habilita escrita em memória. |
| `MemToReg` | 1 | Seleciona dado a escrever no banco de registradores: `0` = ALUOut, `1` = MDR. |
| `RegWrite` | 1 | Habilita escrita no banco de registradores. |
| `ALUSrcA` | 1 | Operando A da ALU: `0` = PC, `1` = registrador A (latched). |
| `ALUSrcB(1:0)` | 2 | Operando B da ALU: `00` = registrador B, `01` = constante 1 (incremento de PC), `10` = imediato estendido. |
| `ALUOp(2:0)` | 3 | Operação da ALU — ver tabela de codificação abaixo. |
| `PCSource(1:0)` | 2 | Próximo valor do PC: `00` = ALUOut sequencial (PC+1), `01` = ALUOut de branch, `10` = endereço de jump (12 bits). |
| `led_state` | 5 | Codificação one-hot do estágio macro atual — ver seção "LEDs verdes". |

`RegDst` não existe nesta FSM: neste ISA o registrador destino é sempre `Ri` (não há distinção rd/rt como no MIPS).

### Codificação de `ALUOp`

Esse ISA não tem campo `funct` compartilhado — cada operação R-type (ADD/SUB/AND/OR/SLT) já é um opcode próprio e completo. Por isso não existe aqui o esquema de dois níveis do MIPS clássico (`ALUOp` genérico + unidade de controle da ALU decodificando `funct`): o controlador já sabe a operação exata só pelo opcode e emite o código final direto.

| ALUOp | Operação |
|---|---|
| `000` | ADD |
| `001` | SUB |
| `010` | AND |
| `011` | OR |
| `100` | SLT |

Uso por estado: `EXEC_R` mapeia 1:1 pelo opcode; `DECODE`, `EXEC_ADDI`, `EXEC_ADDR` e `FETCH` forçam `ADD` (000); `BRANCH` força `SUB` (001) para gerar o `zero`.

## Tabela de sinais por estado

| Estado | PCWrite | PCWriteCond | IorD | IRWrite | MemRead | MemWrite | MemToReg | RegWrite | ALUSrcA | ALUSrcB | ALUOp | PCSource |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| FETCH | 1 | 0 | 0 | 1 | 1 | 0 | X | 0 | 0 | 01 | 000 | 00 |
| DECODE | 0 | 0 | X | 0 | 0 | 0 | X | 0 | 0 | 10 | 000 | X |
| EXEC_R | 0 | 0 | X | 0 | 0 | 0 | X | 0 | 1 | 00 | (por opcode) | X |
| EXEC_ADDI | 0 | 0 | X | 0 | 0 | 0 | X | 0 | 1 | 10 | 000 | X |
| EXEC_ADDR | 0 | 0 | X | 0 | 0 | 0 | X | 0 | 1 | 10 | 000 | X |
| MEM_READ | 0 | 0 | 1 | 0 | 1 | 0 | X | 0 | X | XX | XXX | X |
| MEM_WRITE | 0 | 0 | 1 | 0 | 0 | 1 | X | 0 | X | XX | XXX | X |
| WB_ALU | 0 | 0 | X | 0 | 0 | 0 | 0 | 1 | X | XX | XXX | X |
| WB_MEM | 0 | 0 | X | 0 | 0 | 0 | 1 | 1 | X | XX | XXX | X |
| BRANCH | 0 | ver nota | X | 0 | 0 | 0 | X | 0 | 1 | 00 | 001 | 01 |
| JUMP | 1 | 0 | X | 0 | 0 | 0 | X | 0 | X | XX | XXX | 10 |

`X` = não importa (don't care) naquele estado.

**Nota sobre `PCWriteCond` em BRANCH (BEQ vs BNE):** diferente do MIPS clássico (que só cobre BEQ e usa `PCWriteCond AND zero` fora do controlador), aqui o controlador já conhece o opcode dentro do estado `BRANCH` e precisa inverter a condição para BNE. A lógica é:

```
PCWriteCond = (opcode = BEQ AND zero = '1') OR (opcode = BNE AND zero = '0')
```

Isso é a única saída do controlador que depende de uma entrada (`zero`) além do estado atual — todas as outras saídas seguem o padrão Moore (dependem só do estado). Documentar isso explicitamente no comentário do VHDL evita o bug clássico de trocar a polaridade entre BEQ e BNE.

**Nota sobre `JMP`:** o endereço de 12 bits do campo `end` é usado diretamente como `PCSource = 10`; a decisão sobre concatenação com bits superiores do PC atual (estilo MIPS) vs. endereço absoluto depende da largura final do PC (decisão de pessoa 2/3) e deve ser confirmada antes de fechar o datapath de PC.

## LEDs verdes

O enunciado pede que os LEDs verdes indiquem o estado da unidade de controle ("fetch, decode, busca na memória etc."). Em vez de codificar os 11 estados internos em binário, `led_state` usa **one-hot de 5 bits**, um por estágio macro — mais simples de ler na placa e de defender na apresentação:

| `led_state` | Estágio | Estados internos mapeados |
|---|---|---|
| `00001` | Fetch | `FETCH` |
| `00010` | Decode | `DECODE` |
| `00100` | Execute | `EXEC_R`, `EXEC_ADDI`, `EXEC_ADDR`, `BRANCH`, `JUMP` |
| `01000` | Memory | `MEM_READ`, `MEM_WRITE` |
| `10000` | Write-back | `WB_ALU`, `WB_MEM` |

A quantidade de LEDs verdes realmente disponíveis na placa alvo depende do pin planning (Parte 4, `quartus/`) — confirmar que há pelo menos 5 LEDG livres.

## Riscos e decisões a validar

- **Timing de branch:** o endereço de branch é calculado especulativamente em `DECODE` (antes de saber se vai ser tomado); só a decisão e a escrita condicional do PC ocorrem em `BRANCH`. Nunca atualizar o PC no mesmo estado em que a ALU ainda está calculando o alvo.
- **Acoplamento:** `controller_fsm.vhd` nunca instancia ALU, banco de registradores ou memória — só portas de entrada/saída. A fiação real fica em `src/top/cpu_top.vhd`.
- **Reset:** a definir se é síncrono ou assíncrono; o testbench isolado (`sim/testbenches/tb_controller_fsm.vhd`) deve cobrir reset no meio de uma instrução.
- **Opcodes:** sempre via `use work.cpu_pkg.all` — nunca redefinidos localmente em `src/control/`.
