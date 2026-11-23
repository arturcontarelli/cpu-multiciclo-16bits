-- Memoria unica (instrucoes e dados): 4096 palavras de 16 bits, inicializada
-- por um .mif. Usa a altsyncram do Quartus (biblioteca altera_mf) instanciada
-- direto, sem arquivos gerados pelo wizard.
--
-- A leitura da altsyncram e sincrona (o endereco e registrado numa borda).
-- Por isso ela recebe o clock INVERTIDO: o endereco montado pelo datapath
-- depois de uma borda de subida e registrado na borda de descida seguinte, e
-- o dado fica pronto antes da proxima borda de subida, quando o IR ou o RDM o
-- capturam. Assim a FSM nao precisa de estados de espera (ver secao 01).
-- A inversao fica aqui dentro porque o cpu_top nao pode ter logica.
--
-- MemRead nao tem efeito numa RAM de porta unica (ela le todo ciclo); a porta
-- existe para casar com a saida da FSM.

library ieee;
use ieee.std_logic_1164.all;
use work.cpu_pkg.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity memory is
    generic (
        MIF_FILE : string := "../programs/mif/programa_completo.mif"
    );
    port (
        clk        : in  std_logic;
        addr       : in  word16;      -- so os 12 bits baixos sao usados
        write_data : in  word16;
        MemRead    : in  std_logic;
        MemWrite   : in  std_logic;
        read_data  : out word16
    );
end entity memory;

architecture rtl of memory is
    signal clk_n    : std_logic;
    signal addr_12  : std_logic_vector(11 downto 0);
    signal q        : std_logic_vector(15 downto 0);
begin
    clk_n   <= not clk;
    addr_12 <= addr(11 downto 0);

    u_ram: altsyncram
        generic map (
            operation_mode         => "SINGLE_PORT",
            width_a                => 16,
            widthad_a              => 12,
            numwords_a             => 4096,
            outdata_reg_a          => "UNREGISTERED",
            init_file              => MIF_FILE,
            intended_device_family => "Cyclone IV E",
            lpm_type               => "altsyncram",
            power_up_uninitialized => "FALSE",
            read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
            clock_enable_input_a   => "BYPASS",
            clock_enable_output_a  => "BYPASS",
            outdata_aclr_a         => "NONE",
            width_byteena_a        => 1
        )
        port map (
            clock0    => clk_n,
            address_a => addr_12,
            data_a    => write_data,
            wren_a    => MemWrite,
            q_a       => q
        );

    read_data <= q;
end architecture rtl;
