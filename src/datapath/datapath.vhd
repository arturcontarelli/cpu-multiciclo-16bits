-- Caminho de dados do multiciclo: compoe somente os modulos de src/datapath.
-- Nao conhece a FSM, o decodificador nem a memoria; recebe os sinais de
-- controle, os campos da instrucao e o dado lido da memoria pelas portas.
-- A ligacao com os outros blocos fica em src/top/cpu_top.vhd.
--
-- Muxes (codificacao em docs/especificacao/04-unidade-controle.md):
--   IorD      0 PC          | 1 ALUOut
--   RegSrcB   0 Rk          | 1 Ri                      (porta B do banco)
--   MemToReg  0 ALUOut      | 1 RDM
--   ALUSrcA   0 PC          | 1 A
--   ALUSrcB   00 B          | 01 constante 1 | 10 imediato estendido
--   PCSource  00 saida ULA  | 01 ALUOut      | 10 end do JMP (12 bits, sem sinal)
-- Porta A do banco = Rj; escrita sempre em Ri.

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity datapath is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;

        -- controle (FSM)
        PCWrite     : in  std_logic;
        PCWriteCond : in  std_logic;
        BNE         : in  std_logic;
        IorD        : in  std_logic;
        IRWrite     : in  std_logic;
        MemToReg    : in  std_logic;
        RegWrite    : in  std_logic;
        ALUSrcA     : in  std_logic;
        ALUSrcB     : in  std_logic_vector(1 downto 0);
        ALUOp       : in  std_logic_vector(2 downto 0);
        PCSource    : in  std_logic_vector(1 downto 0);

        -- campos da instrucao (decodificador)
        RegSrcB     : in  std_logic;
        ri          : in  reg_addr;
        rj          : in  reg_addr;
        rk          : in  reg_addr;
        imm         : in  std_logic_vector(5 downto 0);
        jump_addr   : in  std_logic_vector(11 downto 0);

        -- memoria
        mem_addr       : out word16;
        mem_write_data : out word16;
        mem_read_data  : in  word16;

        -- saidas para o decodificador, displays e testbenches
        instr       : out word16;   -- conteudo do IR
        pc_out      : out word16;   -- HEX0-3
        alu_result  : out word16;   -- saida da ULA (HEX4-7, SW17 = 0)
        rdm_out     : out word16;   -- RDM (HEX4-7, SW17 = 1)
        reg_dump    : out std_logic_vector(127 downto 0)
    );
end entity datapath;

architecture rtl of datapath is
    signal pc_q, pc_next       : word16;
    signal ir_q, rdm_q         : word16;
    signal a_q, b_q, aluout_q  : word16;
    signal reg_a, reg_b        : word16;
    signal reg_write_data      : word16;
    signal read_addr_b         : reg_addr;
    signal imm_ext, jump_ext   : word16;
    signal alu_a, alu_b        : word16;
    signal alu_res             : word16;
    signal alu_zero            : std_logic;

    -- entradas dos muxes concatenadas (entrada 0 nos bits baixos, ver mux_n.vhd);
    -- sinais separados porque VHDL-93 nao aceita expressao no port map
    signal pcsource_in : std_logic_vector(63 downto 0);
    signal alusrcb_in  : std_logic_vector(63 downto 0);
    signal iord_in     : std_logic_vector(31 downto 0);
    signal memtoreg_in : std_logic_vector(31 downto 0);
    signal alusrca_in  : std_logic_vector(31 downto 0);
    signal regsrcb_in  : std_logic_vector(5 downto 0);
    signal sel_iord, sel_memtoreg, sel_alusrca, sel_regsrcb : std_logic_vector(0 downto 0);
begin

    pcsource_in <= x"0000" & jump_ext & aluout_q & alu_res;
    alusrcb_in  <= x"0000" & imm_ext & x"0001" & b_q;
    iord_in     <= aluout_q & pc_q;
    memtoreg_in <= rdm_q & aluout_q;
    alusrca_in  <= a_q & pc_q;
    regsrcb_in  <= ri & rk;

    sel_iord(0)     <= IorD;
    sel_memtoreg(0) <= MemToReg;
    sel_alusrca(0)  <= ALUSrcA;
    sel_regsrcb(0)  <= RegSrcB;

    -- PC e escolha do proximo PC
    u_pc: entity work.pc
        port map (
            clk => clk, reset => reset,
            PCWrite => PCWrite, PCWriteCond => PCWriteCond, BNE => BNE,
            zero => alu_zero, pc_next => pc_next, pc_out => pc_q
        );

    jump_ext <= "0000" & jump_addr;

    u_mux_pcsource: entity work.mux_n
        generic map (WIDTH => 16, SEL_BITS => 2)
        port map (sel => PCSource, data_in => pcsource_in, data_out => pc_next);

    -- endereco da memoria
    u_mux_iord: entity work.mux_n
        generic map (WIDTH => 16, SEL_BITS => 1)
        port map (sel => sel_iord, data_in => iord_in, data_out => mem_addr);

    mem_write_data <= b_q;

    -- IR e RDM recebem o dado lido da memoria
    u_ir: entity work.register_n
        generic map (WIDTH => 16)
        port map (clk => clk, reset => reset, en => IRWrite, d => mem_read_data, q => ir_q);

    u_rdm: entity work.register_n
        generic map (WIDTH => 16)
        port map (clk => clk, reset => reset, en => '1', d => mem_read_data, q => rdm_q);

    -- banco de registradores
    u_mux_regsrcb: entity work.mux_n
        generic map (WIDTH => 3, SEL_BITS => 1)
        port map (sel => sel_regsrcb, data_in => regsrcb_in, data_out => read_addr_b);

    u_mux_memtoreg: entity work.mux_n
        generic map (WIDTH => 16, SEL_BITS => 1)
        port map (sel => sel_memtoreg, data_in => memtoreg_in, data_out => reg_write_data);

    u_regfile: entity work.register_file
        port map (
            clk => clk, reset => reset, RegWrite => RegWrite,
            read_addr_a => rj, read_addr_b => read_addr_b,
            write_addr => ri, write_data => reg_write_data,
            read_data_a => reg_a, read_data_b => reg_b,
            reg_dump => reg_dump
        );

    u_a: entity work.register_n
        generic map (WIDTH => 16)
        port map (clk => clk, reset => reset, en => '1', d => reg_a, q => a_q);

    u_b: entity work.register_n
        generic map (WIDTH => 16)
        port map (clk => clk, reset => reset, en => '1', d => reg_b, q => b_q);

    -- ULA
    u_sign_ext: entity work.sign_extend
        port map (imm => imm, imm_ext => imm_ext);

    u_mux_alusrca: entity work.mux_n
        generic map (WIDTH => 16, SEL_BITS => 1)
        port map (sel => sel_alusrca, data_in => alusrca_in, data_out => alu_a);

    u_mux_alusrcb: entity work.mux_n
        generic map (WIDTH => 16, SEL_BITS => 2)
        port map (sel => ALUSrcB, data_in => alusrcb_in, data_out => alu_b);

    u_alu: entity work.alu
        port map (a => alu_a, b => alu_b, alu_op => ALUOp, result => alu_res, zero => alu_zero);

    u_aluout: entity work.register_n
        generic map (WIDTH => 16)
        port map (clk => clk, reset => reset, en => '1', d => alu_res, q => aluout_q);

    instr      <= ir_q;
    pc_out     <= pc_q;
    alu_result <= alu_res;
    rdm_out    <= rdm_q;

end architecture rtl;
