# Dificuldades Encontradas

## Reset no meio do programa buscava a instrução errada

**Sintoma.** No `tb_cpu_top`, depois de rodar o programa até o fim e dar reset, o primeiro FETCH carregava no IR `803F` (o `BEQ` do endereço 18) no lugar de `5206` (a instrução do endereço 0).

**Causa.** A memória (`altsyncram`) tem leitura síncrona e está ligada no clock invertido: ela registra o endereço na **descida** do clock, ou seja, quando o botão de clock é solto. O reset é assíncrono: zera o PC na hora, mas não gera borda nenhuma. A memória continuava com o endereço que tinha registrado na última vez que o `KEY[0]` foi solto, e o primeiro FETCH depois do reset lia esse endereço antigo. No power-up o problema não aparecia, porque o registrador de endereço da RAM já começa em 0.

**Solução.** O reset passou a gerar também um pulso de clock (`cpu_clk = clk_db or reset_db`, em `src/io/clock_reset.vhd`). Soltar o `KEY[1]` desce o clock junto com o fim do reset, com o PC já em 0, e a memória registra o endereço 0. Nenhum arquivo da CPU (FSM, datapath, memória) precisou mudar. Detalhes em [01](01-descricao-topologia.md#módulos-de-srcio).

**Lição.** O erro só apareceu ao juntar a memória com os botões da placa: cada bloco passava nos próprios testes. Por isso o `tb_cpu_top` testa o topo inteiro pelos pinos, inclusive um reset no meio do programa.
