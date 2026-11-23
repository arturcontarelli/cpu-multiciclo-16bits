; programa_completo.asm
; Usa as 11 instrucoes: desvio tomado e nao tomado, laco com desvio para tras,
; JMP por cima de instrucao "veneno" e escrita em R0 (ignorada).
;
; Estado final esperado:
;   R0=0  R1=6  R2=0  R3=3  R4=9  R5=3  R6=000F  R7=9
;   M[30]=9   PC parado em 18 (BEQ R0,R0,fim)

        ADDI R1, R0, 6          ; R1 = 6
        ADDI R2, R0, -3         ; R2 = -3 (FFFD)
        ADD  R3, R1, R2         ; R3 = 3
        SUB  R4, R1, R2         ; R4 = 9
        AND  R5, R1, R3         ; R5 = 6 and 3 = 2
        OR   R6, R1, R4         ; R6 = 6 or 9 = 15
        SLT  R7, R2, R1         ; R7 = (-3 < 6) = 1
        ST   R4, R7, 29         ; M[R7 + 29] = M[30] = 9
        LD   R7, R0, 30         ; R7 = M[30] = 9
        BEQ  R7, R4, depois     ; 9 = 9: desvia
        ADDI R1, R0, 31         ; veneno (pulado)
depois: BNE  R7, R4, laco       ; 9 = 9: nao desvia
        ADDI R5, R5, 1          ; R5 = 3 (prova que nao desviou)
laco:   ADDI R2, R2, 1          ; R2 = -2, -1, 0
        BNE  R2, R0, laco       ; volta enquanto R2 /= 0
        JMP  pula
        ADDI R1, R0, 30         ; veneno (pulado)
pula:   ADDI R0, R0, 9          ; escrita em R0 ignorada
fim:    BEQ  R0, R0, fim        ; fim de programa: desvia para si mesmo
