# Resultados e Discussão

## O que a placa mostra a cada aperto

Gabarito gerado pela simulação do `cpu_top` (`tb_cpu_top`) com o programa `programa_completo.mif`. Na placa, os valores devem ser os mesmos (roteiro em [06](06-testes.md#teste-na-placa)).

Coluna "Apertos": quantas vezes o KEY0 foi apertado depois do reset. A instrução aparece na linha do FETCH em que ela é buscada.

| Apertos | Estado (LEDG) | PC (HEX3–0) | RDM (SW17=0) | ULA (SW17=1) | Instrução |
|---|---|---|---|---|---|
| 0 | fetch | `0000` | `0000` | `0001` | ADDI R1, R0, 6 |
| 1 | decode | `0001` | `5206` | `0007` |  |
| 2 | execute | `0001` | `543D` | `0006` |  |
| 3 | write-back | `0001` | `543D` | `0001` |  |
| 4 | fetch | `0001` | `543D` | `0002` | ADDI R2, R0, -3 |
| 5 | decode | `0002` | `543D` | `FFFF` |  |
| 6 | execute | `0002` | `0650` | `FFFD` |  |
| 7 | write-back | `0002` | `0650` | `0002` |  |
| 8 | fetch | `0002` | `0650` | `0003` | ADD R3, R1, R2 |
| 9 | decode | `0003` | `0650` | `0013` |  |
| 10 | execute | `0003` | `1850` | `0003` |  |
| 11 | write-back | `0003` | `1850` | `0000` |  |
| 12 | fetch | `0003` | `1850` | `0004` | SUB R4, R1, R2 |
| 13 | decode | `0004` | `1850` | `0014` |  |
| 14 | execute | `0004` | `2A58` | `0009` |  |
| 15 | write-back | `0004` | `2A58` | `0001` |  |
| 16 | fetch | `0004` | `2A58` | `0005` | AND R5, R1, R3 |
| 17 | decode | `0005` | `2A58` | `001D` |  |
| 18 | execute | `0005` | `3C60` | `0002` |  |
| 19 | write-back | `0005` | `3C60` | `0008` |  |
| 20 | fetch | `0005` | `3C60` | `0006` | OR R6, R1, R4 |
| 21 | decode | `0006` | `3C60` | `FFE6` |  |
| 22 | execute | `0006` | `4E88` | `000F` |  |
| 23 | write-back | `0006` | `4E88` | `000F` |  |
| 24 | fetch | `0006` | `4E88` | `0007` | SLT R7, R2, R1 |
| 25 | decode | `0007` | `4E88` | `000F` |  |
| 26 | execute | `0007` | `79DD` | `0001` |  |
| 27 | write-back | `0007` | `79DD` | `000D` |  |
| 28 | fetch | `0007` | `79DD` | `0008` | ST R4, R7, 29 |
| 29 | decode | `0008` | `79DD` | `0025` |  |
| 30 | execute | `0008` | `6E1E` | `001E` |  |
| 31 | memory | `0008` | `6E1E` | `0011` |  |
| 32 | fetch | `0008` | `0009` | `0009` | LD R7, R0, 30 |
| 33 | decode | `0009` | `6E1E` | `0027` |  |
| 34 | execute | `0009` | `8F01` | `001E` |  |
| 35 | memory | `0009` | `8F01` | `000C` |  |
| 36 | write-back | `0009` | `0009` | `000C` |  |
| 37 | fetch | `0009` | `8F01` | `000A` | BEQ R7, R4, depois |
| 38 | decode | `000A` | `8F01` | `000B` |  |
| 39 | execute | `000A` | `521F` | `0000` |  |
| 40 | fetch | `000B` | `521F` | `000C` | BNE R7, R4, laco |
| 41 | decode | `000C` | `9F01` | `000D` |  |
| 42 | execute | `000C` | `5B41` | `0000` |  |
| 43 | fetch | `000C` | `5B41` | `000D` | ADDI R5, R5, 1 |
| 44 | decode | `000D` | `5B41` | `000E` |  |
| 45 | execute | `000D` | `5481` | `0003` |  |
| 46 | write-back | `000D` | `5481` | `000D` |  |
| 47 | fetch | `000D` | `5481` | `000E` | ADDI R2, R2, 1 |
| 48 | decode | `000E` | `5481` | `000F` |  |
| 49 | execute | `000E` | `943E` | `FFFE` |  |
| 50 | write-back | `000E` | `943E` | `000E` |  |
| 51 | fetch | `000E` | `943E` | `000F` | BNE R2, R0, laco |
| 52 | decode | `000F` | `943E` | `000D` |  |
| 53 | execute | `000F` | `A011` | `0002` |  |
| 54 | fetch | `000D` | `A011` | `000E` | ADDI R2, R2, 1 |
| 55 | decode | `000E` | `5481` | `000F` |  |
| 56 | execute | `000E` | `943E` | `FFFF` |  |
| 57 | write-back | `000E` | `943E` | `000E` |  |
| 58 | fetch | `000E` | `943E` | `000F` | BNE R2, R0, laco |
| 59 | decode | `000F` | `943E` | `000D` |  |
| 60 | execute | `000F` | `A011` | `0001` |  |
| 61 | fetch | `000D` | `A011` | `000E` | ADDI R2, R2, 1 |
| 62 | decode | `000E` | `5481` | `000F` |  |
| 63 | execute | `000E` | `943E` | `0000` |  |
| 64 | write-back | `000E` | `943E` | `000E` |  |
| 65 | fetch | `000E` | `943E` | `000F` | BNE R2, R0, laco |
| 66 | decode | `000F` | `943E` | `000D` |  |
| 67 | execute | `000F` | `A011` | `0000` |  |
| 68 | fetch | `000F` | `A011` | `0010` | JMP pula |
| 69 | decode | `0010` | `A011` | `0021` |  |
| 70 | execute | `0010` | `521E` | `0010` |  |
| 71 | fetch | `0011` | `521E` | `0012` | ADDI R0, R0, 9 |
| 72 | decode | `0012` | `5009` | `001B` |  |
| 73 | execute | `0012` | `803F` | `0009` |  |
| 74 | write-back | `0012` | `803F` | `0018` |  |
| 75 | fetch | `0012` | `803F` | `0013` | BEQ R0, R0, fim |
| 76 | decode | `0013` | `803F` | `0012` |  |
| 77 | execute | `0013` | `0000` | `0000` |  |
| 78 | fetch | `0012` | `0000` | `0013` | BEQ R0, R0, fim |
| 79 | decode | `0013` | `803F` | `0012` |  |
| 80 | execute | `0013` | `0000` | `0000` |  |
| 81 | fetch | `0012` | `0000` | `0013` | BEQ R0, R0, fim |
| 82 | decode | `0013` | `803F` | `0012` |  |
| 83 | execute | `0013` | `0000` | `0000` |  |
| 84 | fetch | `0012` | `0000` | `0013` | BEQ R0, R0, fim |

## Discussão

- **Por que a ULA mostra valores "estranhos" em alguns estados?** Nos estados em que a ULA não é usada (memory, write-back, jump), os seletores ficam no valor padrão da FSM e a ULA calcula algo que ninguém usa. Os valores que importam são os de FETCH, DECODE e execute.
- **O alvo do desvio aparece em todo DECODE.** Por exemplo, no aperto 1 a ULA mostra `0007` (PC + 1 + 6): o DECODE calcula o alvo de desvio para qualquer instrução, porque ainda não sabe se ela é um BEQ/BNE. Só os desvios usam esse valor.
- **O RDM muda em todo ciclo.** Ele é escrito em todo ciclo, então mostra a última palavra lida: a instrução depois de um FETCH e o dado só no ciclo seguinte ao MEM_READ (aperto 36, `0009`).
