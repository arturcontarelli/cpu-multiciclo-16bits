# Formato das Instruções

Todas as instruções têm 16 bits, o tamanho de uma palavra, e ocupam um endereço de memória. O opcode está sempre nos 4 bits mais altos.

## Formatos

**Tipo R:** ADD, SUB, AND, OR, SLT

| 15..12 | 11..9 | 8..6 | 5..3 | 2..0 |
|---|---|---|---|---|
| opcode | Ri | Rj | Rk | não usado (`000`) |

**Tipo I:** ADDI, LD, ST, BEQ, BNE

| 15..12 | 11..9 | 8..6 | 5..0 |
|---|---|---|---|
| opcode | Ri | Rj | imediato |

**Tipo J:** JMP

| 15..12 | 11..0 |
|---|---|
| opcode | end |

Os campos ficam sempre na mesma posição: Ri, Rj e Rk são os mesmos bits em todos os formatos que os usam, e o imediato coincide com Rk + os 3 bits não usados. Por isso o decodificador apenas separa os bits do IR, sem depender do formato.

## Opcodes

| Opcode | Instrução | Tipo | Operação |
|---|---|---|---|
| `0000` | ADD Ri, Rj, Rk | R | `Ri ← Rj + Rk` |
| `0001` | SUB Ri, Rj, Rk | R | `Ri ← Rj − Rk` |
| `0010` | AND Ri, Rj, Rk | R | `Ri ← Rj and Rk` (bit a bit) |
| `0011` | OR Ri, Rj, Rk | R | `Ri ← Rj or Rk` (bit a bit) |
| `0100` | SLT Ri, Rj, Rk | R | `Ri ← 1` se `Rj < Rk` (com sinal), senão `Ri ← 0` |
| `0101` | ADDI Ri, Rj, imm | I | `Ri ← Rj + imm` |
| `0110` | LD Ri, Rj, imm | I | `Ri ← M[Rj + imm]` |
| `0111` | ST Ri, Rj, imm | I | `M[Rj + imm] ← Ri` |
| `1000` | BEQ Ri, Rj, imm | I | se `Ri = Rj`: `PC ← PC + 1 + imm` |
| `1001` | BNE Ri, Rj, imm | I | se `Ri ≠ Rj`: `PC ← PC + 1 + imm` |
| `1010` | JMP end | J | `PC ← end` |
| `1011`–`1111` | — | — | livres |

Os opcodes seguem a ordem da tabela do enunciado e estão definidos em `src/common/cpu_pkg.vhd`. Com ADD = `0000` e R0 fixo em 0, uma posição de memória zerada é lida como `ADD R0, R0, R0`, que não faz nada. Assim, se o PC passar do fim do programa, a CPU não executa lixo. *(adaptação)*

## Detalhes de cada campo

- **Imediato:** 6 bits em complemento de 2 (−32 a +31), estendido com sinal para 16 bits antes de ir para a ULA. O enunciado pede um imediato "positivo ou negativo".
- **SLT:** compara com sinal, coerente com o imediato. Exemplo: `−3 < 6` dá 1.
- **LD/ST:** o endereço é `Rj + imm`, e a memória usa só os 12 bits baixos (ver [01](01-descricao-topologia.md)).
- **BEQ/BNE:** o desvio é relativo à **próxima instrução** (PC+1), como no MIPS. No multiciclo o PC já foi incrementado no FETCH; calcular sobre o PC da própria instrução exigiria guardar o PC antigo em mais um registrador. O alcance é de −32 a +31 instruções a partir de PC+1. Ao montar o programa: `imm = alvo − (endereço do desvio + 1)`.
- **JMP:** `end` é um endereço absoluto de 12 bits, sem concatenação com o PC atual, e cobre a memória inteira (4096 palavras).
- **Fim de programa:** `BEQ R0, R0, -1` desvia para si mesmo para sempre. Como não existe instrução de parada, é assim que um programa termina.

## Exemplos de codificação

| Instrução | Campos | Binário | Hex |
|---|---|---|---|
| `ADDI R1, R0, 6` | 0101 · 001 · 000 · 000110 | `0101 0010 0000 0110` | `5206` |
| `ADDI R2, R0, -3` | 0101 · 010 · 000 · 111101 | `0101 0100 0011 1101` | `543D` |
| `ADD R3, R1, R2` | 0000 · 011 · 001 · 010 · 000 | `0000 0110 0101 0000` | `0650` |
| `ST R4, R7, 29` | 0111 · 100 · 111 · 011101 | `0111 1001 1101 1101` | `79DD` |
| `JMP 17` | 1010 · 000000010001 | `1010 0000 0001 0001` | `A011` |
| `BEQ R0, R0, -1` | 1000 · 000 · 000 · 111111 | `1000 0000 0011 1111` | `803F` |
