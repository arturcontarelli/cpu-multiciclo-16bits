-- Testbench de integracao da placa (Parte 4): cpu_top inteiro, olhando so os
-- pinos da DE2-115 (HEX, LEDG), como alguem olhando a placa.
--
-- Simula o CLOCK_50 e os apertos do KEY[0] COM quique (o contato abre e fecha
-- algumas vezes), para provar que o debouncer gera exatamente 1 ciclo de CPU
-- por aperto. O DEBOUNCE_CONTAGEM e reduzido para a simulacao ser rapida.
--
-- Roteiro (programa programs/mif/programa_completo.mif):
--   1. reset -> PC = 0000, FETCH; RDM e ULA nos displays conforme SW17
--   2. 4 apertos percorrem ADDI R1,R0,6: FETCH, DECODE, ADDR_CALC, WB_ALU
--   3. roda o programa ate o fim: PC parado em 0012/0013
--   4. reset no meio do programa e confere que a 1a instrucao e buscada de
--      novo corretamente (testa o pulso de clock gerado pelo reset, ver
--      src/io/clock_reset.vhd)
--
-- Caminho do .mif: relativo ao diretorio onde o vsim roda, igual ao tb_cpu
-- (passe -gMIF_FILE=... se rodar de outro lugar).

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

entity tb_cpu_top is
    generic (
        MIF_FILE : string := "../../programs/mif/programa_completo.mif"
    );
end entity tb_cpu_top;

architecture sim of tb_cpu_top is
    constant PERIODO_50M : time     := 20 ns;
    constant CONTAGEM    : positive := 8;              -- debouncer curto
    constant ESPERA      : time     := PERIODO_50M * 40;  -- > CONTAGEM + sincronizador

    signal CLOCK_50 : std_logic := '0';
    signal KEY      : std_logic_vector(3 downto 0)  := (others => '1');  -- soltos
    signal SW       : std_logic_vector(17 downto 0) := (others => '0');
    signal LEDG     : std_logic_vector(8 downto 0);
    signal HEX0, HEX1, HEX2, HEX3 : std_logic_vector(6 downto 0);
    signal HEX4, HEX5, HEX6, HEX7 : std_logic_vector(6 downto 0);
    signal fim      : boolean := false;

    -- converte o padrao de segmentos (ativo em 0) de volta para o digito
    function seg2hex(s : std_logic_vector(6 downto 0)) return std_logic_vector is
    begin
        case s is
            when "1000000" => return x"0";
            when "1111001" => return x"1";
            when "0100100" => return x"2";
            when "0110000" => return x"3";
            when "0011001" => return x"4";
            when "0010010" => return x"5";
            when "0000010" => return x"6";
            when "1111000" => return x"7";
            when "0000000" => return x"8";
            when "0010000" => return x"9";
            when "0001000" => return x"A";
            when "0000011" => return x"B";
            when "1000110" => return x"C";
            when "0100001" => return x"D";
            when "0000110" => return x"E";
            when "0001110" => return x"F";
            when others    => return "XXXX";
        end case;
    end function;

    function hex2str(v : word16) return string is
        constant DIG : string(1 to 16) := "0123456789ABCDEF";
        variable s   : string(1 to 4);
        variable n   : integer;
    begin
        for i in 0 to 3 loop
            n := 0;
            for b in 3 downto 0 loop
                n := n * 2;
                if v(4*(3-i) + b) = '1' then n := n + 1; end if;
            end loop;
            s(i + 1) := DIG(n + 1);
        end loop;
        return s;
    end function;
begin

    clk_proc: process
    begin
        while not fim loop
            CLOCK_50 <= '0'; wait for PERIODO_50M / 2;
            CLOCK_50 <= '1'; wait for PERIODO_50M / 2;
        end loop;
        wait;
    end process;

    dut: entity work.cpu_top
        generic map (MIF_FILE => MIF_FILE, DEBOUNCE_CONTAGEM => CONTAGEM)
        port map (
            CLOCK_50 => CLOCK_50, KEY => KEY, SW => SW, LEDG => LEDG,
            HEX0 => HEX0, HEX1 => HEX1, HEX2 => HEX2, HEX3 => HEX3,
            HEX4 => HEX4, HEX5 => HEX5, HEX6 => HEX6, HEX7 => HEX7
        );

    estimulo: process
        variable falhas : natural := 0;

        procedure verifica(cond : boolean; nome : string) is
        begin
            if not cond then
                report "FALHA " & nome severity error;
                falhas := falhas + 1;
            end if;
        end procedure;

        -- aperta e solta um botao, com quiques curtos (menores que o debounce)
        procedure aperta(n : natural) is
        begin
            for q in 1 to 3 loop
                KEY(n) <= '0'; wait for PERIODO_50M * 2;
                KEY(n) <= '1'; wait for PERIODO_50M * 2;
            end loop;
            KEY(n) <= '0'; wait for ESPERA;      -- apertado e estavel
            for q in 1 to 3 loop
                KEY(n) <= '1'; wait for PERIODO_50M * 2;
                KEY(n) <= '0'; wait for PERIODO_50M * 2;
            end loop;
            KEY(n) <= '1'; wait for ESPERA;      -- solto e estavel
        end procedure;

        procedure clock_cpu(vezes : natural) is
        begin
            for i in 1 to vezes loop
                aperta(0);
            end loop;
        end procedure;

        impure function pc return word16 is
        begin
            return seg2hex(HEX3) & seg2hex(HEX2) & seg2hex(HEX1) & seg2hex(HEX0);
        end function;

        impure function hex_alto return word16 is
        begin
            return seg2hex(HEX7) & seg2hex(HEX6) & seg2hex(HEX5) & seg2hex(HEX4);
        end function;

        -- confere PC, estado (LEDG4-0), RDM (SW17=0) e ULA (SW17=1)
        procedure confere(nome : string; pc_esp : word16;
                          estado : std_logic_vector(4 downto 0);
                          rdm_esp, ula_esp : word16) is
        begin
            SW(17) <= '0'; wait for PERIODO_50M;
            verifica(hex_alto = rdm_esp, nome & ": RDM = " & hex2str(rdm_esp) &
                     " (lido " & hex2str(hex_alto) & ")");
            SW(17) <= '1'; wait for PERIODO_50M;
            verifica(hex_alto = ula_esp, nome & ": ULA = " & hex2str(ula_esp) &
                     " (lido " & hex2str(hex_alto) & ")");
            verifica(pc = pc_esp, nome & ": PC = " & hex2str(pc_esp) &
                     " (lido " & hex2str(pc) & ")");
            verifica(LEDG(4 downto 0) = estado, nome & ": LEDG4-0");
            verifica(LEDG(7 downto 5) = "000", nome & ": LEDG7-5 apagados");
            verifica(LEDG(8) = '0', nome & ": LEDG8 apagado com o botao solto");
        end procedure;

        -- os 4 ciclos de ADDI R1, R0, 6 (M[0] = 5206) logo depois de um reset
        procedure confere_primeira_instrucao(quando : string) is
        begin
            -- FETCH: ULA calcula PC + 1; RDM ainda e o valor zerado pelo reset
            confere(quando & " FETCH", x"0000", "00001", x"0000", x"0001");
            clock_cpu(1);
            -- DECODE: IR = RDM = M[0]; ULA = PC + ext(6) = 1 + 6
            confere(quando & " DECODE", x"0001", "00010", x"5206", x"0007");
            clock_cpu(1);
            -- ADDR_CALC: ULA = A + ext(6) = R0 + 6; o RDM e escrito todo
            -- ciclo e, no DECODE, a memoria leu M[PC] = M[1] = 543D
            confere(quando & " ADDR_CALC", x"0001", "00100", x"543D", x"0006");
            clock_cpu(1);
            -- WB_ALU: R1 <- 6 (ULA mostra 0 + 0, operandos don't care)
            verifica(LEDG(4 downto 0) = "10000", quando & " WB_ALU: LEDG4-0");
            clock_cpu(1);
            -- FETCH da 2a instrucao (ADDI R2, R0, -3)
            verifica(pc = x"0001" and LEDG(4 downto 0) = "00001",
                     quando & " FETCH da instrucao 1");
        end procedure;
    begin
        -- 1. reset inicial
        wait for ESPERA;
        aperta(1);
        confere_primeira_instrucao("inicio");

        -- LEDG8 acompanha o botao de clock
        KEY(0) <= '0'; wait for ESPERA;
        verifica(LEDG(8) = '1', "LEDG8 aceso com KEY0 apertado");
        KEY(0) <= '1'; wait for ESPERA;

        -- 3. roda o resto do programa (ver tb_cpu: termina em ~80 ciclos)
        clock_cpu(100);
        verifica(pc = x"0012" or pc = x"0013",
                 "PC parado no fim (lido " & hex2str(pc) & ")");

        -- 4. reset no meio do programa (memoria estava lendo o endereco 18)
        aperta(1);
        confere_primeira_instrucao("depois do reset");

        if falhas = 0 then
            report "tb_cpu_top: OK" severity note;
        else
            report "tb_cpu_top: " & integer'image(falhas) & " falha(s)" severity failure;
        end if;
        fim <= true;
        wait;
    end process;

end architecture sim;
