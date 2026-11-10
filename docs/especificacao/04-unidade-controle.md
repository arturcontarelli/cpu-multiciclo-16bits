# Unidade de Controle (FSM)

Responsável: Tiago (`src/control/controller_fsm.vhd`).

## Visão geral

O controlador é uma máquina de estados finita (FSM) que decide, a cada pulso do botão de clock (debounced), qual conjunto de sinais de controle fica ativo. Ele **não executa** nenhuma operação — apenas gera os sinais que o datapath (`src/datapath`, Parte 2) e a memória (`src/memory`, Parte 3) usam para executar. O estado atual também é exposto nos LEDs verdes da FPGA (ver seção "LEDs verdes").

Entradas do controlador:
- `opcode(3:0)` — vem de um decodificador de instrução que mora fora de `src/control/` (Parte 3), fiado via `src/top/`.
- `clk` (pulso debounced) e `reset`.

O controlador **não recebe `zero` como entrada** (decisão alinhada com a Parte 2, ver seção "Sinais de controle" / `BNE`). A lógica de decisão do branch (`Zero XOR BNE`) é resolvida dentro do datapath, não no controlador — isso mantém a FSM 100% Moore (todas as saídas dependem só do estado atual).

Saídas do controlador: sinais de controle listados na tabela da seção "Sinais de controle", mais `led_state`.

## Estados

Dez estados, agrupados nos 5 estágios clássicos do multiciclo que o enunciado pede (fetch, decode, execute, memory, write-back). `EXEC_ADDI` e `EXEC_ADDR` do rascunho inicial foram fundidos em um único estado `ADDR_CALC`, já que ADDI e LD/ST calculam exatamente `A + imediato` com os mesmos sinais de controle — a única diferença é o que acontece depois (ver tabela de transições):

| Estado | Estágio macro | O que acontece |
|---|---|---|
| `FETCH` | Fetch | Busca a instrução na memória (`Mem[PC]`) e carrega no IR; calcula `PC+1` em paralelo. |
| `DECODE` | Decode | Lê os registradores para os latches A/B; calcula especulativamente o alvo de branch (`PC+1 + imediato`) e guarda em ALUOut. |
| `ADDR_CALC` | Execute | ALU calcula `A + imediato` — usado por ADDI (resultado final) e por LD/ST (endereço efetivo). |
| `EXEC_R` | Execute | ALU executa a operação R-type (ADD/SUB/AND/OR/SLT) sobre A e B. |
| `BRANCH` | Execute | Calcula `A - B` na ALU e sinaliza `PCWriteCond`; a decisão real (BEQ vs BNE) é resolvida no datapath via `Zero XOR BNE`. |
| `JUMP` | Execute | Escreve o PC incondicionalmente com o endereço de 12 bits do JMP (absoluto, sem concatenação com o PC atual — confirmado com a Parte 2). |
| `MEM_READ` | Memory | Lê a memória de dados no endereço calculado (LD). |
| `MEM_WRITE` | Memory | Escreve a memória de dados no endereço calculado (ST). |
| `WB_ALU` | Write-back | Escreve o resultado da ALU (ALUOut) no banco de registradores (R-type, ADDI). |
| `WB_MEM` | Write-back | Escreve o dado lido da memória (RDM) no banco de registradores (LD). |

Registradores intermediários do datapath (Parte 2): `IR`, `A`, `B`, `ALUOut`, `RDM` (registrador de dados da memória — mesma função que "MDR" em inglês, nome alinhado com a Parte 2). Carregam o valor do estado anterior sem sinal de enable dedicado (escritos todo ciclo, confirmado pela Parte 2) — só `PCWrite`, `PCWriteCond`, `IRWrite`, `RegWrite`, `MemRead` e `MemWrite` são enables explícitos vindos do controlador.

## Tabela de transições

```
FETCH -> DECODE                                   (sempre)

DECODE -> EXEC_R        se opcode ∈ {ADD,SUB,AND,OR,SLT}
DECODE -> ADDR_CALC     se opcode ∈ {ADDI,LD,ST}
DECODE -> BRANCH        se opcode ∈ {BEQ,BNE}
DECODE -> JUMP          se opcode = JMP

EXEC_R      -> WB_ALU
ADDR_CALC   -> WB_ALU      se opcode = ADDI
ADDR_CALC   -> MEM_READ    se opcode = LD
ADDR_CALC   -> MEM_WRITE   se opcode = ST

MEM_READ    -> WB_MEM
MEM_WRITE   -> FETCH
WB_ALU      -> FETCH
WB_MEM      -> FETCH
BRANCH      -> FETCH
JUMP        -> FETCH
```

## Sinais de controle

Contrato fechado com a Parte 2 (datapath):

| Sinal | Largura | Significado |
|---|---|---|
| `PCWrite` | 1 | Habilita escrita incondicional do PC (FETCH, JUMP). |
| `PCWriteCond` | 1 | Habilita a *tentativa* de escrita condicional do PC (ativo em `BRANCH`). A escrita de fato só ocorre se `Zero XOR BNE` for `1` — essa combinação acontece no datapath, não no controlador. |
| `BNE` | 1 | `1` quando a instrução atual é BNE, `0` caso contrário (inclusive para BEQ). Derivado direto do `opcode`, independente do estado — não é um sinal "por estado" como os demais. |
| `IorD` | 1 | Endereço de memória: `0` = PC (FETCH), `1` = ALUOut (LD/ST). Memória única (topologia fechada). |
| `IRWrite` | 1 | Habilita escrita no registrador de instrução (FETCH). |
| `MemRead` | 1 | Habilita leitura de memória. |
| `MemWrite` | 1 | Habilita escrita em memória. |
| `MemToReg` | 1 | Seleciona dado a escrever no banco de registradores: `0` = ALUOut, `1` = RDM. |
| `RegWrite` | 1 | Habilita escrita no banco de registradores. |
| `ALUSrcA` | 1 | Operando A da ALU: `0` = PC, `1` = registrador A (latched). |
| `ALUSrcB(1:0)` | 2 | Operando B da ALU: `00` = registrador B, `01` = constante 1 (incremento de PC), `10` = imediato estendido. |
| `ALUOp(2:0)` | 3 | Código final da ALU — ver tabela de codificação abaixo. |
| `PCSource(1:0)` | 2 | Próximo valor do PC: `00` = saída direta da ULA (PC+1, calculado no próprio FETCH), `01` = ALUOut (alvo de branch, calculado no DECODE), `10` = endereço de jump (12 bits). |
| `led_state` | 5 | Codificação one-hot do estágio macro atual — ver seção "LEDs verdes". |

`RegDst` não existe nesta FSM: neste ISA o registrador destino é sempre `Ri`. O mux da porta B do banco de registradores (Rk no tipo R, Ri no branch/ST, etc.) é resolvido pelo decodificador direto a partir do opcode — **não** é um sinal gerado pelo controlador.

### Codificação de `ALUOp`

O controlador emite direto o código final de 3 bits que a ALU (Parte 2, já testada em laboratório anterior) consome — sem unidade intermediária de "ALU control" traduzindo um código genérico, porque não há campo `funct` compartilhado neste ISA (decisão fechada com a Parte 2):

| ALUOp | Operação |
|---|---|
| `000` | AND |
| `001` | OR |
| `010` | ADD |
| `100` | SUB |
| `110` | SLT |

Uso por estado: `EXEC_R` mapeia 1:1 pelo opcode; `DECODE`, `ADDR_CALC` e `FETCH` forçam `ADD` (`010`); `BRANCH` força `SUB` (`100`) para gerar o `zero` que o datapath usa internamente.

## Tabela de sinais por estado

| Estado | PCWrite | PCWriteCond | IorD | IRWrite | MemRead | MemWrite | MemToReg | RegWrite | ALUSrcA | ALUSrcB | ALUOp | PCSource |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| FETCH | 1 | 0 | 0 | 1 | 1 | 0 | X | 0 | 0 | 01 | 010 | 00 |
| DECODE | 0 | 0 | X | 0 | 0 | 0 | X | 0 | 0 | 10 | 010 | X |
| ADDR_CALC | 0 | 0 | X | 0 | 0 | 0 | X | 0 | 1 | 10 | 010 | X |
| EXEC_R | 0 | 0 | X | 0 | 0 | 0 | X | 0 | 1 | 00 | (por opcode) | X |
| MEM_READ | 0 | 0 | 1 | 0 | 1 | 0 | X | 0 | X | XX | XXX | X |
| MEM_WRITE | 0 | 0 | 1 | 0 | 0 | 1 | X | 0 | X | XX | XXX | X |
| WB_ALU | 0 | 0 | X | 0 | 0 | 0 | 0 | 1 | X | XX | XXX | X |
| WB_MEM | 0 | 0 | X | 0 | 0 | 0 | 1 | 1 | X | XX | XXX | X |
| BRANCH | 0 | 1 | X | 0 | 0 | 0 | X | 0 | 1 | 00 | 100 | 01 |
| JUMP | 1 | 0 | X | 0 | 0 | 0 | X | 0 | X | XX | XXX | 10 |

`X` = não importa (don't care) naquele estado. `BNE` não aparece nesta tabela porque não depende do estado, só do opcode (ver seção de sinais).

**Nota sobre `PCWriteCond`/`BNE` (decisão fechada com a Parte 2):** diferente do MIPS clássico (que só cobre BEQ), este controlador fica **puramente Moore**: `PCWriteCond` é `1` sempre que o estado atual é `BRANCH`, sem olhar `opcode` nem `zero`. A polaridade BEQ/BNE é resolvida inteiramente no datapath, que calcula `Zero XOR BNE` e só efetiva a escrita do PC quando esse resultado é `1`. O controlador só fornece `BNE` (derivado do opcode) para essa conta.

## LEDs verdes

O enunciado pede que os LEDs verdes indiquem o estado da unidade de controle ("fetch, decode, busca na memória etc."). `led_state` usa **one-hot de 5 bits**, um por estágio macro (decisão mantida após comparar com a sugestão alternativa de codificação binária dos 10 estados — optamos pelo agrupamento por bater literalmente com o texto do enunciado e ser mais fácil de ler na placa durante a apresentação):

| `led_state` | Estágio | Estados internos mapeados |
|---|---|---|
| `00001` | Fetch | `FETCH` |
| `00010` | Decode | `DECODE` |
| `00100` | Execute | `ADDR_CALC`, `EXEC_R`, `BRANCH`, `JUMP` |
| `01000` | Memory | `MEM_READ`, `MEM_WRITE` |
| `10000` | Write-back | `WB_ALU`, `WB_MEM` |

A quantidade de LEDs verdes realmente disponíveis na placa alvo depende do pin planning (Parte 4, `quartus/`) — confirmar que há pelo menos 5 LEDG livres.

## Riscos e pontos de atenção

- **Timing de branch:** o endereço de branch é calculado especulativamente em `DECODE`; a decisão (`Zero XOR BNE`) e a escrita condicional do PC ocorrem em `BRANCH`. Nunca atualizar o PC no mesmo estado em que a ALU ainda está calculando o alvo.
- **Acoplamento:** `controller_fsm.vhd` nunca instancia ALU, banco de registradores ou memória — só portas de entrada/saída. A fiação real fica em `src/top/cpu_top.vhd`.
- **Reset:** assíncrono (decisão de projeto — o reset vem de um botão/switch físico, não sincronizado ao clock manual). O testbench isolado (`sim/testbenches/tb_controller_fsm.vhd`) deve cobrir reset no meio de uma instrução.
- **Opcodes:** sempre via `use work.cpu_pkg.all` — nunca redefinidos localmente em `src/control/`.
- **Leitura síncrona da memória (decidido):** a RAM do Quartus (`altsyncram`) tem leitura síncrona. Por isso ela é ligada no **clock invertido** (ver [`decisoes.md`](decisoes.md)), e esta FSM não precisa de estados de espera em `FETCH` e `MEM_READ`. Se essa decisão mudar, a FSM precisa ganhar esses estados.

## Status de implementação

- `src/control/controller_fsm.vhd` — implementado, batendo 1:1 com as tabelas de estado/sinais acima (10 estados, saídas puramente Moore, `ALUOp` no código final de 3 bits da ALU, `BNE` derivado do opcode).
- `sim/testbenches/tb_controller_fsm.vhd` — testbench isolado implementado, cobrindo os 11 opcodes (um teste por tipo de instrução), a distinção `BNE`/`PCWriteCond` em `BRANCH`, e reset assíncrono no meio de uma instrução (`ADDR_CALC`). Nenhuma ALU/banco de registradores/memória real é instanciada no teste.
- Evidência de execução do testbench (log do simulador) e os resultados consolidados dos testes de integração ficam em `docs/especificacao/06-testes.md` (Parte 5) — este documento cobre só o desenho da unidade de controle, não os resultados de simulação.
