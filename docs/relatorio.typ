// =============================================================================
// Relatório do projeto — CPU multiciclo 16 bits
// Template normalizado conforme ABNT NBR 14724 (apresentação), NBR 6024
// (numeração de seções), NBR 6027 (sumário) e NBR 6023 (referências).
//
// Como usar:
//   1. Os dados em "DADOS DO TRABALHO" já estão preenchidos — revise antes
//      da entrega (nomes, professor, etc.).
//   2. O conteúdo das seções 1 a 8 já foi migrado de docs/especificacao/.
//      Os blocos #todo[...] marcam o que falta: figuras a exportar, a seção
//      de uso de IA (ainda não escrita por ninguém) e o resumo.
//   3. Compile com:  typst compile docs/relatorio.typ docs/relatorio.pdf
//
// Nenhuma seção deve ficar como #todo[...] na versão final entregue.
// =============================================================================

// ----------------------------------------------------------------------------
// DADOS DO TRABALHO — edite aqui, o resto do documento usa estas variáveis
// ----------------------------------------------------------------------------
#let instituicao = "PUC Campinas"
#let curso = "Engenharia de Computação"
#let disciplina = "Arquitetura de Sistemas Computacionais"
#let professor = "Leonardo Rezende Costa"
#let cidade = "Campinas"
#let ano = "2026"
#let titulo = "Projeto de uma CPU Multiciclo de 16 bits em VHDL"

#let integrantes = (
  "Artur Contarelli",
  "Guilherme Fusco",
  "João Minelli",
  "Ramon Batista",
  "Tiago Rodrigues",
)

// ----------------------------------------------------------------------------
// Marcação de pendência — remova todo #todo[...] antes da entrega final
// ----------------------------------------------------------------------------
#let todo(body) = text(fill: rgb("#a30000"), style: "italic", size: 10pt)[
  [PENDENTE: #body]
]

#let fonte(body) = align(center, text(size: 10pt)[Fonte: #body])

// ----------------------------------------------------------------------------
// Regras ABNT — página, fonte, parágrafo
// ----------------------------------------------------------------------------
#set document(title: titulo, author: integrantes)

#set page(
  paper: "a4",
  margin: (top: 3cm, left: 3cm, right: 2cm, bottom: 2cm),
  numbering: none,
  number-align: top + right,
)

#set text(font: "Times New Roman", size: 12pt, lang: "pt", region: "BR")

#set par(
  justify: true,
  first-line-indent: 1.25cm,
  leading: 1em,
  spacing: 1em,
)

// Blocos de código (trechos de VHDL / assembly / .mif) — monoespaçado, sem
// recuo de parágrafo, levemente destacado do corpo do texto.
#show raw.where(block: true): it => {
  set par(first-line-indent: 0cm, justify: false, leading: 0.65em)
  set text(font: "Consolas", size: 10pt)
  block(fill: luma(245), inset: 8pt, radius: 2pt, width: 100%, it)
}
#show raw.where(block: false): set text(font: "Consolas", size: 10pt)

// Legendas: tabela acima, figura abaixo (NBR 14724); fonte sempre abaixo.
#show figure.where(kind: table): set figure.caption(position: top)
#show figure.caption: set text(size: 10pt)
#show figure: set align(center)
// Tabelas mais longas que uma página (ex.: o gabarito de simulação) têm que
// poder continuar na página seguinte, em vez de serem espremidas numa só.
#show figure: set block(breakable: true)

// Tabelas estilo ABNT: sem linhas verticais e sem linhas entre as linhas de
// dados — só uma linha no topo, uma sob o cabeçalho e uma no final (as três
// inseridas manualmente em cada tabela com #table.hline()).
#set table(stroke: none, inset: 6pt)
#set table.hline(stroke: 0.6pt)

// ----------------------------------------------------------------------------
// Seções numeradas (NBR 6024) — só valem a partir da parte textual
// ----------------------------------------------------------------------------
#set heading(numbering: "1.1.1")

#show heading.where(level: 1): it => {
  v(1.2em, weak: true)
  block(width: 100%, above: 0em, below: 0.8em)[
    #set text(weight: "bold", size: 12pt)
    #upper(it)
  ]
}
#show heading.where(level: 2): it => {
  v(1em, weak: true)
  block(width: 100%, above: 0em, below: 0.6em)[
    #set text(weight: "bold", size: 12pt)
    #it
  ]
}
#show heading.where(level: 3): it => {
  v(0.8em, weak: true)
  block(width: 100%, above: 0em, below: 0.5em)[
    #set text(weight: "regular", style: "italic", size: 12pt)
    #it
  ]
}

// =============================================================================
// ELEMENTOS PRÉ-TEXTUAIS (sem numeração de seção, sem número de página)
// =============================================================================

// ----- Capa -------------------------------------------------------------
#align(center)[
  #upper(instituicao)

  #v(2cm)

  #image("PUC.png")

  #v(1fr)

  #text(size: 14pt, weight: "bold")[#upper(titulo)]

  #v(1fr)

  #cidade \
  #ano
]

// ----- Folha de rosto -----------------------------------------------------
#pagebreak()
#align(center)[
  #upper(instituicao)

  #v(2cm)

  #for nome in integrantes [#nome \ ]
]

#v(1fr)

#align(center)[
  #text(size: 14pt, weight: "bold")[#upper(titulo)]
]

#v(1fr)

#align(right)[
  #block(width: 8cm)[
    #set par(first-line-indent: 0cm)
    Relatório apresentado à disciplina de #disciplina,

    Professor(a): #professor
  ]
]

#v(1fr)

#align(center)[
  #cidade \
  #ano
]

// ----- Resumo ---------------------------------------------------------
#pagebreak()
#align(center, text(weight: "bold")[RESUMO])
#v(1em)

#set par(first-line-indent: 0cm)
Este trabalho apresenta o projeto, a implementação e a validação de uma CPU
multiciclo de 16 bits em VHDL, desenvolvida para a disciplina de Arquitetura
de Sistemas Computacionais e sintetizada na placa DE2-115. A arquitetura
segue o modelo multiciclo de Patterson e Hennessy, adaptado ao conjunto de
onze instruções do enunciado (ADD, SUB, AND, OR, SLT, ADDI, LD, ST, BEQ, BNE
e JMP), distribuídas nos formatos R, I e J de 16 bits. O projeto foi dividido
em cinco frentes — unidade de controle, caminho de dados, memória e
decodificação de instruções, integração com a FPGA e testes/documentação —,
integradas somente na entidade de topo `cpu_top`, de modo que cada módulo
pudesse ser testado isoladamente. A unidade de controle é uma máquina de
estados de dez estados, puramente Moore, que gera os sinais do caminho de
dados e expõe o estágio atual (fetch, decode, execute, memory, write-back)
nos LEDs verdes da placa. O caminho de dados reaproveita uma única ULA e uma
única memória ao longo dos ciclos de cada instrução, usando registradores
intermediários (IR, RDM, A, B, ALUOut). A validação combinou testbenches
unitários por módulo, dois níveis de testbench de integração (caminho de
dados com FSM, e CPU completa) e um testbench do `cpu_top` simulando a
interação física com botões, chaves, displays e LEDs da DE2-115, incluindo
quique no botão de clock e reset no meio da execução. Um programa de teste
único, que exercita as onze instruções, produziu resultados idênticos em
simulação e na placa, confirmando a corretude da implementação.
#set par(first-line-indent: 1.25cm)

#v(1em)
*Palavras-chave*: CPU multiciclo; VHDL; FPGA; Arquitetura de computadores.

// ----- Sumário ----------------------------------------------------------
#pagebreak()
#align(center, text(weight: "bold")[SUMÁRIO])
#v(1em)
#outline(title: none, indent: auto)

// =============================================================================
// ELEMENTOS TEXTUAIS — a partir daqui a numeração de página é exibida
// =============================================================================
#pagebreak()
#set page(numbering: "1")

= Introdução e descrição da topologia

== O projeto

CPU multiciclo de 16 bits em VHDL, sintetizada no Quartus e gravada na FPGA
da placa DE2-115. Ela executa as onze instruções do enunciado: ADD, SUB,
AND, OR, SLT, ADDI, LD, ST, BEQ, BNE e JMP. O clock é manual, gerado por um
botão com debouncer. Os displays e os LEDs da placa mostram o PC, o dado
lido da memória ou a saída da ULA, e o estado da unidade de controle.

A base é o processador multiciclo MIPS de Patterson e Hennessy
(_Computer Organization and Design_, 2. ed., cap. 5). O enunciado deixa
várias decisões em aberto; onde o grupo não seguiu o livro, isso é indicado
como _(adaptação)_ ao longo do texto.

== Por que multiciclo

Cada instrução é dividida em etapas de um ciclo: busca, decodificação,
execução, acesso à memória e escrita no registrador. Uma instrução usa só
as etapas de que precisa, por isso leva de 3 a 5 ciclos. Entre um ciclo e o
próximo, os resultados ficam em registradores intermediários (IR, RDM, A, B
e ALUOut). Com isso, a mesma ULA e a mesma memória são reaproveitadas em
ciclos diferentes da mesma instrução.

#figure(
  table(
    columns: 3,
    table.hline(),
    table.header[*Instruções*][*Ciclos*][*Estados percorridos*],
    table.hline(),
    [ADD, SUB, AND, OR, SLT], [4], [FETCH → DECODE → EXEC\_R → WB\_ALU],
    [ADDI], [4], [FETCH → DECODE → ADDR\_CALC → WB\_ALU],
    [LD], [5], [FETCH → DECODE → ADDR\_CALC → MEM\_READ → WB\_MEM],
    [ST], [4], [FETCH → DECODE → ADDR\_CALC → MEM\_WRITE],
    [BEQ, BNE], [3], [FETCH → DECODE → BRANCH],
    [JMP], [3], [FETCH → DECODE → JUMP],
    table.hline(),
  ),
  caption: [Ciclos por instrução],
)

== Topologia

A CPU tem quatro blocos, ligados somente na entidade de topo
(`src/top/cpu_top.vhd`):

#figure(
  table(
    columns: 3,
    table.hline(),
    table.header[*Bloco*][*Pasta*][*Função*],
    table.hline(),
    [Unidade de controle], [`src/control/`], [Máquina de estados de 10 estados. Recebe o opcode e gera os sinais de controle e o estado para os LEDs.],
    [Caminho de dados], [`src/datapath/`], [PC, banco de registradores, ULA, registradores intermediários e muxes. Executa o que a unidade de controle manda.],
    [Memória e decodificador], [`src/memory/`, `src/common/`], [Memória única de instruções e dados. O decodificador separa os campos da instrução guardada no IR.],
    [Periféricos da placa], [`src/io/`], [Debouncer do botão de clock e displays de 7 segmentos.],
    table.hline(),
  ),
  caption: [Blocos da topologia],
)

Os blocos não se conhecem: cada um só vê as próprias portas. Opcodes e
tipos ficam num pacote único (`src/common/cpu_pkg.vhd`), usado por todos.

#todo[
  Inserir aqui o diagrama de blocos da topologia (exportar o diagrama mermaid
  de `docs/especificacao/01-descricao-topologia.md` como PNG/SVG, salvar em
  `docs/figuras/` e substituir este bloco por
  `#figure(image("figuras/topologia.png"), caption: [...])`).
]

== Memória

#figure(
  table(
    columns: 3,
    table.hline(),
    table.header[*Decisão*][*Valor*][*Motivo*],
    table.hline(),
    [Topologia], [Memória única para instruções e dados, com o mux `IorD` escolhendo o endereço (PC na busca, ALUOut em LD/ST)], [Modelo do livro. Usa um único `.mif` por programa, e o RDM mostrado no display sai dela.],
    [Tamanho], [4096 palavras de 16 bits (12 bits de endereço)], [Igual ao alcance do campo `end` do JMP. Cabe com folga na memória da DE2-115. _(adaptação)_],
    [Endereçamento], [Por palavra: o PC avança de 1 em 1], [Cada endereço guarda uma instrução inteira de 16 bits. Por isso não existe o "imediato deslocado" do MIPS. _(adaptação)_],
    [LD/ST], [Usam os 12 bits baixos de `Rj + imediato`], [Consequência do tamanho da memória.],
    [Implementação], [`altsyncram` de porta única, inicializada pelo `.mif`, saída sem registrador, ligada no clock invertido], [A leitura da RAM do Quartus é síncrona: o endereço é registrado numa borda de clock. Com o clock invertido, o endereço é registrado na borda de descida, e o dado fica pronto antes da próxima borda de subida. Assim, a unidade de controle não precisa de estados de espera em FETCH e MEM\_READ. _(adaptação; o livro não trata disso)_],
    table.hline(),
  ),
  caption: [Decisões de projeto da memória],
)

== Reset

O reset é assíncrono no PC, no banco de registradores, nos registradores
intermediários e na unidade de controle, porque vem de um botão físico que
não está sincronizado com o clock manual. Depois do reset, todos os
registradores valem 0, a execução começa no endereço 0 e a unidade de
controle volta para FETCH.

== Integração na placa (DE2-115)

O `cpu_top` liga a CPU aos botões, chaves, displays e LEDs da DE2-115,
atendendo os requisitos de teste do enunciado:

#figure(
  table(
    columns: 3,
    table.hline(),
    table.header[*Requisito do enunciado*][*Como foi atendido*][*Onde*],
    table.hline(),
    [Um botão controla o clock, com debouncer], [`KEY[0]` → `debouncer` → `clk` da CPU. Cada aperto é um ciclo.], [`src/io/debouncer.vhd`, `src/io/clock_reset.vhd`],
    [HEX0–HEX3 mostram o PC], [4 instâncias de `hex_display` ligadas a `pc_out`], [`src/top/cpu_top.vhd`],
    [HEX4–HEX7 mostram o RDM ou a saída da ULA, escolhidos pelo SW17], [`hex_mux` (`SW17 = 0` → RDM, `1` → ULA) + 4 `hex_display`], [`src/io/hex_mux.vhd`],
    [LEDs verdes indicam o estado da unidade de controle], [`LEDG[4:0] = led_state` (one-hot: fetch, decode, execute, memory, write-back)], [`src/top/cpu_top.vhd`],
    [Memória inicializada por `.mif`], [generic `MIF_FILE` do `cpu_top`, repassado à `memory`], [`quartus/criar_projeto.tcl`],
    table.hline(),
  ),
  caption: [Requisitos de integração com a FPGA],
)

Além disso, `KEY[1]` é o reset e `LEDG[8]` acende enquanto o botão de clock
está apertado, o que mostra que o debouncer reagiu.

O `cpu_top` é o único arquivo que conhece todos os blocos e não tem lógica
própria: só instancia os módulos e liga as portas. Toda a lógica de placa
(inverter botões, filtrar quique, decodificar segmentos, escolher o que vai
no display) fica em `src/io/`.

#todo[
  Inserir aqui o diagrama de fiação da integração FPGA (exportar o segundo
  diagrama mermaid de `docs/especificacao/01-descricao-topologia.md`).
]

A fiação do núcleo (FSM + decodificador + datapath + memória) é a mesma do
`sim/testbenches/tb_cpu.vhd`. A integração com a placa acrescenta só os
periféricos de E/S.

=== Clock da CPU

O botão é o próprio clock da CPU: cada aperto é um ciclo. A alternativa
seria rodar a CPU no `CLOCK_50` e usar o botão como enable, o que é mais
"correto" em projeto síncrono, mas FSM, datapath e memória teriam de ganhar
uma entrada de enable. Com um ciclo por aperto, o aviso do Quartus de clock
gerado por lógica não causa problema.

=== Módulos de E/S (`src/io/`)

*`debouncer.vhd`: o botão vira um clock limpo.* Um botão mecânico quica: ao
ser apertado ou solto, o contato abre e fecha várias vezes durante alguns
milissegundos. Como o `KEY[0]` é o próprio clock da CPU, sem filtro cada
quique viraria uma borda de subida, e um aperto executaria vários ciclos. O
debouncer roda no `CLOCK_50` (50 MHz) e tem três partes:

+ *Sincronizador de 2 flip-flops.* O botão muda a qualquer momento, sem
  relação com o `CLOCK_50`. Se ele mudar bem na borda, o primeiro FF pode
  ficar metaestável. O segundo FF dá um ciclo inteiro para o valor se
  estabilizar antes de ser usado.
+ *Contador.* Enquanto a entrada sincronizada for igual ao nível estável, o
  contador fica em 0. Quando ela muda, o contador começa a contar; se o
  botão voltar antes do fim (quique), o contador zera. Só depois de
  `CONTAGEM` = 1 000 000 ciclos seguidos (20 ms a 50 MHz) o novo nível é
  aceito.
+ *Inversão.* Os `KEY` da DE2-115 são ativos em 0. A saída do debouncer é
  ativa em 1 (`1` = apertado), pronta para ser clock e reset.

A saída vem de um registrador, então não tem glitch: é seguro usá-la como
clock. `CONTAGEM` é um generic para o testbench poder usar um valor pequeno.

*`clock_reset.vhd`: clock e reset da CPU.* Junta dois debouncers (`KEY[0]`
e `KEY[1]`) e entrega `cpu_clk` e `cpu_reset`:

```vhdl
cpu_clk   <= clk_db or reset_db;
cpu_reset <= reset_db;
```

O `or` faz o reset também gerar um pulso de clock. A memória registra o
endereço na descida do clock (clock invertido); o reset, sendo assíncrono,
zera o PC mas não gera borda nenhuma. Com o `or`, apertar `KEY[1]` sobe o
clock, sem efeito porque tudo está em reset; soltar `KEY[1]` desce o clock
junto com o fim do reset, com o PC já em 0, e a memória registra o endereço
0. O problema que isso resolve está detalhado na seção de dificuldades
encontradas.

*`hex_display.vhd`: 4 bits → 7 segmentos.* Tabela de 16 linhas
(`with ... select`), uma por dígito de 0 a F. Os segmentos da DE2-115 são
ativos em 0 (`0` acende), na ordem `segmentos(0)` = a … `segmentos(6)` = g.
As letras b e d saem minúsculas para não serem confundidas com 8 e 0. O
mesmo componente é instanciado 8 vezes, uma por display.

*`hex_mux.vhd`: RDM ou ULA nos HEX4–HEX7.* Mux 2:1 de 16 bits: `SW17 = 0`
mostra o RDM (dado lido da memória) e `SW17 = 1` mostra a saída da ULA, na
ordem em que o enunciado os cita. A saída da ULA é combinacional, então
mostra o que a ULA está calculando no estado atual (por exemplo, `PC + 1`
no FETCH). O RDM mostra o que foi lido da memória na borda anterior.

*`cpu_top.vhd`: a composição.* As portas têm exatamente os nomes e
larguras do `quartus/pinos_de2_115.qsf`, porque o Quartus associa os pinos
às portas pelo nome. Tem dois generics: `MIF_FILE` (programa carregado na
memória) e `DEBOUNCE_CONTAGEM` (20 ms na placa, poucos ciclos na
simulação). O PC e o dado do display são divididos em fatias de 4 bits
(`pc_out(3 downto 0)` vai no HEX0, …, `pc_out(15 downto 12)` no HEX3), e
`LEDG <= cpu_clk & "000" & led_state` (LEDG4–0 = estado, LEDG7–5 apagados,
LEDG8 = clock).

=== Temporização de um aperto

```
              aperta KEY0          solta KEY0            aperta KEY0
cpu_clk  ______/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\____________________/‾‾‾‾‾‾
               ↑                    ↓                    ↑
               borda de subida:     borda de descida:    borda de subida:
               FSM muda de estado;  memória registra o   IR/RDM capturam o
               PC, IR, A, B,        endereço (PC ou      dado lido
               ALUOut, RDM e banco  ALUOut) e começa
               são escritos         a ler
```

Por isso, olhando a placa: a cada aperto o LED de estado avança, e o PC
muda no aperto que sai do FETCH. O valor da memória que aparece no RDM é o
do endereço que estava montado quando o botão foi solto.

=== Pinagem

Detalhada em `quartus/pinout.md` e desenhada no mapa a seguir. Como
compilar e gravar: `quartus/README.md`.

#figure(
  table(
    columns: 3,
    table.hline(),
    table.header[*Sinal*][*Pino*][*Uso*],
    table.hline(),
    [`CLOCK_50`], [Y2], [só para os debouncers],
    [`KEY[0]`], [M23], [clock manual da CPU],
    [`KEY[1]`], [M21], [reset],
    [`SW[17]`], [Y23], [HEX7–4: 0 = RDM, 1 = ULA],
    [`LEDG[0..4]`], [E21, E22, E25, E24, H21], [fetch, decode, execute, memory, write-back],
    [`LEDG[8]`], [F17], [clock da CPU (aceso com o botão apertado)],
    [`HEX0..HEX3`], [ver `.qsf`], [PC],
    [`HEX4..HEX7`], [ver `.qsf`], [RDM ou ULA],
    table.hline(),
  ),
  caption: [Pinagem usada na DE2-115],
)

#figure(
  image("figuras/mapa_placa.svg", width: 90%),
  caption: [Mapa de pinagem da placa DE2-115],
)
#fonte[Os autores, com base em `quartus/pinout.md`.]

= Registradores

== Banco de registradores

São 8 registradores de 16 bits (R0 a R7). Os campos Ri, Rj e Rk da
instrução têm 3 bits, o que permite exatamente 8 endereços.

#figure(
  table(
    columns: 4,
    table.hline(),
    table.header[*Registrador*][*Endereço*][*Tamanho*][*Observação*],
    table.hline(),
    [R0], [`000`], [16 bits], [Vale sempre 0; escritas são ignoradas.],
    [R1], [`001`], [16 bits], [Uso geral],
    [R2], [`010`], [16 bits], [Uso geral],
    [R3], [`011`], [16 bits], [Uso geral],
    [R4], [`100`], [16 bits], [Uso geral],
    [R5], [`101`], [16 bits], [Uso geral],
    [R6], [`110`], [16 bits], [Uso geral],
    [R7], [`111`], [16 bits], [Uso geral],
    table.hline(),
  ),
  caption: [Banco de registradores],
)

*Por que R0 vale sempre 0:* não existe instrução para carregar uma
constante num registrador. Constantes são carregadas com
`ADDI Ri, R0, imediato`, o que só funciona se R0 for sempre 0. R0 também
serve como referência em comparações (`BNE Ri, R0, ...` testa se Ri é
diferente de 0) e no fim de programa (`BEQ R0, R0, -1`). Mesma ideia do
`\$zero` do MIPS.

O banco tem duas portas de leitura, combinacionais, e uma de escrita, na
borda de subida com `RegWrite`:

#figure(
  table(
    columns: 3,
    table.hline(),
    table.header[*Porta*][*Endereço*][*Motivo*],
    table.hline(),
    [Leitura A], [Sempre Rj], [Rj é a primeira fonte em todos os formatos que leem registradores.],
    [Leitura B], [Rk no tipo R; Ri em ST, BEQ e BNE (mux `RegSrcB`)], [Em ST, Ri é o dado a gravar; em BEQ/BNE, Ri é comparado com Rj. O `RegSrcB` é gerado pelo decodificador a partir do opcode, porque A e B já são lidos no DECODE, antes de a unidade de controle saber qual é a instrução. _(adaptação)_],
    [Escrita], [Sempre Ri], [No formato usado o destino nunca muda de campo, por isso não existe o `RegDst` do MIPS. _(adaptação)_],
    table.hline(),
  ),
  caption: [Portas de acesso ao banco de registradores],
)

== Registradores especiais

Além do banco, o caminho de dados tem registradores que o programa não
acessa diretamente. Todos têm 16 bits.

#figure(
  table(
    columns: 3,
    table.hline(),
    table.header[*Registrador*][*Função*][*Escrita*],
    table.hline(),
    [PC], [Endereço da próxima instrução.], [`PCWrite`, ou `PCWriteCond` com a condição de desvio verdadeira.],
    [IR], [Instrução que está sendo executada.], [`IRWrite` (só no FETCH).],
    [RDM], [Dado lido da memória (o MDR do livro).], [Todo ciclo.],
    [A], [Valor lido de Rj.], [Todo ciclo.],
    [B], [Valor lido de Rk ou de Ri.], [Todo ciclo.],
    [ALUOut], [Resultado da ULA no ciclo anterior.], [Todo ciclo.],
    table.hline(),
  ),
  caption: [Registradores especiais do caminho de dados],
)

Só o PC e o IR precisam de sinal de escrita, porque só eles guardam um
valor por vários ciclos. RDM, A, B e ALUOut são sempre lidos no ciclo
seguinte ao que foram escritos, então podem ser escritos em todo ciclo,
como no livro.

= Formato das instruções

Todas as instruções têm 16 bits, o tamanho de uma palavra, e ocupam um
endereço de memória. O opcode está sempre nos 4 bits mais altos.

== Formatos

```
Tipo R (ADD, SUB, AND, OR, SLT):
 15..12   11..9   8..6    5..3    2..0
| opcode |  Ri  |  Rj  |  Rk  | não usado (000) |

Tipo I (ADDI, LD, ST, BEQ, BNE):
 15..12   11..9   8..6    5..0
| opcode |  Ri  |  Rj  |   imediato   |

Tipo J (JMP):
 15..12     11..0
| opcode |    end     |
```

Os campos ficam sempre na mesma posição: Ri, Rj e Rk são os mesmos bits em
todos os formatos que os usam, e o imediato coincide com Rk mais os 3 bits
não usados. Por isso o decodificador apenas separa os bits do IR, sem
depender do formato.

== Opcodes

#figure(
  table(
    columns: 4,
    table.hline(),
    table.header[*Opcode*][*Instrução*][*Tipo*][*Operação*],
    table.hline(),
    [`0000`], [ADD Ri, Rj, Rk], [R], [`Ri ← Rj + Rk`],
    [`0001`], [SUB Ri, Rj, Rk], [R], [`Ri ← Rj − Rk`],
    [`0010`], [AND Ri, Rj, Rk], [R], [`Ri ← Rj and Rk` (bit a bit)],
    [`0011`], [OR Ri, Rj, Rk], [R], [`Ri ← Rj or Rk` (bit a bit)],
    [`0100`], [SLT Ri, Rj, Rk], [R], [`Ri ← 1` se `Rj < Rk` (com sinal), senão `Ri ← 0`],
    [`0101`], [ADDI Ri, Rj, imm], [I], [`Ri ← Rj + imm`],
    [`0110`], [LD Ri, Rj, imm], [I], [`Ri ← M[Rj + imm]`],
    [`0111`], [ST Ri, Rj, imm], [I], [`M[Rj + imm] ← Ri`],
    [`1000`], [BEQ Ri, Rj, imm], [I], [se `Ri = Rj`: `PC ← PC + 1 + imm`],
    [`1001`], [BNE Ri, Rj, imm], [I], [se `Ri ≠ Rj`: `PC ← PC + 1 + imm`],
    [`1010`], [JMP end], [J], [`PC ← end`],
    [`1011`–`1111`], [—], [—], [livres],
    table.hline(),
  ),
  caption: [Tabela de opcodes],
)

Os opcodes seguem a ordem da tabela do enunciado e estão definidos em
`src/common/cpu_pkg.vhd`. Com ADD = `0000` e R0 fixo em 0, uma posição de
memória zerada é lida como `ADD R0, R0, R0`, que não faz nada. Assim, se o
PC passar do fim do programa, a CPU não executa lixo. _(adaptação)_

== Detalhes de cada campo

- *Imediato:* 6 bits em complemento de 2 (−32 a +31), estendido com sinal
  para 16 bits antes de ir para a ULA.
- *SLT:* compara com sinal, coerente com o imediato. Exemplo: `−3 < 6` dá 1.
- *LD/ST:* o endereço é `Rj + imm`, e a memória usa só os 12 bits baixos.
- *BEQ/BNE:* o desvio é relativo à próxima instrução (PC+1), como no MIPS.
  No multiciclo o PC já foi incrementado no FETCH; calcular sobre o PC da
  própria instrução exigiria guardar o PC antigo em mais um registrador. O
  alcance é de −32 a +31 instruções a partir de PC+1. Ao montar o
  programa: `imm = alvo − (endereço do desvio + 1)`.
- *JMP:* `end` é um endereço absoluto de 12 bits, sem concatenação com o
  PC atual, e cobre a memória inteira (4096 palavras).
- *Fim de programa:* `BEQ R0, R0, -1` desvia para si mesmo para sempre.
  Como não existe instrução de parada, é assim que um programa termina.

== Exemplos de codificação

#figure(
  table(
    columns: 4,
    table.hline(),
    table.header[*Instrução*][*Campos*][*Binário*][*Hex*],
    table.hline(),
    [`ADDI R1, R0, 6`], [0101 · 001 · 000 · 000110], [`0101 0010 0000 0110`], [`5206`],
    [`ADDI R2, R0, -3`], [0101 · 010 · 000 · 111101], [`0101 0100 0011 1101`], [`543D`],
    [`ADD R3, R1, R2`], [0000 · 011 · 001 · 010 · 000], [`0000 0110 0101 0000`], [`0650`],
    [`ST R4, R7, 29`], [0111 · 100 · 111 · 011101], [`0111 1001 1101 1101`], [`79DD`],
    [`JMP 17`], [1010 · 000000010001], [`1010 0000 0001 0001`], [`A011`],
    [`BEQ R0, R0, -1`], [1000 · 000 · 000 · 111111], [`1000 0000 0011 1111`], [`803F`],
    table.hline(),
  ),
  caption: [Exemplos de codificação de instruções],
)

= Unidade de controle

Responsável pela implementação: Tiago Rodrigues (`src/control/controller_fsm.vhd`).

== Visão geral

O controlador é uma máquina de estados finita (FSM) que decide, a cada
pulso do botão de clock (debounced), qual conjunto de sinais de controle
fica ativo. Ele não executa nenhuma operação — apenas gera os sinais que o
caminho de dados e a memória usam para executar. O estado atual também é
exposto nos LEDs verdes da FPGA.

Entradas do controlador: `opcode(3:0)` (do decodificador de instrução),
`clk` (pulso debounced) e `reset`. O controlador não recebe `zero` como
entrada: a lógica de decisão do branch (`Zero XOR BNE`) é resolvida dentro
do caminho de dados, o que mantém a FSM 100% Moore (todas as saídas
dependem só do estado atual).

== Estados

Dez estados, agrupados nos cinco estágios clássicos do multiciclo exigidos
pelo enunciado (fetch, decode, execute, memory, write-back). Os estados de
execução de ADDI e de cálculo de endereço (LD/ST) foram fundidos em um
único estado `ADDR_CALC`, já que ambos calculam exatamente `A + imediato`
com os mesmos sinais de controle — a diferença é só o que acontece depois.

#figure(
  table(
    columns: 3,
    table.hline(),
    table.header[*Estado*][*Estágio macro*][*O que acontece*],
    table.hline(),
    [`FETCH`], [Fetch], [Busca a instrução na memória (`Mem[PC]`) e carrega no IR; calcula `PC+1` em paralelo.],
    [`DECODE`], [Decode], [Lê os registradores para os latches A/B; calcula especulativamente o alvo de branch (`PC+1 + imediato`) e guarda em ALUOut.],
    [`ADDR_CALC`], [Execute], [ULA calcula `A + imediato` — usado por ADDI (resultado final) e por LD/ST (endereço efetivo).],
    [`EXEC_R`], [Execute], [ULA executa a operação R-type (ADD/SUB/AND/OR/SLT) sobre A e B.],
    [`BRANCH`], [Execute], [Calcula `A - B` na ULA e sinaliza `PCWriteCond`; a decisão real (BEQ vs. BNE) é resolvida no datapath via `Zero XOR BNE`.],
    [`JUMP`], [Execute], [Escreve o PC incondicionalmente com o endereço de 12 bits do JMP.],
    [`MEM_READ`], [Memory], [Lê a memória de dados no endereço calculado (LD).],
    [`MEM_WRITE`], [Memory], [Escreve a memória de dados no endereço calculado (ST).],
    [`WB_ALU`], [Write-back], [Escreve o resultado da ULA (ALUOut) no banco de registradores (R-type, ADDI).],
    [`WB_MEM`], [Write-back], [Escreve o dado lido da memória (RDM) no banco de registradores (LD).],
    table.hline(),
  ),
  caption: [Estados da unidade de controle],
)

Registradores intermediários do caminho de dados (IR, A, B, ALUOut, RDM)
carregam o valor do estado anterior sem sinal de enable dedicado (escritos
todo ciclo); só `PCWrite`, `PCWriteCond`, `IRWrite`, `RegWrite`, `MemRead`
e `MemWrite` são enables explícitos vindos do controlador.

== Tabela de transições

```
FETCH -> DECODE                                   (sempre)

DECODE -> EXEC_R        se opcode em {ADD,SUB,AND,OR,SLT}
DECODE -> ADDR_CALC     se opcode em {ADDI,LD,ST}
DECODE -> BRANCH        se opcode em {BEQ,BNE}
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

== Sinais de controle

#figure(
  table(
    columns: 3,
    table.hline(),
    table.header[*Sinal*][*Largura*][*Significado*],
    table.hline(),
    [`PCWrite`], [1], [Habilita escrita incondicional do PC (FETCH, JUMP).],
    [`PCWriteCond`], [1], [Habilita a tentativa de escrita condicional do PC (ativo em `BRANCH`). A escrita de fato só ocorre se `Zero XOR BNE` for `1` — resolvido no datapath.],
    [`BNE`], [1], [`1` quando a instrução atual é BNE, `0` caso contrário (inclusive para BEQ). Derivado direto do opcode, não é um sinal "por estado".],
    [`IorD`], [1], [Endereço de memória: `0` = PC (FETCH), `1` = ALUOut (LD/ST).],
    [`IRWrite`], [1], [Habilita escrita no registrador de instrução (FETCH).],
    [`MemRead`], [1], [Habilita leitura de memória.],
    [`MemWrite`], [1], [Habilita escrita em memória.],
    [`MemToReg`], [1], [Seleciona dado a escrever no banco: `0` = ALUOut, `1` = RDM.],
    [`RegWrite`], [1], [Habilita escrita no banco de registradores.],
    [`ALUSrcA`], [1], [Operando A da ULA: `0` = PC, `1` = registrador A.],
    [`ALUSrcB(1:0)`], [2], [Operando B da ULA: `00` = registrador B, `01` = constante 1, `10` = imediato estendido.],
    [`ALUOp(2:0)`], [3], [Código final da ULA.],
    [`PCSource(1:0)`], [2], [Próximo PC: `00` = saída da ULA, `01` = ALUOut (alvo de branch), `10` = endereço de jump.],
    [`led_state`], [5], [Codificação one-hot do estágio macro atual.],
    table.hline(),
  ),
  caption: [Sinais de controle gerados pela FSM],
)

`RegDst` não existe nesta FSM: neste ISA o registrador destino é sempre
`Ri`. O mux da porta B do banco de registradores é resolvido pelo
decodificador direto a partir do opcode — não é um sinal gerado pelo
controlador.

=== Codificação de `ALUOp`

O controlador emite direto o código final de 3 bits que a ULA consome, sem
unidade intermediária de "ALU control", porque não há campo `funct`
compartilhado neste ISA:

#figure(
  table(
    columns: 2,
    table.hline(),
    table.header[*ALUOp*][*Operação*],
    table.hline(),
    [`000`], [AND],
    [`001`], [OR],
    [`010`], [ADD],
    [`100`], [SUB],
    [`110`], [SLT],
    table.hline(),
  ),
  caption: [Codificação de ALUOp],
)

Uso por estado: `EXEC_R` mapeia 1:1 pelo opcode; `DECODE`, `ADDR_CALC` e
`FETCH` forçam ADD (`010`); `BRANCH` força SUB (`100`) para gerar o `zero`
usado internamente pelo datapath.

== Tabela de sinais por estado

#page(flipped: true, margin: (top: 2cm, left: 2cm, right: 2cm, bottom: 2cm))[
  #set text(size: 9pt)
  #figure(
    table(
      columns: (auto,) * 13,
      table.hline(),
      table.header[*Estado*][*PCWrite*][*PCWriteCond*][*IorD*][*IRWrite*][*MemRead*][*MemWrite*][*MemToReg*][*RegWrite*][*ALUSrcA*][*ALUSrcB*][*ALUOp*][*PCSource*],
      table.hline(),
      [FETCH], [1], [0], [0], [1], [1], [0], [X], [0], [0], [01], [010], [00],
      [DECODE], [0], [0], [X], [0], [0], [0], [X], [0], [0], [10], [010], [X],
      [ADDR\_CALC], [0], [0], [X], [0], [0], [0], [X], [0], [1], [10], [010], [X],
      [EXEC\_R], [0], [0], [X], [0], [0], [0], [X], [0], [1], [00], [(por opcode)], [X],
      [MEM\_READ], [0], [0], [1], [0], [1], [0], [X], [0], [X], [XX], [XXX], [X],
      [MEM\_WRITE], [0], [0], [1], [0], [0], [1], [X], [0], [X], [XX], [XXX], [X],
      [WB\_ALU], [0], [0], [X], [0], [0], [0], [0], [1], [X], [XX], [XXX], [X],
      [WB\_MEM], [0], [0], [X], [0], [0], [0], [1], [1], [X], [XX], [XXX], [X],
      [BRANCH], [0], [1], [X], [0], [0], [0], [X], [0], [1], [00], [100], [01],
      [JUMP], [1], [0], [X], [0], [0], [0], [X], [0], [X], [XX], [XXX], [10],
      table.hline(),
    ),
    caption: [Sinais de controle por estado (X = não importa)],
  )
]

*Nota sobre `PCWriteCond`/`BNE`:* diferente do MIPS clássico (que só cobre
BEQ), este controlador fica puramente Moore: `PCWriteCond` é `1` sempre que
o estado atual é `BRANCH`, sem olhar `opcode` nem `zero`. A polaridade
BEQ/BNE é resolvida inteiramente no datapath, que calcula `Zero XOR BNE` e
só efetiva a escrita do PC quando esse resultado é `1`.

== LEDs verdes

O enunciado pede que os LEDs verdes indiquem o estado da unidade de
controle. `led_state` usa one-hot de 5 bits, um por estágio macro:

#figure(
  table(
    columns: 3,
    table.hline(),
    table.header[*led\_state*][*Estágio*][*Estados internos mapeados*],
    table.hline(),
    [`00001`], [Fetch], [`FETCH`],
    [`00010`], [Decode], [`DECODE`],
    [`00100`], [Execute], [`ADDR_CALC`, `EXEC_R`, `BRANCH`, `JUMP`],
    [`01000`], [Memory], [`MEM_READ`, `MEM_WRITE`],
    [`10000`], [Write-back], [`WB_ALU`, `WB_MEM`],
    table.hline(),
  ),
  caption: [Mapeamento de estados para os LEDs verdes],
)

== Riscos e pontos de atenção

- *Timing de branch:* o endereço de branch é calculado especulativamente
  em `DECODE`; a decisão (`Zero XOR BNE`) e a escrita condicional do PC
  ocorrem em `BRANCH`.
- *Acoplamento:* `controller_fsm.vhd` nunca instancia ULA, banco de
  registradores ou memória — só portas de entrada/saída.
- *Reset:* assíncrono, pois vem de um botão físico não sincronizado ao
  clock manual.
- *Leitura síncrona da memória:* a RAM do Quartus (`altsyncram`) é ligada
  no clock invertido, por isso esta FSM não precisa de estados de espera
  em `FETCH` e `MEM_READ`.

= Caminho de dados

Responsável pela implementação: Artur Contarelli (`src/datapath/`).

== Visão geral

O caminho de dados segue a topologia multiciclo de Patterson e Hennessy
(2. ed., cap. 5), adaptada ao formato de instrução do grupo e à FPGA. Cada
instrução é executada em 3 a 5 ciclos. Os resultados intermediários ficam
em registradores entre um ciclo e o próximo, e por isso a mesma ULA e a
mesma memória são reaproveitadas em ciclos diferentes:

- uma memória única para instruções e dados, endereçada pelo PC (busca) ou
  pelo ALUOut (LD/ST), escolhidos pelo mux `IorD`;
- uma ULA, que calcula `PC+1` no FETCH, o alvo do desvio no DECODE e a
  operação da instrução no estado de execução;
- registradores intermediários: `IR`, `RDM`, `A` e `B` e `ALUOut`.

O datapath não decide nada: recebe os sinais de controle da FSM, os campos
da instrução do decodificador e o dado lido da memória. Toda a composição
está em `src/datapath/datapath.vhd`.

#todo[
  Inserir aqui o diagrama do caminho de dados (exportar o diagrama mermaid
  de `docs/especificacao/05-caminho-dados.md` como PNG/SVG).
]

== Componentes

#figure(
  table(
    columns: 3,
    table.hline(),
    table.header[*Componente*][*Arquivo*][*Função*],
    table.hline(),
    [PC], [`pc.vhd`], [Registrador de 16 bits. É escrito quando `PCWrite OR (PCWriteCond AND (zero XOR BNE))`.],
    [Banco de registradores], [`register_file.vhd`], [8 × 16 bits. Duas leituras combinacionais e uma escrita na borda de subida com `RegWrite`. R0 vale sempre 0.],
    [ULA], [`alu.vhd`], [AND, OR, ADD, SUB e SLT (com sinal), escolhidos pelo `ALUOp` de 3 bits. Gera `zero` quando o resultado é 0.],
    [Extensão de sinal], [`sign_extend.vhd`], [Imediato de 6 bits (−32 a +31) para 16 bits.],
    [IR, RDM, A, B, ALUOut], [`register_n.vhd`], [Registrador genérico. O IR só é escrito com `IRWrite`; os demais são escritos em todo ciclo.],
    [Muxes], [`mux_n.vhd`], [Mux genérico (largura e número de entradas configuráveis), usado nos 6 pontos de seleção.],
    table.hline(),
  ),
  caption: [Componentes do caminho de dados],
)

A ULA e o banco de registradores foram adaptados de um laboratório
anterior da disciplina: na ULA, foram removidos NOR, Overflow e Cout, que
nenhuma instrução usa; no banco, saíram os valores iniciais fixos de teste
e entrou o R0 fixo em 0.

== Muxes

#figure(
  table(
    columns: 3,
    table.hline(),
    table.header[*Seletor*][*Entradas*][*Uso*],
    table.hline(),
    [`IorD`], [0 PC · 1 ALUOut], [Endereço da memória: busca da instrução ou LD/ST.],
    [`RegSrcB`], [0 Rk · 1 Ri], [Leitura B do banco: Rk no tipo R; Ri em ST (dado a gravar) e BEQ/BNE (comparação).],
    [`MemToReg`], [0 ALUOut · 1 RDM], [Dado escrito em Ri: resultado da ULA (tipo R, ADDI) ou dado lido (LD).],
    [`ALUSrcA`], [0 PC · 1 A], [Primeiro operando da ULA.],
    [`ALUSrcB`], [00 B · 01 constante 1 · 10 imediato estendido], [Segundo operando da ULA.],
    [`PCSource`], [00 saída da ULA · 01 ALUOut · 10 `end` do JMP], [Próximo PC: `PC+1`, alvo do desvio ou JMP.],
    table.hline(),
  ),
  caption: [Muxes do caminho de dados],
)

Endereços de registrador fixos: a leitura A é sempre Rj, e a escrita é
sempre em Ri, por isso não existe `RegDst`. O `RegSrcB` é gerado pelo
decodificador a partir do opcode, e não pela FSM, porque A e B já são
lidos no DECODE.

== Transferências por estado

#figure(
  table(
    columns: 2,
    table.hline(),
    table.header[*Estado*][*Transferências*],
    table.hline(),
    [FETCH], [`IR ← M[PC]`, `PC ← PC + 1`],
    [DECODE], [`A ← R[Rj]`, `B ← R[Rk ou Ri]`, `ALUOut ← PC + ext(imm)`],
    [ADDR\_CALC], [`ALUOut ← A + ext(imm)` (ADDI, LD, ST)],
    [EXEC\_R], [`ALUOut ← A op B`],
    [MEM\_READ], [`RDM ← M[ALUOut]`],
    [MEM\_WRITE], [`M[ALUOut] ← B` (B = Ri)],
    [WB\_ALU], [`R[Ri] ← ALUOut`],
    [WB\_MEM], [`R[Ri] ← RDM`],
    [BRANCH], [ULA calcula `A − B`; se `zero XOR BNE`, `PC ← ALUOut`],
    [JUMP], [`PC ← end` (12 bits, sem sinal)],
    table.hline(),
  ),
  caption: [Transferências por estado do caminho de dados],
)

== Detalhes de implementação

- *Condição de escrita do PC:* o livro só tem BEQ, que escreve o PC quando
  `zero = 1`. Para cobrir o BNE, a condição virou `zero XOR BNE`, calculada
  no datapath. Com isso a unidade de controle não recebe o `zero` e
  continua sendo uma máquina de Moore pura. _(adaptação)_
- *Temporização da memória:* a memória (`altsyncram`) registra o endereço
  na borda de descida, porque está ligada no clock invertido. Por isso
  FETCH e MEM\_READ levam um ciclo cada.
- *Muxes em VHDL-93:* as entradas do `mux_n` chegam concatenadas num único
  barramento, com a entrada 0 nos bits baixos, porque o VHDL-93 não aceita
  array de vetores sem tamanho fixo nem expressões no `port map`.
- *Reset:* assíncrono em todos os registradores do datapath, com o mesmo
  critério da FSM.

= Metodologia de testes

Todos os testes estão em `sim/testbenches/` e rodam no ModelSim do Quartus
20.1. Cada testbench confere as saídas e termina com `tb_<nome>: OK` ou com
a contagem de falhas. Todos compilam em VHDL-93 e VHDL-2008.

== Testes por módulo

#figure(
  table(
    columns: 2,
    table.hline(),
    table.header[*Testbench*][*O que testa*],
    table.hline(),
    [`tb_alu`], [As 5 operações, `zero`, estouro (`0x7FFF + 1`), resultado negativo e SLT com sinal.],
    [`tb_register_file`], [Escrita e leitura nas duas portas, escrita em R0 ignorada e reset assíncrono.],
    [`tb_pc`], [As 4 combinações de BEQ/BNE com `zero`, `PCWrite` incondicional e reset assíncrono.],
    [`tb_sign_extend`], [Imediatos positivos, negativos e nos limites (−32 e +31).],
    [`tb_mux_n`, `tb_register_n`], [Mux e registrador genéricos com larguras diferentes.],
    [`tb_controller_fsm`], [Sequência de estados e sinais de controle para os 11 opcodes, `BNE`/`PCWriteCond` e reset no meio de uma instrução.],
    [`tb_instruction_decoder`], [Campos dos três formatos e `RegSrcB` para os 16 opcodes.],
    [`tb_memory`], [Conteúdo do `.mif`, temporização da leitura no clock invertido, escrita e leitura de volta, bits altos do endereço ignorados.],
    table.hline(),
  ),
  caption: [Testbenches unitários por módulo],
)

== Testes de integração

Os três usam o programa `programs/asm/programa_completo.asm`, que exercita
as 11 instruções: desvio tomado e não tomado, laço com desvio para trás,
JMP por cima de instrução "veneno", ST seguido de LD do mesmo endereço e
escrita em R0. Estado final esperado: R1 = 6, R2 = 0, R3 = 3, R4 = 9,
R5 = 3, R6 = `000F`, R7 = 9, PC parado em 18.

#figure(
  table(
    columns: 2,
    table.hline(),
    table.header[*Testbench*][*O que integra*],
    table.hline(),
    [`tb_datapath`], [Datapath + FSM real, com modelos simples de memória e decodificador.],
    [`tb_cpu`], [FSM + datapath + decodificador + memória real (`altsyncram`) carregando o `.mif`: a CPU inteira sem a placa.],
    [`tb_cpu_top`], [O `cpu_top` inteiro, testado só pelos pinos da placa.],
    table.hline(),
  ),
  caption: [Testbenches de integração],
)

*Teste de mutação.* Para mostrar que os testes detectam erros, foram
plantados defeitos de propósito, um de cada vez, e todos foram pegos: SLT
sem sinal, R0 gravável, BNE ignorado, `RegSrcB` sem o BNE,
`PCSource = 00` ligado ao ALUOut, uma palavra do `.mif` trocada e memória
sem o clock invertido.

=== `tb_cpu_top`: a placa simulada

Testa o `cpu_top` como alguém olhando a placa, com o programa
`programa_completo.mif`:

- aperta o `KEY[0]` com quique (3 rebotes de 40 ns antes e depois) e
  confere que cada aperto gera exatamente um ciclo;
- confere ciclo a ciclo a primeira instrução (`ADDI R1, R0, 6`): PC nos
  HEX0–3, estado nos LEDG4–0, RDM e ULA nos HEX4–7 com o SW17 nas duas
  posições;
- confere o LEDG8 com o botão apertado e solto;
- roda o programa até o fim e confere o PC parado em `0012`/`0013`;
- dá reset no meio do programa e confere que a primeira instrução é
  buscada de novo corretamente (o teste que pegou o problema descrito na
  seção de dificuldades encontradas).

== Teste na placa

Depois de gravar e apertar o reset (`KEY[1]`), avança-se com o `KEY[0]` e
compara-se a placa com o gabarito completo da seção de resultados. Pontos
que valem mostrar na apresentação:

#figure(
  table(
    columns: 3,
    table.hline(),
    table.header[*Apertos*][*O que observar*][*Prova que*],
    table.hline(),
    [0 → 4], [LEDs: fetch → decode → execute → write-back → fetch; PC 0000 → 0001], [FSM e ADDI],
    [1], [SW17 = 0: `5206` (a instrução lida); SW17 = 1: `0007` (PC + 6, alvo especulativo do desvio)], [RDM, ULA e mux do SW17],
    [30–31], [ST: execute com ULA = `001E` (endereço 30) e depois memory], [cálculo de endereço do ST],
    [36], [LD em write-back com RDM = `0009`], [o ST gravou e o LD leu de volta],
    [38 → 40], [BEQ: PC vai de `000A` para `000B`, pulando o "veneno" do endereço 10], [desvio tomado],
    [41 → 43], [BNE não tomado: PC segue em `000C`], [desvio não tomado],
    [53 → 54], [BNE do laço: PC volta de `000F` para `000D`], [desvio para trás],
    [69 → 71], [JMP: PC vai para `0011`], [salto incondicional],
    [75 em diante], [PC alterna `0012`/`0013` para sempre], [fim de programa (`BEQ R0, R0, -1`)],
    table.hline(),
  ),
  caption: [Roteiro de verificação na placa],
)

O PC mostrado é o valor no estado atual. No FETCH ele é o endereço da
instrução que está sendo buscada; do DECODE em diante ele já foi
incrementado (PC + 1).

= Resultados e discussão

== O que a placa mostra a cada aperto

Gabarito gerado pela simulação do `cpu_top` (`tb_cpu_top`) com o programa
`programa_completo.mif`. Na placa, os valores devem ser os mesmos. Coluna
"Apertos": quantas vezes o `KEY0` foi apertado depois do reset. A
instrução aparece na linha do FETCH em que ela é buscada.

#todo[
  A tabela completa (85 linhas, uma por aperto de botão) está em
  `docs/especificacao/07-resultados-discussao.md`. Decidam em grupo se ela
  entra na íntegra no corpo do texto (como está hoje) ou se vira um anexo,
  com só um trecho representativo aqui — ambas são aceitáveis, mas a
  segunda deixa o relatório mais leve de ler.
]

#page(flipped: true, margin: (top: 2cm, left: 2cm, right: 2cm, bottom: 2cm))[
  #set text(size: 8pt)
  #figure(
    table(
      columns: (auto,) * 6,
      table.hline(),
      table.header[*Apertos*][*Estado (LEDG)*][*PC (HEX3–0)*][*RDM (SW17=0)*][*ULA (SW17=1)*][*Instrução*],
      table.hline(),
      [0], [fetch], [`0000`], [`0000`], [`0001`], [ADDI R1, R0, 6],
      [1], [decode], [`0001`], [`5206`], [`0007`], [],
      [2], [execute], [`0001`], [`543D`], [`0006`], [],
      [3], [write-back], [`0001`], [`543D`], [`0001`], [],
      [4], [fetch], [`0001`], [`543D`], [`0002`], [ADDI R2, R0, -3],
      [5], [decode], [`0002`], [`543D`], [`FFFF`], [],
      [6], [execute], [`0002`], [`0650`], [`FFFD`], [],
      [7], [write-back], [`0002`], [`0650`], [`0002`], [],
      [8], [fetch], [`0002`], [`0650`], [`0003`], [ADD R3, R1, R2],
      [9], [decode], [`0003`], [`0650`], [`0013`], [],
      [10], [execute], [`0003`], [`1850`], [`0003`], [],
      [11], [write-back], [`0003`], [`1850`], [`0000`], [],
      [12], [fetch], [`0003`], [`1850`], [`0004`], [SUB R4, R1, R2],
      [13], [decode], [`0004`], [`1850`], [`0014`], [],
      [14], [execute], [`0004`], [`2A58`], [`0009`], [],
      [15], [write-back], [`0004`], [`2A58`], [`0001`], [],
      [16], [fetch], [`0004`], [`2A58`], [`0005`], [AND R5, R1, R3],
      [17], [decode], [`0005`], [`2A58`], [`001D`], [],
      [18], [execute], [`0005`], [`3C60`], [`0002`], [],
      [19], [write-back], [`0005`], [`3C60`], [`0008`], [],
      [20], [fetch], [`0005`], [`3C60`], [`0006`], [OR R6, R1, R4],
      [21], [decode], [`0006`], [`3C60`], [`FFE6`], [],
      [22], [execute], [`0006`], [`4E88`], [`000F`], [],
      [23], [write-back], [`0006`], [`4E88`], [`000F`], [],
      [24], [fetch], [`0006`], [`4E88`], [`0007`], [SLT R7, R2, R1],
      [25], [decode], [`0007`], [`4E88`], [`000F`], [],
      [26], [execute], [`0007`], [`79DD`], [`0001`], [],
      [27], [write-back], [`0007`], [`79DD`], [`000D`], [],
      [28], [fetch], [`0007`], [`79DD`], [`0008`], [ST R4, R7, 29],
      [29], [decode], [`0008`], [`79DD`], [`0025`], [],
      [30], [execute], [`0008`], [`6E1E`], [`001E`], [],
      [31], [memory], [`0008`], [`6E1E`], [`0011`], [],
      [32], [fetch], [`0008`], [`0009`], [`0009`], [LD R7, R0, 30],
      [33], [decode], [`0009`], [`6E1E`], [`0027`], [],
      [34], [execute], [`0009`], [`8F01`], [`001E`], [],
      [35], [memory], [`0009`], [`8F01`], [`000C`], [],
      [36], [write-back], [`0009`], [`0009`], [`000C`], [],
      [37], [fetch], [`0009`], [`8F01`], [`000A`], [BEQ R7, R4, depois],
      [38], [decode], [`000A`], [`8F01`], [`000B`], [],
      [39], [execute], [`000A`], [`521F`], [`0000`], [],
      [40], [fetch], [`000B`], [`521F`], [`000C`], [BNE R7, R4, laco],
      [41], [decode], [`000C`], [`9F01`], [`000D`], [],
      [42], [execute], [`000C`], [`5B41`], [`0000`], [],
      [43], [fetch], [`000C`], [`5B41`], [`000D`], [ADDI R5, R5, 1],
      [44], [decode], [`000D`], [`5B41`], [`000E`], [],
      [45], [execute], [`000D`], [`5481`], [`0003`], [],
      [46], [write-back], [`000D`], [`5481`], [`000D`], [],
      [47], [fetch], [`000D`], [`5481`], [`000E`], [ADDI R2, R2, 1],
      [48], [decode], [`000E`], [`5481`], [`000F`], [],
      [49], [execute], [`000E`], [`943E`], [`FFFE`], [],
      [50], [write-back], [`000E`], [`943E`], [`000E`], [],
      [51], [fetch], [`000E`], [`943E`], [`000F`], [BNE R2, R0, laco],
      [52], [decode], [`000F`], [`943E`], [`000D`], [],
      [53], [execute], [`000F`], [`A011`], [`0002`], [],
      [54], [fetch], [`000D`], [`A011`], [`000E`], [ADDI R2, R2, 1],
      [55], [decode], [`000E`], [`5481`], [`000F`], [],
      [56], [execute], [`000E`], [`943E`], [`FFFF`], [],
      [57], [write-back], [`000E`], [`943E`], [`000E`], [],
      [58], [fetch], [`000E`], [`943E`], [`000F`], [BNE R2, R0, laco],
      [59], [decode], [`000F`], [`943E`], [`000D`], [],
      [60], [execute], [`000F`], [`A011`], [`0001`], [],
      [61], [fetch], [`000D`], [`A011`], [`000E`], [ADDI R2, R2, 1],
      [62], [decode], [`000E`], [`5481`], [`000F`], [],
      [63], [execute], [`000E`], [`943E`], [`0000`], [],
      [64], [write-back], [`000E`], [`943E`], [`000E`], [],
      [65], [fetch], [`000E`], [`943E`], [`000F`], [BNE R2, R0, laco],
      [66], [decode], [`000F`], [`943E`], [`000D`], [],
      [67], [execute], [`000F`], [`A011`], [`0000`], [],
      [68], [fetch], [`000F`], [`A011`], [`0010`], [JMP pula],
      [69], [decode], [`0010`], [`A011`], [`0021`], [],
      [70], [execute], [`0010`], [`521E`], [`0010`], [],
      [71], [fetch], [`0011`], [`521E`], [`0012`], [ADDI R0, R0, 9],
      [72], [decode], [`0012`], [`5009`], [`001B`], [],
      [73], [execute], [`0012`], [`803F`], [`0009`], [],
      [74], [write-back], [`0012`], [`803F`], [`0018`], [],
      [75], [fetch], [`0012`], [`803F`], [`0013`], [BEQ R0, R0, fim],
      [76], [decode], [`0013`], [`803F`], [`0012`], [],
      [77], [execute], [`0013`], [`0000`], [`0000`], [],
      [78], [fetch], [`0012`], [`0000`], [`0013`], [BEQ R0, R0, fim],
      [79], [decode], [`0013`], [`803F`], [`0012`], [],
      [80], [execute], [`0013`], [`0000`], [`0000`], [],
      [81], [fetch], [`0012`], [`0000`], [`0013`], [BEQ R0, R0, fim],
      [82], [decode], [`0013`], [`803F`], [`0012`], [],
      [83], [execute], [`0013`], [`0000`], [`0000`], [],
      [84], [fetch], [`0012`], [`0000`], [`0013`], [BEQ R0, R0, fim],
      table.hline(),
    ),
    caption: [Gabarito de simulação do `cpu_top`, programa completo],
  )
]

== Discussão

- *Por que a ULA mostra valores "estranhos" em alguns estados?* Nos
  estados em que a ULA não é usada (memory, write-back, jump), os
  seletores ficam no valor padrão da FSM e a ULA calcula algo que ninguém
  usa. Os valores que importam são os de FETCH, DECODE e execute.
- *O alvo do desvio aparece em todo DECODE.* Por exemplo, no aperto 1 a
  ULA mostra `0007` (PC + 1 + 6): o DECODE calcula o alvo de desvio para
  qualquer instrução, porque ainda não sabe se ela é um BEQ/BNE. Só os
  desvios usam esse valor.
- *O RDM muda em todo ciclo.* Ele é escrito em todo ciclo, então mostra a
  última palavra lida: a instrução depois de um FETCH e o dado só no
  ciclo seguinte ao MEM\_READ (aperto 36, `0009`).

#todo[
  Acrescentar aqui fotos da placa DE2-115 durante a apresentação/validação
  (displays e LEDs em pontos-chave da tabela acima), com
  `#figure(image("figuras/placa-xx.jpg"), caption: [...])`.
]

= Dificuldades encontradas

== Reset no meio do programa buscava a instrução errada

*Sintoma.* No `tb_cpu_top`, depois de rodar o programa até o fim e dar
reset, o primeiro FETCH carregava no IR `803F` (o BEQ do endereço 18) no
lugar de `5206` (a instrução do endereço 0).

*Causa.* A memória (`altsyncram`) tem leitura síncrona e está ligada no
clock invertido: ela registra o endereço na descida do clock, ou seja,
quando o botão de clock é solto. O reset é assíncrono: zera o PC na hora,
mas não gera borda nenhuma. A memória continuava com o endereço que tinha
registrado na última vez que o `KEY[0]` foi solto, e o primeiro FETCH
depois do reset lia esse endereço antigo. No power-up o problema não
aparecia, porque o registrador de endereço da RAM já começa em 0.

*Solução.* O reset passou a gerar também um pulso de clock
(`cpu_clk = clk_db or reset_db`, em `src/io/clock_reset.vhd`). Soltar o
`KEY[1]` desce o clock junto com o fim do reset, com o PC já em 0, e a
memória registra o endereço 0. Nenhum arquivo da CPU (FSM, datapath,
memória) precisou mudar.

*Lição.* O erro só apareceu ao juntar a memória com os botões da placa:
cada bloco passava nos próprios testes. Por isso o `tb_cpu_top` testa o
topo inteiro pelos pinos, inclusive um reset no meio do programa.

#todo[
  Cada parte do grupo deve acrescentar aqui as próprias dificuldades
  técnicas (ex.: timing de branch, VHDL-93 vs. VHDL-2008, pin planning,
  divergência simulação × placa) que não estejam cobertas pelo caso acima.
]

= Uso de inteligência artificial

#todo[
  Esta seção ainda não foi escrita por ninguém do grupo
  (`docs/especificacao/09-uso-ia.md` não existe). É item obrigatório da
  entrega. Cada integrante deve preencher a própria linha da tabela abaixo
  — não apaguem as linhas dos colegas, só completem a sua.
]

#figure(
  table(
    columns: 4,
    table.hline(),
    table.header[*Integrante*][*Parte do projeto*][*Onde a IA foi usada*][*Por quê*],
    table.hline(),
    [Tiago Rodrigues], [Unidade de controle (`src/control/`)], [#todo[completar]], [#todo[completar]],
    [Artur Contarelli], [Caminho de dados (`src/datapath/`)], [#todo[completar]], [#todo[completar]],
    [Guilherme Fusco], [Integração FPGA (`src/io/`, `src/top/`)], [#todo[completar]], [#todo[completar]],
    [João Minelli], [#todo[confirmar parte]], [#todo[completar]], [#todo[completar]],
    [Ramon Batista], [#todo[confirmar parte]], [#todo[completar]], [#todo[completar]],
    table.hline(),
  ),
  caption: [Uso de IA por integrante e parte do projeto],
)

Sugestões de pontos a declarar, caso se apliquem: geração ou revisão de
testbenches, debouncer/clock\_reset, diagramas mermaid, redação das seções
de especificação, revisão de VHDL já escrito manualmente, geração do
`montador.py`.

// =============================================================================
// ELEMENTOS PÓS-TEXTUAIS
// =============================================================================
#pagebreak()
#heading(numbering: none)[Referências]

#set par(first-line-indent: 0cm, justify: false)

ASSOCIAÇÃO BRASILEIRA DE NORMAS TÉCNICAS. *NBR 14724*: informação e
documentação — trabalhos acadêmicos — apresentação. Rio de Janeiro: ABNT,
2011.

PATTERSON, David A.; HENNESSY, John L. *Computer Organization and Design*:
the hardware/software interface. 2. ed. San Francisco: Morgan Kaufmann,
1997.

#todo[
  Adicionar o manual/datasheet da placa DE2-115 (Terasic) e qualquer
  material de aula citado, em ordem alfabética, formato ABNT NBR 6023.
]
