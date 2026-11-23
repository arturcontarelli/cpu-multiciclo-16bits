# Registradores

## Banco de registradores

São **8 registradores de 16 bits** (R0 a R7). Os campos Ri, Rj e Rk da instrução têm 3 bits, o que permite exatamente 8 endereços.

| Registrador | Endereço | Tamanho | Observação |
|---|---|---|---|
| R0 | `000` | 16 bits | Vale sempre 0; escritas são ignoradas. |
| R1 | `001` | 16 bits | Uso geral |
| R2 | `010` | 16 bits | Uso geral |
| R3 | `011` | 16 bits | Uso geral |
| R4 | `100` | 16 bits | Uso geral |
| R5 | `101` | 16 bits | Uso geral |
| R6 | `110` | 16 bits | Uso geral |
| R7 | `111` | 16 bits | Uso geral |

**Por que R0 vale sempre 0:** não existe instrução para carregar uma constante num registrador. Constantes são carregadas com `ADDI Ri, R0, imediato`, o que só funciona se R0 for sempre 0. R0 também serve como referência em comparações (`BNE Ri, R0, ...` testa se Ri é diferente de 0) e no fim de programa (`BEQ R0, R0, -1`). Mesma ideia do `$zero` do MIPS.

O banco tem duas portas de leitura, combinacionais, e uma de escrita, na borda de subida com `RegWrite`:

| Porta | Endereço | Motivo |
|---|---|---|
| Leitura A | Sempre **Rj** | Rj é a primeira fonte em todos os formatos que leem registradores. |
| Leitura B | **Rk** no tipo R; **Ri** em ST, BEQ e BNE (mux `RegSrcB`) | Em ST, Ri é o dado a gravar; em BEQ/BNE, Ri é comparado com Rj. O `RegSrcB` é gerado pelo decodificador a partir do opcode, porque A e B já são lidos no DECODE, antes de a unidade de controle saber qual é a instrução. *(adaptação)* |
| Escrita | Sempre **Ri** | No nosso formato o destino nunca muda de campo, por isso não existe o `RegDst` do MIPS. *(adaptação)* |

## Registradores especiais

Além do banco, o caminho de dados tem registradores que o programa não acessa diretamente. Todos têm 16 bits.

| Registrador | Função | Escrita |
|---|---|---|
| PC | Endereço da próxima instrução. | `PCWrite`, ou `PCWriteCond` com a condição de desvio verdadeira. |
| IR | Instrução que está sendo executada. | `IRWrite` (só no FETCH). |
| RDM | Dado lido da memória (o MDR do livro). | Todo ciclo. |
| A | Valor lido de Rj. | Todo ciclo. |
| B | Valor lido de Rk ou de Ri. | Todo ciclo. |
| ALUOut | Resultado da ULA no ciclo anterior. | Todo ciclo. |

Só o PC e o IR precisam de sinal de escrita, porque só eles guardam um valor por vários ciclos. RDM, A, B e ALUOut são sempre lidos no ciclo seguinte ao que foram escritos, então podem ser escritos em todo ciclo, como no livro.
