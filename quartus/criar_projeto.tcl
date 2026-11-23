# Cria o projeto Quartus da CPU multiciclo para a DE2-115 (Parte 4).
#
# Rode DENTRO da pasta quartus/ (o caminho do .mif e relativo a ela):
#   quartus_sh -t criar_projeto.tcl
# No Windows, o quartus_sh fica em <instalacao>\quartus\bin64\ (ex.:
# C:\intelFPGA_lite\20.1\quartus\bin64\quartus_sh.exe).
#
# Gera cpu_multiciclo.qpf e cpu_multiciclo.qsf. Esses dois arquivos sao
# gerados (estao no .gitignore): para mudar alguma configuracao de forma
# permanente, mude aqui ou em pinos_de2_115.qsf e rode o script de novo.
# Depois: File > Open Project > quartus/cpu_multiciclo.qpf, e compile.

load_package project

project_new cpu_multiciclo -overwrite

# --- dispositivo e topo -------------------------------------------------------
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE115F29C7
set_global_assignment -name TOP_LEVEL_ENTITY cpu_top
set_global_assignment -name VHDL_INPUT_VERSION VHDL_1993
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
set_global_assignment -name RESERVE_ALL_UNUSED_PINS_WEAK_PULLUP "AS INPUT TRI-STATED"

# --- fontes VHDL (o Quartus resolve a ordem sozinho) --------------------------
set fontes {
    ../src/common/cpu_pkg.vhd
    ../src/datapath/alu.vhd
    ../src/datapath/mux_n.vhd
    ../src/datapath/pc.vhd
    ../src/datapath/register_file.vhd
    ../src/datapath/register_n.vhd
    ../src/datapath/sign_extend.vhd
    ../src/datapath/datapath.vhd
    ../src/control/controller_fsm.vhd
    ../src/memory/instruction_decoder.vhd
    ../src/memory/memory.vhd
    ../src/io/debouncer.vhd
    ../src/io/clock_reset.vhd
    ../src/io/hex_display.vhd
    ../src/io/hex_mux.vhd
    ../src/top/cpu_top.vhd
}
foreach f $fontes {
    set_global_assignment -name VHDL_FILE $f
}

# programa carregado na memoria: passa o generic MIF_FILE do cpu_top.
# Para gravar outro programa, troque o nome aqui (ou rode
#   quartus_sh -t criar_projeto.tcl <nome>   sem o .mif)
# e recompile. O .mif e gerado por programs/montador.py.
set programa programa_completo
if {[llength $quartus(args)] > 0} {
    set programa [lindex $quartus(args) 0]
}
set mif ../programs/mif/$programa.mif
set_global_assignment -name MIF_FILE $mif
set_parameter -name MIF_FILE $mif

# --- pinos: fonte unica em pinos_de2_115.qsf (ver pinout.md) ------------------
# Nao da para usar "source": em Tcl, KEY[0] seria lido como chamada do comando
# "0". Por isso cada linha e lida e os colchetes sao escapados antes do eval.
set arq [open pinos_de2_115.qsf r]
set pinos 0
while {[gets $arq linha] >= 0} {
    set linha [string trim $linha]
    if {$linha eq "" || [string index $linha 0] eq "#"} {
        continue
    }
    eval [string map [list "\[" "\\\[" "\]" "\\\]"] $linha]
    if {[string match "set_location_assignment*" $linha]} {
        incr pinos
    }
}
close $arq
puts "Pinos atribuidos: $pinos"

export_assignments
project_close

puts "Projeto criado: quartus/cpu_multiciclo.qpf (programa: $mif)"
