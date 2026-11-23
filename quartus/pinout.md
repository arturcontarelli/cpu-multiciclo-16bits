# Pinagem da DE2-115

Placa: Terasic DE2-115, FPGA **Cyclone IV E `EP4CE115F29C7`**.

O arquivo [`pinos_de2_115.qsf`](pinos_de2_115.qsf) tem só os pinos que o projeto usa, copiados do `.qsf` oficial da Terasic. Para aplicar no projeto do Quartus: *Assignments → Import Assignments…* e escolha esse arquivo.

## Portas do `cpu_top`

As atribuições de pino só funcionam se as portas do `cpu_top` tiverem **exatamente** estes nomes e larguras:

```vhdl
entity cpu_top is
    port (
        CLOCK_50 : in  std_logic;
        KEY      : in  std_logic_vector(3 downto 0);
        SW       : in  std_logic_vector(17 downto 0);
        LEDG     : out std_logic_vector(8 downto 0);
        HEX0, HEX1, HEX2, HEX3 : out std_logic_vector(6 downto 0);
        HEX4, HEX5, HEX6, HEX7 : out std_logic_vector(6 downto 0)
    );
end entity cpu_top;
```

## O que o projeto usa

| Sinal | Pino | Uso no projeto |
|---|---|---|
| `CLOCK_50` | Y2 | Clock de 50 MHz da placa. Usado **só pelo debouncer**, para amostrar o botão. |
| `KEY[0]` | M23 | **Clock manual da CPU**, depois do debouncer. |
| `KEY[1]` | M21 | Reset. |
| `SW[17]` | Y23 | HEX4–7 mostram o RDM (`0`) ou a saída da ULA (`1`). |
| `LEDG[0..4]` | E21, E22, E25, E24, H21 | `led_state` da FSM: fetch, decode, execute, memory, write-back (ver `docs/especificacao/04-unidade-controle.md`). |
| `HEX0..HEX3` | (ver `.qsf`) | PC em hexadecimal; HEX0 é o dígito menos significativo. |
| `HEX4..HEX7` | (ver `.qsf`) | RDM ou saída da ULA, conforme o SW17. |

`KEY[2..3]`, `SW[0..16]` e `LEDG[5..8]` estão no `.qsf` para que as portas fiquem completas. Os LEDs que sobram devem receber `'0'`: `LEDG <= "0000" & led_state`.

## Detalhes elétricos

- **Botões `KEY` são ativos em 0**: valem `0` quando apertados e `1` quando soltos.
- **Segmentos dos displays são ativos em 0**: `0` acende o segmento. A ordem é `HEXn[0]` = segmento a, …, `HEXn[6]` = segmento g. O `decodificador_7seg.vhd` dos Labs 04/05 do grupo já segue essa convenção e pode ser reaproveitado.
- Todos os pinos usam o padrão `3.3-V LVTTL`, já definido no `.qsf`.

## Clock da CPU

Decisão do grupo, a mesma do Lab05: **o botão `KEY[0]`, filtrado pelo debouncer, é o próprio `clk` da CPU.** Cada aperto é um ciclo.

- O debouncer roda no `CLOCK_50` e entrega o nível estável do botão invertido (`1` = apertado). Esse sinal vai para o `clk` da FSM, do datapath e da memória.
- **Não** use o `CLOCK_50` como clock da CPU com o botão como enable: FSM, datapath e memória não têm entrada de enable.
- A memória já inverte o clock internamente (`src/memory/memory.vhd`), então o topo não faz nada além de ligar o mesmo `clk` nela. Na placa, a memória lê quando o botão é **solto**, e o IR/RDM capturam no aperto **seguinte**.
- O reset das partes 1 a 3 é **assíncrono** e ativo em `1`: ligue nele o `KEY[1]` invertido. Com o clock vindo do botão, um reset síncrono só funcionaria apertando o clock junto.
- O Quartus vai avisar que o clock é gerado por lógica. Nessa velocidade (um ciclo por aperto) isso não causa problema.

O `.qsf` oficial completo (com todos os periféricos da placa) e o manual da DE2-115 vêm no CD/site da Terasic. Não copie as linhas de topo do arquivo oficial (`TOP_LEVEL_ENTITY "DE2_115"`, `SDC_FILE DE2_115.SDC`): o topo deste projeto é o `cpu_top`.
