# Decisões de projeto

Decisões que o enunciado (`docs/descricao-projeto.md`) deixa em aberto e que o grupo fechou. A base é o multiciclo MIPS do Patterson & Hennessy (2ª ed., cap. 5). Quando a decisão não vem do livro, ela está marcada como *(adaptação)*.

Os sinais de controle, os estados da FSM e os LEDs estão detalhados em [`04-unidade-controle.md`](04-unidade-controle.md) e não são repetidos aqui.

## ISA

| Decisão | Valor | Motivo |
|---|---|---|
| Registradores | 8 (R0–R7), 16 bits | Os campos de 3 bits permitem exatamente 8. |
| R0 | Sempre 0 (escrita ignorada) | Não existe instrução para carregar constante; `ADDI Ri, R0, imm` só funciona se R0 for 0. |
| Opcodes | ADD=0000, SUB=0001, AND=0010, OR=0011, SLT=0100, ADDI=0101, LD=0110, ST=0111, BEQ=1000, BNE=1001, JMP=1010 (1011–1111 livres) | Ordem da tabela do enunciado. Memória zerada vira `ADD R0,R0,R0`, que não faz nada. *(adaptação)* Definidos em `src/common/cpu_pkg.vhd`. |
| Imediato | 6 bits com sinal (−32 a +31), estendido para 16 bits | Enunciado: "positivo ou negativo". |
| SLT | Comparação com sinal | Coerente com o imediato com sinal. |

## Memória

| Decisão | Valor | Motivo |
|---|---|---|
| Topologia | Memória única para instruções e dados, mux `IorD` no endereço | Modelo do livro; um `.mif` por programa; o RDM do display sai dela. |
| Tamanho | 4096 palavras de 16 bits (12 bits de endereço) | Igual ao alcance do campo `end` do JMP. Cabe com folga na DE2-115. *(adaptação)* |
| Endereçamento | Por palavra (PC avança de 1 em 1) | Cada endereço guarda uma instrução de 16 bits. Por isso não existe o "imediato deslocado" do MIPS. *(adaptação)* |
| LD/ST | Usam os 12 bits baixos de `Rj + imediato` | Consequência do tamanho da memória. |
| Implementação | `altsyncram` de porta única, inicializada pelo `.mif`, saída sem registrador, ligada no **clock invertido** | A leitura da RAM do Quartus é síncrona. Com o clock invertido, o dado fica pronto antes da próxima borda de subida, e a FSM não precisa de estados de espera. *(adaptação; o livro não trata disso)* |

## Desvios

| Decisão | Valor | Motivo |
|---|---|---|
| BEQ/BNE | `PC <- PC+1+imediato` (relativo à próxima instrução) | O PC já foi incrementado no FETCH; usar o PC da própria instrução exigiria mais um registrador. Ao traduzir o `.asm`: `imm = alvo − (endereço do branch + 1)`. |
| Fim de programa | `BEQ R0, R0, -1` (desvia para si mesmo) | Consequência da regra acima. |
| JMP | `PC <- end` (12 bits, absoluto) | Sem concatenação com o PC atual. |
| Condição de escrita do PC | `PCWrite OR (PCWriteCond AND (Zero XOR BNE))`, calculada no datapath | A FSM fica Moore pura e não recebe `Zero`. O livro só tem BEQ; o bit `BNE` é *(adaptação)*. |

## Datapath

| Decisão | Valor | Motivo |
|---|---|---|
| Registradores intermediários | IR, RDM, A, B, ALUOut | Modelo do livro; o enunciado cita o RDM. Só IR e PC têm enable; os outros são escritos em todo ciclo. |
| Porta A do banco | Sempre Rj | Rj é a primeira fonte em todos os formatos. |
| Porta B do banco | Mux `RegSrcB`: Rk no tipo R; Ri em ST, BEQ e BNE | Gerado pelo **decodificador** a partir do opcode, não pela FSM, porque A e B já são lidos no DECODE. *(adaptação)* |
| Destino da escrita | Sempre Ri (não existe `RegDst`) | No nosso formato o destino nunca muda de campo. *(adaptação)* |
| ULA | Código de 3 bits do lab5: 000 AND, 001 OR, 010 ADD, 100 SUB, 110 SLT | Já testada; a FSM gera esse código direto, sem `alu_control`, porque não há campo funct. |
| Reset | Assíncrono no PC, no banco de registradores e na FSM | Mesmo critério da FSM: o reset vem de um botão físico. |

## LEDs verdes

`led_state` de 5 bits, um LED por etapa (fetch, decode, execute, memory, write-back), conforme `04-unidade-controle.md`.
