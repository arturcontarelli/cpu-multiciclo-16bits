-- Testbench do PC: escrita incondicional (PCWrite), tabela completa da
-- escrita condicional (PCWriteCond, BNE, zero) e reset assincrono.

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity tb_pc is
end entity tb_pc;

architecture sim of tb_pc is
    constant PERIODO : time := 20 ns;

    signal clk         : std_logic := '0';
    signal reset       : std_logic := '1';
    signal PCWrite     : std_logic := '0';
    signal PCWriteCond : std_logic := '0';
    signal BNE         : std_logic := '0';
    signal zero        : std_logic := '0';
    signal pc_next     : word16    := (others => '0');
    signal pc_out      : word16;
    signal fim         : boolean   := false;
begin

    dut: entity work.pc
        port map (
            clk => clk, reset => reset, PCWrite => PCWrite, PCWriteCond => PCWriteCond,
            BNE => BNE, zero => zero, pc_next => pc_next, pc_out => pc_out
        );

    clk_proc: process
    begin
        while not fim loop
            clk <= '0'; wait for PERIODO / 2;
            clk <= '1'; wait for PERIODO / 2;
        end loop;
        wait;
    end process;

    process
        variable falhas : natural := 0;

        -- aplica os sinais, passa uma borda de subida e confere o PC
        procedure ciclo(w, cond, bne_v, zero_v : std_logic; prox, esperado : word16; nome : string) is
        begin
            wait until falling_edge(clk);
            PCWrite     <= w;
            PCWriteCond <= cond;
            BNE         <= bne_v;
            zero        <= zero_v;
            pc_next     <= prox;
            wait until rising_edge(clk);
            wait for 1 ns;
            if pc_out /= esperado then
                report "FALHA " & nome severity error;
                falhas := falhas + 1;
            end if;
        end procedure;
    begin
        wait for PERIODO;
        if pc_out /= x"0000" then
            report "FALHA reset inicial" severity error;
            falhas := falhas + 1;
        end if;
        reset <= '0';

        --    PCWrite Cond BNE zero  pc_next  esperado
        ciclo('1', '0', '0', '0', x"0001", x"0001", "PCWrite carrega");
        ciclo('0', '0', '0', '0', x"00FF", x"0001", "sem enable mantem");
        ciclo('0', '0', '0', '1', x"00FF", x"0001", "zero sem PCWriteCond mantem");
        ciclo('0', '1', '0', '1', x"0010", x"0010", "BEQ com zero = 1 desvia");
        ciclo('0', '1', '0', '0', x"0020", x"0010", "BEQ com zero = 0 nao desvia");
        ciclo('0', '1', '1', '0', x"0030", x"0030", "BNE com zero = 0 desvia");
        ciclo('0', '1', '1', '1', x"0040", x"0030", "BNE com zero = 1 nao desvia");
        ciclo('1', '0', '1', '1', x"0ABC", x"0ABC", "PCWrite ignora zero/BNE (JMP)");

        -- reset assincrono
        wait until falling_edge(clk);
        wait for 2 ns;
        reset <= '1';
        wait for 1 ns;
        if pc_out /= x"0000" then
            report "FALHA reset assincrono" severity error;
            falhas := falhas + 1;
        end if;

        if falhas = 0 then
            report "tb_pc: OK" severity note;
        else
            report "tb_pc: " & integer'image(falhas) & " falha(s)" severity failure;
        end if;
        fim <= true;
        wait;
    end process;

end architecture sim;
