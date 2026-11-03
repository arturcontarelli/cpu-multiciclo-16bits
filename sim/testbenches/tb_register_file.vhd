-- Testbench do banco de registradores: confere reset, escrita sincrona,
-- leitura simultanea nas duas portas, RegWrite = 0, R0 sempre 0 e
-- reset assincrono no meio da execucao.
-- Os estimulos mudam na borda de descida e sao conferidos depois da subida.

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity tb_register_file is
end entity tb_register_file;

architecture sim of tb_register_file is
    constant PERIODO : time := 20 ns;
    constant ZEROS   : std_logic_vector(127 downto 0) := (others => '0');

    signal clk         : std_logic := '0';
    signal reset       : std_logic := '1';
    signal RegWrite    : std_logic := '0';
    signal read_addr_a : reg_addr  := "000";
    signal read_addr_b : reg_addr  := "000";
    signal write_addr  : reg_addr  := "000";
    signal write_data  : word16    := (others => '0');
    signal read_data_a : word16;
    signal read_data_b : word16;
    signal reg_dump    : std_logic_vector(127 downto 0);
    signal fim         : boolean   := false;
begin

    dut: entity work.register_file
        port map (
            clk => clk, reset => reset, RegWrite => RegWrite,
            read_addr_a => read_addr_a, read_addr_b => read_addr_b,
            write_addr => write_addr, write_data => write_data,
            read_data_a => read_data_a, read_data_b => read_data_b,
            reg_dump => reg_dump
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

        procedure verifica(cond : boolean; nome : string) is
        begin
            if not cond then
                report "FALHA " & nome severity error;
                falhas := falhas + 1;
            end if;
        end procedure;

        -- escreve 'valor' em 'reg' na proxima borda de subida
        procedure escreve(reg : reg_addr; valor : word16; we : std_logic) is
        begin
            wait until falling_edge(clk);
            write_addr <= reg;
            write_data <= valor;
            RegWrite   <= we;
            wait until rising_edge(clk);
            wait for 1 ns;
            RegWrite   <= '0';
        end procedure;
    begin
        wait for PERIODO;
        verifica(reg_dump = ZEROS, "reset inicial zera tudo");
        reset <= '0';

        escreve("001", x"1234", '1');
        escreve("010", x"FFFF", '1');
        escreve("111", x"00A5", '1');

        -- leitura combinacional nas duas portas ao mesmo tempo
        read_addr_a <= "001";
        read_addr_b <= "010";
        wait for 1 ns;
        verifica(read_data_a = x"1234", "porta A le R1");
        verifica(read_data_b = x"FFFF", "porta B le R2");

        read_addr_a <= "111";
        read_addr_b <= "111";
        wait for 1 ns;
        verifica(read_data_a = x"00A5" and read_data_b = x"00A5", "mesmo registrador nas duas portas");

        -- sem RegWrite nada muda
        escreve("001", x"BEEF", '0');
        verifica(reg_dump(31 downto 16) = x"1234", "RegWrite = 0 nao escreve");

        -- R0 sempre 0
        escreve("000", x"FFFF", '1');
        read_addr_a <= "000";
        wait for 1 ns;
        verifica(read_data_a = x"0000", "escrita em R0 ignorada");

        -- sobrescrever
        escreve("010", x"0042", '1');
        verifica(reg_dump(47 downto 32) = x"0042", "sobrescreve R2");

        -- conferencia do dump (R7..R0)
        verifica(reg_dump = x"00A5" & x"0000" & x"0000" & x"0000" & x"0000" & x"0042" & x"1234" & x"0000",
                 "dump R7..R0");

        -- reset assincrono: zera sem esperar borda de clock
        wait until falling_edge(clk);
        wait for 2 ns;
        reset <= '1';
        wait for 1 ns;
        verifica(reg_dump = ZEROS, "reset assincrono zera tudo");
        reset <= '0';

        if falhas = 0 then
            report "tb_register_file: OK" severity note;
        else
            report "tb_register_file: " & integer'image(falhas) & " falha(s)" severity failure;
        end if;
        fim <= true;
        wait;
    end process;

end architecture sim;
