# Descrição e Topologia

## O projeto

CPU multiciclo de 16 bits em VHDL, sintetizada no Quartus e gravada na FPGA da placa DE2-115. Ela executa as 11 instruções do enunciado (`docs/descricao-projeto.md`): ADD, SUB, AND, OR, SLT, ADDI, LD, ST, BEQ, BNE e JMP. O clock é manual, gerado por um botão com debouncer. Os displays e os LEDs da placa mostram o PC, o dado lido da memória ou a saída da ULA, e o estado da unidade de controle.

A base é o processador multiciclo MIPS do Patterson & Hennessy (*Computer Organization and Design*, 2ª ed., cap. 5). O enunciado deixa várias coisas em aberto, e onde o grupo não seguiu o livro está marcado como *(adaptação)* nas seções.

## Por que multiciclo

Cada instrução é dividida em etapas de um ciclo: busca, decodificação, execução, acesso à memória e escrita no registrador. Uma instrução usa só as etapas de que precisa, e por isso leva de 3 a 5 ciclos. Entre um ciclo e o próximo, os resultados ficam em registradores intermediários (IR, RDM, A, B e ALUOut). Com isso, a mesma ULA e a mesma memória são reaproveitadas em ciclos diferentes da mesma instrução.

| Instruções | Ciclos | Estados percorridos |
|---|---|---|
| ADD, SUB, AND, OR, SLT | 4 | FETCH → DECODE → EXEC_R → WB_ALU |
| ADDI | 4 | FETCH → DECODE → ADDR_CALC → WB_ALU |
| LD | 5 | FETCH → DECODE → ADDR_CALC → MEM_READ → WB_MEM |
| ST | 4 | FETCH → DECODE → ADDR_CALC → MEM_WRITE |
| BEQ, BNE | 3 | FETCH → DECODE → BRANCH |
| JMP | 3 | FETCH → DECODE → JUMP |

## Topologia

A CPU tem quatro blocos, ligados somente na entidade de topo (`src/top/cpu_top.vhd`):

| Bloco | Pasta | Função | Seção |
|---|---|---|---|
| Unidade de controle | `src/control/` | Máquina de estados de 10 estados. Recebe o opcode e gera os sinais de controle e o estado para os LEDs. | [04](04-unidade-controle.md) |
| Caminho de dados | `src/datapath/` | PC, banco de registradores, ULA, registradores intermediários e muxes. Executa o que a unidade de controle manda. | [05](05-caminho-dados.md) |
| Memória e decodificador | `src/memory/`, `src/common/` | Memória única de instruções e dados. O decodificador separa os campos da instrução guardada no IR. | — |
| Periféricos da placa | `src/io/` | Debouncer do botão de clock e displays de 7 segmentos. | — |

Os blocos não se conhecem: cada um só vê as próprias portas. Opcodes e tipos ficam num pacote único (`src/common/cpu_pkg.vhd`), usado por todos.

## Memória

| Decisão | Valor | Motivo |
|---|---|---|
| Topologia | Memória única para instruções e dados, com o mux `IorD` escolhendo o endereço (PC na busca, ALUOut em LD/ST) | Modelo do livro. Usa um único `.mif` por programa, e o RDM mostrado no display sai dela. |
| Tamanho | 4096 palavras de 16 bits (12 bits de endereço) | Igual ao alcance do campo `end` do JMP. Cabe com folga na memória da DE2-115. *(adaptação)* |
| Endereçamento | Por palavra: o PC avança de 1 em 1 | Cada endereço guarda uma instrução inteira de 16 bits. Por isso não existe o "imediato deslocado" do MIPS. *(adaptação)* |
| LD/ST | Usam os 12 bits baixos de `Rj + imediato` | Consequência do tamanho da memória. |
| Implementação | `altsyncram` de porta única, inicializada pelo `.mif`, saída sem registrador, ligada no **clock invertido** | A leitura da RAM do Quartus é síncrona: o endereço é registrado numa borda de clock. Com o clock invertido, o endereço é registrado na borda de descida, e o dado fica pronto antes da próxima borda de subida. Assim, a unidade de controle não precisa de estados de espera em FETCH e MEM_READ. *(adaptação; o livro não trata disso)* |

## Reset

O reset é assíncrono no PC, no banco de registradores, nos registradores intermediários e na unidade de controle, porque vem de um botão físico que não está sincronizado com o clock manual. Depois do reset, todos os registradores valem 0, a execução começa no endereço 0 e a unidade de controle volta para FETCH.
