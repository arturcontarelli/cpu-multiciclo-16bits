# Estrutura do Projeto

Este documento descreve a organização de pastas da CPU multiciclo 16 bits e como ela aplica os princípios de **SOLID** e **DRY** (adaptados do mundo OO para VHDL/hardware).

## Visão geral

```
cpu-multiciclo-16bits/
├── docs/                   # documentação do projeto e da especificação
│   └── especificacao/      # seções que compõem o PDF final de entrega
├── src/                    # código-fonte VHDL
│   ├── common/             # pacote compartilhado: tipos, constantes, opcodes
│   ├── datapath/           # ALU, banco de registradores, PC, extensão de sinal, muxes
│   ├── control/            # unidade de controle (FSM) e decodificador de instrução
│   ├── memory/             # memória de instrução e de dados
│   ├── io/                 # periféricos da FPGA: debouncer, displays HEX
│   └── top/                # entidade de topo que integra todos os módulos
├── sim/
│   └── testbenches/        # um testbench por módulo + testbench de integração
├── programs/
│   ├── asm/                # pseudo-assembly dos programas de teste (legível)
│   └── mif/                # arquivos .mif gerados a partir do asm, usados na FPGA
└── quartus/                 # projeto Quartus (.qpf/.qsf) e pin planning
```

## Como SOLID e DRY se aplicam aqui

### Single Responsibility (SRP)
Cada arquivo `.vhd` implementa **uma** entidade com **uma** responsabilidade: a ALU só calcula, o banco de registradores só armazena/lê registradores, o controlador só gera sinais de controle. Nenhum módulo decide "o que fazer" fora do seu escopo — quem decide o fluxo é sempre o controlador, quem decide a fiação é sempre o `top`.

### Open/Closed
Opcodes, larguras de bits e tipos ficam centralizados em `src/common/cpu_pkg.vhd`. Adicionar uma instrução nova deve, idealmente, exigir apenas:
- uma nova constante de opcode no pacote;
- um novo `case` no decodificador e no controlador;
sem alterar a interface (portas) dos módulos de datapath já existentes.

### Liskov / Interface Segregation
Componentes reutilizáveis (muxes, registradores, somadores) são genéricos e parametrizáveis por largura de bits, com portas mínimas e bem definidas — evita que um módulo exponha sinais que o chamador não precisa.

### Dependency Inversion
Os módulos de `datapath/`, `control/` e `memory/` **não se conhecem entre si**. Toda a fiação (quem conecta com quem) acontece em `src/top/cpu_top.vhd`. Isso permite testar cada módulo isoladamente (via testbench) e trocar a implementação de um módulo sem tocar nos outros.

### DRY
- `src/common/cpu_pkg.vhd` evita duplicar constantes de opcode e tipos em múltiplos arquivos.
- Componentes genéricos (mux, registrador) evitam duplicar a mesma lógica combinacional/sequencial em vários lugares com larguras diferentes.
- Os programas de teste ficam como fonte (`programs/asm`) + gerado (`programs/mif`), evitando editar `.mif` manualmente e duplicar lógica de tradução.

## Relação com a divisão de equipe

Ver [`divisao-equipe.md`](divisao-equipe.md) para quem é responsável por cada pasta:

| Pasta | Parte responsável |
|---|---|
| `src/control/` | 1. Unidade de Controle (FSM) — Tiago |
| `src/datapath/` | 2. Caminho de Dados — ALU e Banco de Registradores |
| `src/memory/`, `src/common/` | 3. Memória e Decodificação de Instruções |
| `src/io/`, `src/top/`, `quartus/` | 4. Integração FPGA e Periféricos |
| `sim/`, `programs/`, `docs/especificacao/` | 5. Testes, Documentação e Coordenação |

## Decisões de organização e documentação

- **README por pasta**: não é uma convenção de VHDL nem do Quartus (a ferramenta não lê nem se importa com isso) — é uma escolha deliberada do grupo para deixar a responsabilidade de cada pasta visível sem depender de abrir um doc externo, já que são 5 pessoas trabalhando em partes diferentes. Mantenha cada README curto (regra, não texto didático), para não duplicar o que vai no documento de especificação oficial em `docs/especificacao/`. O efeito colateral é que isso também mantém as pastas ainda vazias versionadas no Git (que não rastreia diretório vazio); a alternativa seria um `.gitkeep` sem conteúdo, descartada aqui em favor do README por ter valor documental.
- **Caminho de `programs/mif/`**: decidido e fixado desde já porque blocos de memória do Quartus (wizard/`altsyncram`) guardam o caminho do `.mif` na configuração do componente, e o ModelSim resolve esse caminho relativo ao diretório de simulação. Mover o arquivo depois exige corrigir a referência manualmente em cada lugar que a usa — evitem reorganizar `programs/` depois que a memória já estiver configurada no Quartus.
