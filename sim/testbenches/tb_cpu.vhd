-- Testbench de integracao da CPU sem a placa: FSM + datapath + decodificador
-- + memoria real (altsyncram) carregada com programs/mif/programa_completo.mif.
-- A fiacao e a mesma que o cpu_top deve fazer (menos o I/O da placa).
--
-- O programa (programs/asm/programa_completo.asm) usa as 11 instrucoes e
-- termina em BEQ R0, R0, fim. No fim confere os registradores e o PC.
-- R7 = 9 vem do LD de M[30], que so vale 9 se o ST tiver escrito na memoria.
--
-- O caminho do .mif e relativo ao diretorio onde o vsim roda; passe o caminho
-- certo com -gMIF_FILE=... se rodar de outro lugar.

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity tb_cpu is
    generic (
        MIF_FILE : string := "../../programs/mif/programa_completo.mif"
    );
end entity tb_cpu;

architecture sim of tb_cpu is
    constant PERIODO : time    := 20 ns;
    constant CICLOS  : natural := 300;

    signal clk   : std_logic := '0';
    signal reset : std_logic := '1';
    signal fim   : boolean   := false;

    -- controle
    signal PCWrite, PCWriteCond, BNE, IorD, IRWrite : std_logic;
    signal MemRead, MemWrite, MemToReg, RegWrite, ALUSrcA : std_logic;
    signal ALUSrcB, PCSource : std_logic_vector(1 downto 0);
    signal ALUOp     : std_logic_vector(2 downto 0);
    signal led_state : std_logic_vector(4 downto 0);

    -- decodificador
    signal instr     : word16;
    signal opcode    : opcode_t;
    signal ri, rj, rk : reg_addr;
    signal imm       : std_logic_vector(5 downto 0);
    signal jump_addr : std_logic_vector(11 downto 0);
    signal RegSrcB   : std_logic;

    -- memoria e observacao
    signal mem_addr, mem_write_data, mem_read_data : word16;
    signal pc_out, alu_result, rdm_out : word16;
    signal reg_dump : std_logic_vector(127 downto 0);
begin

    clk_proc: process
    begin
        while not fim loop
            clk <= '0'; wait for PERIODO / 2;
            clk <= '1'; wait for PERIODO / 2;
        end loop;
        wait;
    end process;

    u_fsm: entity work.controller_fsm
        port map (
            clk => clk, reset => reset, opcode => opcode,
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
            clk => clk, reset => reset,
            PCWrite => PCWrite, PCWriteCond => PCWriteCond, BNE => BNE,
            IorD => IorD, IRWrite => IRWrite, MemToReg => MemToReg, RegWrite => RegWrite,
            ALUSrcA => ALUSrcA, ALUSrcB => ALUSrcB, ALUOp => ALUOp, PCSource => PCSource,
            RegSrcB => RegSrcB, ri => ri, rj => rj, rk => rk,
            imm => imm, jump_addr => jump_addr,
            mem_addr => mem_addr, mem_write_data => mem_write_data, mem_read_data => mem_read_data,
            instr => instr, pc_out => pc_out, alu_result => alu_result, rdm_out => rdm_out,
            reg_dump => reg_dump
        );

    u_mem: entity work.memory
        generic map (MIF_FILE => MIF_FILE)
        port map (
            clk => clk, addr => mem_addr, write_data => mem_write_data,
            MemRead => MemRead, MemWrite => MemWrite, read_data => mem_read_data
        );

    process
        variable falhas : natural := 0;

        procedure verifica(cond : boolean; nome : string) is
        begin
            if not cond then
                report "FALHA " & nome severity error;
                falhas := falhas + 1;
            end if;
        end procedure;

        -- extrai Rn do reg_dump (R7..R0)
        function reg(n : natural; dump : std_logic_vector(127 downto 0)) return word16 is
            variable w : word16;
        begin
            w := dump(16*n + 15 downto 16*n);
            return w;
        end function;
    begin
        wait for PERIODO;
        reset <= '0';
        wait for PERIODO * CICLOS;

        verifica(reg(0, reg_dump) = x"0000", "R0 = 0 (escrita ignorada)");
        verifica(reg(1, reg_dump) = x"0006", "R1 = 6 (ADDI; venenos pulados)");
        verifica(reg(2, reg_dump) = x"0000", "R2 = 0 (laco com BNE para tras)");
        verifica(reg(3, reg_dump) = x"0003", "R3 = 3 (ADD)");
        verifica(reg(4, reg_dump) = x"0009", "R4 = 9 (SUB)");
        verifica(reg(5, reg_dump) = x"0003", "R5 = 3 (AND + BNE nao tomado)");
        verifica(reg(6, reg_dump) = x"000F", "R6 = 15 (OR)");
        verifica(reg(7, reg_dump) = x"0009", "R7 = 9 (SLT, ST em M[30] e LD de volta)");
        verifica(pc_out = x"0012" or pc_out = x"0013", "PC parado no fim (18/19)");

        if falhas = 0 then
            report "tb_cpu: OK" severity note;
        else
            report "tb_cpu: " & integer'image(falhas) & " falha(s)" severity failure;
        end if;
        fim <= true;
        wait;
    end process;

end architecture sim;
