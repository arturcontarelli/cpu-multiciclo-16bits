Projeto
Lab. de Arquitetura de Sistemas Computacionais 

 

Realizar o projeto de uma CPU capaz de executar as seguintes instruções:

 

Instrução
	

Significado
	

Descrição

ADD Ri, Rj, Rk
	

Ri <- Rj + Rk
	

Soma entre dois regs

SUB Ri, Rj, Rk
	

Ri <- Rj - Rk
	

Subtração entre dois regs

AND Ri, Rj, Rk
	

Ri <- Rj && Rk
	

Operação and entre dois regs

OR Ri, Rj, Rk
	

Ri <- Rj || Rk
	

Operação or entre dois regs

SLT Ri, Rj, Rk
	

Ri <- 1, se Rj < Rk; Ri <- 0
	

Set se menor que

ADDI Ri, Rj, imediato
	

Ri <- Rj + imediato
	

Soma imediato

LD Ri, Rj, imediato
	

Ri <- Memoria[Rj + imediato]
	

load 

ST Ri, Rj, imediato
	

Memoria[Rj + imediato] <- Ri
	

store

BEQ Ri, Rj, imediato
	

PC <- PC + imediato, se Ri == Rj
	

salto condicional

BNE Ri, Rj, imediato
	

PC <- PC + imediato, se Ri != Rj
	

salto condicional

JMP end
	

PC <- end
	

sato incondicional



Formatos das instruções:

 

Tipo R

4 bits
	

3 bits
	

3 bits
	

3 bits
	

3 bits

Opcode
	

Ri
	

Rj
	

Rk
	

não usado



Tipo I

4 bits
	

3 bits
	

3 bits
	

6 bits

Opcode
	

Ri
	

Rj
	

imediato



Tipo J

4 bits
	

12 bits

Opcode
	

end

 

Onde:

    CPU utiliza palavra de 16 bits
    Ri, Rj e Rk são registradores de 16 bits
    imediato é um número positivo ou negativo

 

TESTES

    Utilize um arquivo .mif para inicializar a memória com o programa a ser testado.
    Implemente o projeto na FPGA:
        Utilize um dos botões para controlar o sinal de clock (lembre do debouncer)
        Utilize os HEX0 a HEX3 para mostrar o valor de PC
        Utilize os HEX4 a HEX7 para mostrar duas coisas:
            O valor lido da memória (RDM)
            A saída da ULA
                Para isso, use o switch 17 como chave para multiplexar qual das duas informações será mostrada nos displays HEX4-7
        Utilize os LEDs verdes para indicar o estado da unidade de controle (fetch, decode, busca na memória etc.)

 

ENTREGA

Na data definida deve ser entregue um documento de especificação que contenha:

    Descrição textual do projeto com a topologia da CPU
    Especificação
        Registradores (quantidade, endereço e tamanho)
        Formato das instruções
        Unidade de controle: diagrama e tabela de estados, sinais e seus significados
    Diagrama de caminho de dados
    Descrição dos testes utilizados
    Resultados e discussão
    Dificuldades encontradas
    Uso de IA
        quais partes foram desenvolvidas com uso de IA e por quê.

 

Um integrante do grupo deverá postar na tarefa Projeto no CANVAS:

        O documento de especificação em pdf
        O código VHDL produzido (.vhd)
        Os programas testados (.mif)

    Entrem em um grupo no CANVAS já no primeiro dia

 

OBSERVAÇÕES

    Escreva um bom documento. Ele deve descrever bem o projeto sem ser prolixo. Elabore bem na discussão sobre a especificação, descrição dos testes e resultados. 
    É mais importante que vocês entendam o que está sendo feito do que o funcionamento impecável do projeto. 
    O desenvolvimento do projeto durante as aulas de laboratório faz parte da nota. 
    Todos os membros do grupo devem estar presentes no dia da apresentação. A ausência implica em nota 0 para o integrante.
    Atividade em grupos de 4 a 5 pessoas (obrigatoriamente). Não serão aceitos grupos menores do que 4 componentes, exceto se algum componente desistir da disciplina durante o projeto. Os integrantes restantes ficarão responsáveis pelo projeto sem distinção (ou seja: prefiram grupos maiores).
    As datas de apresentação do trabalho são: 17/11, 24/11 e 01/12. A ordem de apresentação será sorteada perto do prazo de entrega.
