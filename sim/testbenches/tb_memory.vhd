-- Testbench da memoria (altsyncram, clock invertido, .mif).
-- Confere:
--   * o conteudo inicial vindo do programa_completo.mif;
--   * a temporizacao: o endereco posto na borda de subida so aparece na saida
--     depois da borda de descida, e o dado esta pronto antes da subida seguinte;
--   * escrita e leitura de volta;
--   * os bits 15..12 do endereco sao ignorados.
--
-- O caminho do .mif e relativo ao diretorio onde o vsim roda; passe o caminho
-- certo com -gMIF_FILE=... se rodar de outro lugar.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cpu_pkg.all;

entity tb_memory is
    generic (
        MIF_FILE : string := "../../programs/mif/programa_completo.mif"
    );
end entity tb_memory;

architecture sim of tb_memory is
    constant PERIODO : time := 20 ns;

    type palavras_t is array (0 to 18) of word16;
    constant PROGRAMA : palavras_t := (
        x"5206", x"543D", x"0650", x"1850", x"2A58", x"3C60", x"4E88",
        x"79DD", x"6E1E", x"8F01", x"521F", x"9F01", x"5B41", x"5481",
        x"943E", x"A011", x"521E", x"5009", x"803F"
    );

    signal clk        : std_logic := '0';
    signal fim        : boolean   := false;
    signal addr       : word16    := (others => '0');
    signal write_data : word16    := (others => '0');
    signal MemWrite   : std_logic := '0';
    signal read_data  : word16;
begin
    clk_proc: process
    begin
        while not fim loop
            clk <= '0'; wait for PERIODO / 2;
            clk <= '1'; wait for PERIODO / 2;
        end loop;
        wait;
    end process;

    dut: entity work.memory
        generic map (MIF_FILE => MIF_FILE)
        port map (
            clk => clk, addr => addr, write_data => write_data,
            MemRead => '1', MemWrite => MemWrite, read_data => read_data
        );

    process
        variable falhas : natural := 0;
        variable antes  : word16;

        procedure verifica(cond : boolean; nome : string) is
        begin
            if not cond then
                report "FALHA " & nome severity error;
                falhas := falhas + 1;
            end if;
        end procedure;

        -- poe o endereco logo depois da subida, como o datapath faz, e espera
        -- ate pouco antes da proxima subida (dado ja deve estar pronto)
        procedure le(a : natural) is
        begin
            wait until rising_edge(clk);
            addr <= std_logic_vector(to_unsigned(a, 16));
            wait until falling_edge(clk);
            wait for PERIODO / 4;
        end procedure;
    begin
        -- conteudo do .mif
        for i in PROGRAMA'range loop
            le(i);
            verifica(read_data = PROGRAMA(i), "mif endereco " & integer'image(i));
        end loop;
        le(19);
        verifica(read_data = x"0000", "resto da memoria em 0");

        -- temporizacao: logo depois da subida a saida ainda e a do endereco antigo
        le(0);
        antes := read_data;                       -- 5206
        wait until rising_edge(clk);
        addr <= std_logic_vector(to_unsigned(1, 16));
        wait for 1 ns;
        verifica(read_data = antes, "saida so muda depois da borda de descida");
        wait until falling_edge(clk);
        wait for 1 ns;
        verifica(read_data = PROGRAMA(1), "dado novo depois da borda de descida");

        -- escrita: ativa na borda de descida, como o MEM_WRITE da FSM
        wait until rising_edge(clk);
        addr       <= std_logic_vector(to_unsigned(100, 16));
        write_data <= x"ABCD";
        MemWrite   <= '1';
        wait until rising_edge(clk);
        MemWrite   <= '0';
        le(0);
        le(100);
        verifica(read_data = x"ABCD", "leitura de volta do que foi escrito");

        -- bits altos ignorados: 0x1064 aponta para o endereco 0x064 = 100
        le(16#1064#);
        verifica(read_data = x"ABCD", "bits 15..12 do endereco ignorados");

        if falhas = 0 then
            report "tb_memory: OK" severity note;
        else
            report "tb_memory: " & integer'image(falhas) & " falha(s)" severity failure;
        end if;
        fim <= true;
        wait;
    end process;
end architecture sim;
