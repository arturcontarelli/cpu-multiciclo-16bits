-- Entidade de topo da CPU multiciclo na DE2-115 (Parte 4 - Integracao FPGA).
--
-- Unico lugar onde os blocos se conhecem: instancia FSM, decodificador,
-- datapath, memoria e os perifericos de src/io, e faz a fiacao entre eles.
-- Nao tem logica propria (so ligacoes, fatias de barramento e constantes),
-- conforme src/top/README.md.
--
-- Portas: nomes e larguras EXATAMENTE iguais aos de quartus/pinos_de2_115.qsf
-- (o Quartus casa os pinos pelo nome). Pinagem em quartus/pinout.md.
--
-- Uso da placa:
--   KEY[0]   clock manual da CPU (cada aperto = 1 ciclo), via debouncer
--   KEY[1]   reset (assincrono, ativo em 1 depois do debouncer); volta ao
--            FETCH do endereco 0
--   SW[17]   HEX7-4: 0 = RDM, 1 = saida da ULA
--   HEX3-0   PC em hexadecimal (HEX0 = digito menos significativo)
--   LEDG4-0  estado da FSM (one-hot): fetch, decode, execute, memory, write-back
--   LEDG8    clock da CPU (aceso enquanto o KEY[0] ou o KEY[1] esta apertado)
--
-- Generics (so mudam em simulacao):
--   MIF_FILE          programa carregado na memoria; o caminho e relativo a
--                     pasta do projeto Quartus (quartus/)
--   DEBOUNCE_CONTAGEM ciclos de CLOCK_50 que o botao precisa ficar estavel

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity cpu_top is
    generic (
        MIF_FILE          : string   := "../programs/mif/programa_completo.mif";
        DEBOUNCE_CONTAGEM : positive := 1_000_000      -- 20 ms a 50 MHz
    );
    port (
        CLOCK_50 : in  std_logic;
        KEY      : in  std_logic_vector(3 downto 0);
        SW       : in  std_logic_vector(17 downto 0);
        LEDG     : out std_logic_vector(8 downto 0);
        HEX0, HEX1, HEX2, HEX3 : out std_logic_vector(6 downto 0);
        HEX4, HEX5, HEX6, HEX7 : out std_logic_vector(6 downto 0)
    );
end entity cpu_top;

architecture estrutural of cpu_top is

    -- clock e reset da CPU (saidas dos debouncers, ativos em 1)
    signal cpu_clk, cpu_reset : std_logic;

    -- sinais de controle (FSM -> datapath / memoria)
    signal PCWrite, PCWriteCond, BNE, IorD, IRWrite : std_logic;
    signal MemRead, MemWrite, MemToReg, RegWrite    : std_logic;
    signal ALUSrcA                                  : std_logic;
    signal ALUSrcB, PCSource                        : std_logic_vector(1 downto 0);
    signal ALUOp                                    : std_logic_vector(2 downto 0);
    signal led_state                                : std_logic_vector(4 downto 0);

    -- campos da instrucao (decodificador -> FSM / datapath)
    signal instr      : word16;
    signal opcode     : opcode_t;
    signal ri, rj, rk : reg_addr;
    signal imm        : std_logic_vector(5 downto 0);
    signal jump_addr  : std_logic_vector(11 downto 0);
    signal RegSrcB    : std_logic;

    -- memoria (datapath <-> memoria)
    signal mem_addr, mem_write_data, mem_read_data : word16;

    -- observacao (datapath -> displays)
    signal pc_out, alu_result, rdm_out : word16;
    signal hex_dado                    : word16;   -- RDM ou ULA, conforme SW17

begin

    ---------------------------------------------------------------------------
    -- Perifericos de entrada: botoes -> clock e reset da CPU
    ---------------------------------------------------------------------------
    -- debouncers dos dois botoes; soltar o reset tambem gera uma descida de
    -- clock para a memoria registrar o endereco 0 (ver src/io/clock_reset.vhd)
    u_clock_reset: entity work.clock_reset
        generic map (CONTAGEM => DEBOUNCE_CONTAGEM)
        port map (
            clk_50 => CLOCK_50, key_clk => KEY(0), key_reset => KEY(1),
            cpu_clk => cpu_clk, cpu_reset => cpu_reset
        );

    ---------------------------------------------------------------------------
    -- Nucleo da CPU (mesma fiacao de sim/testbenches/tb_cpu.vhd)
    ---------------------------------------------------------------------------
    u_fsm: entity work.controller_fsm
        port map (
            clk => cpu_clk, reset => cpu_reset, opcode => opcode,
            PCWrite => PCWrite, PCWriteCond => PCWriteCond, BNE => BNE,
            IorD => IorD, IRWrite => IRWrite, MemRead => MemRead, MemWrite => MemWrite,
            MemToReg => MemToReg, RegWrite => RegWrite, ALUSrcA => ALUSrcA,
            ALUSrcB => ALUSrcB, ALUOp => ALUOp, PCSource => PCSource,
            led_state => led_state
        );

    u_dec: entity work.instruction_decoder
        port map (
            instr => instr, opcode => opcode, ri => ri, rj => rj, rk => rk,
            imm => imm, jump_addr => jump_addr, RegSrcB => RegSrcB
        );

    u_dp: entity work.datapath
        port map (
            clk => cpu_clk, reset => cpu_reset,
            PCWrite => PCWrite, PCWriteCond => PCWriteCond, BNE => BNE,
            IorD => IorD, IRWrite => IRWrite, MemToReg => MemToReg, RegWrite => RegWrite,
            ALUSrcA => ALUSrcA, ALUSrcB => ALUSrcB, ALUOp => ALUOp, PCSource => PCSource,
            RegSrcB => RegSrcB, ri => ri, rj => rj, rk => rk,
            imm => imm, jump_addr => jump_addr,
            mem_addr => mem_addr, mem_write_data => mem_write_data,
            mem_read_data => mem_read_data,
            instr => instr, pc_out => pc_out, alu_result => alu_result,
            rdm_out => rdm_out,
            reg_dump => open                      -- so usado nos testbenches
        );

    -- a memoria inverte o clock internamente (ver src/memory/memory.vhd)
    u_mem: entity work.memory
        generic map (MIF_FILE => MIF_FILE)
        port map (
            clk => cpu_clk, addr => mem_addr, write_data => mem_write_data,
            MemRead => MemRead, MemWrite => MemWrite, read_data => mem_read_data
        );

    ---------------------------------------------------------------------------
    -- Perifericos de saida
    ---------------------------------------------------------------------------
    -- LEDs verdes: LEDG8 = clock da CPU, LEDG7-5 apagados, LEDG4-0 = estado
    LEDG <= cpu_clk & "000" & led_state;

    -- HEX3..HEX0: PC
    u_hex0: entity work.hex_display port map (digito => pc_out(3 downto 0),   segmentos => HEX0);
    u_hex1: entity work.hex_display port map (digito => pc_out(7 downto 4),   segmentos => HEX1);
    u_hex2: entity work.hex_display port map (digito => pc_out(11 downto 8),  segmentos => HEX2);
    u_hex3: entity work.hex_display port map (digito => pc_out(15 downto 12), segmentos => HEX3);

    -- HEX7..HEX4: RDM (SW17 = 0) ou saida da ULA (SW17 = 1)
    u_hex_mux: entity work.hex_mux
        port map (sel => SW(17), rdm => rdm_out, ula => alu_result, saida => hex_dado);

    u_hex4: entity work.hex_display port map (digito => hex_dado(3 downto 0),   segmentos => HEX4);
    u_hex5: entity work.hex_display port map (digito => hex_dado(7 downto 4),   segmentos => HEX5);
    u_hex6: entity work.hex_display port map (digito => hex_dado(11 downto 8),  segmentos => HEX6);
    u_hex7: entity work.hex_display port map (digito => hex_dado(15 downto 12), segmentos => HEX7);

    -- KEY[3:2] e SW[16:0] nao sao usados (estao no .qsf so para as portas
    -- ficarem completas).

end architecture estrutural;
